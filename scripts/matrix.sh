#!/usr/bin/env bash
# Orquestación de la matriz MC × loader (versions/matrix.yml).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MATRIX_FILE="${PROJECT_ROOT}/versions/matrix.yml"

log_info() { echo "[info] $*"; }
log_ok() { echo "[ok] $*"; }
log_error() { echo "[error] $*" >&2; }

usage() {
	cat <<'EOF'
Uso: matrix.sh <comando> [id-celda]

Comandos:
  list              Lista todas las celdas de la matriz
  verify [id]       Verifica celdas enabled (o una id)
  build  [id]       Compila common + celdas enabled (o una id)
  test   [id]       Ejecuta tests (common + forge si aplica)
  help              Esta ayuda

Ejemplos:
  ./scripts/matrix.sh list
  ./scripts/matrix.sh build
  ./scripts/matrix.sh test mc1.20.1-forge
EOF
}

require_matrix() {
	if [[ ! -f "${MATRIX_FILE}" ]]; then
		log_error "No se encontró ${MATRIX_FILE}"
		exit 1
	fi
}

# Fallar si matrix mod_semver ≠ sufijo de gradle.properties mod_version.
verify_mod_semver() {
	local gradle_props="${PROJECT_ROOT}/gradle.properties"
	local mod_version matrix_semver gradle_semver
	mod_version="$(grep -E '^mod_version=' "${gradle_props}" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r')"
	matrix_semver="$(grep -E '^mod_semver:' "${MATRIX_FILE}" 2>/dev/null | head -1 | sed 's/^mod_semver:[[:space:]]*//' | tr -d '"'"'" | tr -d '\r')"
	[[ -n "${mod_version}" ]] || {
		log_error "No se encontró mod_version en gradle.properties"
		return 1
	}
	[[ -n "${matrix_semver}" ]] || {
		log_error "No se encontró mod_semver en ${MATRIX_FILE}"
		return 1
	}
	# Sufijo tras el primer '-': 1.20.1-4.2.0 → 4.2.0; 26.1-4.2.0 → 4.2.0
	if [[ "${mod_version}" == *-* ]]; then
		gradle_semver="${mod_version#*-}"
	else
		gradle_semver="${mod_version}"
	fi
	if [[ "${gradle_semver}" != "${matrix_semver}" ]]; then
		log_error "mod_semver desincronizado: matrix=${matrix_semver} gradle mod_version=${mod_version} (esperado sufijo ${gradle_semver})"
		log_error "Actualizá versions/matrix.yml mod_semver al publicar un nuevo semver."
		return 1
	fi
	log_ok "mod_semver OK (${matrix_semver})"
}

# Parseo simple de matrix.yml sin depender de yq.
# Emite líneas: id|minecraft|loader|java|enabled|project
parse_matrix() {
	python3 - <<'PY' "${MATRIX_FILE}"
import sys
path = sys.argv[1]
id = mc = loader = java = enabled = project = None

def flush():
    if id is None:
        return
    print(f"{id}|{mc}|{loader}|{java}|{enabled}|{project}")

with open(path, encoding="utf-8") as fh:
    for raw in fh:
        line = raw.rstrip("\n")
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("- id:"):
            flush()
            id = stripped.split(":", 1)[1].strip().strip('"').strip("'")
            mc = loader = java = enabled = project = ""
            continue
        if id is None:
            continue
        if stripped.startswith("minecraft:"):
            mc = stripped.split(":", 1)[1].strip().strip('"').strip("'")
        elif stripped.startswith("loader:"):
            loader = stripped.split(":", 1)[1].strip().strip('"').strip("'")
        elif stripped.startswith("java:"):
            java = stripped.split(":", 1)[1].strip().strip('"').strip("'")
        elif stripped.startswith("enabled:"):
            enabled = stripped.split(":", 1)[1].strip().lower()
        elif stripped.startswith("project:"):
            project = stripped.split(":", 1)[1].strip().strip('"').strip("'")
    flush()
PY
}

list_targets() {
	require_matrix
	printf '%-22s %-10s %-10s %-6s %-8s %s\n' "ID" "MC" "LOADER" "JAVA" "ENABLED" "PROJECT"
	printf '%s\n' "--------------------------------------------------------------------------------"
	while IFS='|' read -r id mc loader java enabled project; do
		printf '%-22s %-10s %-10s %-6s %-8s %s\n' "$id" "$mc" "$loader" "$java" "$enabled" "$project"
	done < <(parse_matrix)
}

find_target() {
	local want="$1"
	while IFS='|' read -r id mc loader java enabled project; do
		if [[ "$id" == "$want" ]]; then
			echo "${id}|${mc}|${loader}|${java}|${enabled}|${project}"
			return 0
		fi
	done < <(parse_matrix)
	return 1
}

enabled_targets() {
	while IFS='|' read -r id mc loader java enabled project; do
		if [[ "$enabled" == "true" ]]; then
			echo "${id}|${mc}|${loader}|${java}|${enabled}|${project}"
		fi
	done < <(parse_matrix)
}

select_targets() {
	local filter="${1:-}"
	if [[ -n "$filter" ]]; then
		local row
		row="$(find_target "$filter")" || {
			log_error "Celda desconocida: ${filter}"
			exit 1
		}
		echo "$row"
		return
	fi
	enabled_targets
}

gradle_cmd() {
	(cd "${PROJECT_ROOT}" && ./gradlew "$@")
}

fabric_gradle() {
	(cd "${PROJECT_ROOT}/fabric" && ./gradlew "$@")
}

neoforge_gradle() {
	(cd "${PROJECT_ROOT}/neoforge" && ./gradlew "$@")
}

is_fabric_project() {
	local p="${1#:}"
	[[ "$p" == "fabric" || "$p" == fabric-* ]]
}

is_neoforge_project() {
	local p="${1#:}"
	[[ "$p" == "neoforge" || "$p" == neoforge-* ]]
}

is_isolated_project() {
	is_fabric_project "$1" || is_neoforge_project "$1"
}

# Gradle wrapper del módulo aislado (fabric, fabric-26.1, neoforge-26.2, …).
isolated_gradle() {
	local project="$1"
	shift
	local dir="${project#:}"
	(cd "${PROJECT_ROOT}/${dir}" && ./gradlew "$@")
}

cmd_verify() {
	local filter="${1:-}"
	require_matrix
	verify_mod_semver || exit 1
	local any=0
	local need_common=0
	local -a isolated=()
	while IFS='|' read -r id mc loader java enabled project; do
		any=1
		log_info "Verificando ${id} (MC ${mc}, ${loader}, Java ${java}, ${project})"
		if [[ "$enabled" != "true" && -z "$filter" ]]; then
			log_info "  omitida (enabled=false)"
			continue
		fi
		local dir="${project#:}"
		if [[ ! -d "${PROJECT_ROOT}/${dir}" ]]; then
			log_error "No existe el módulo ${dir} para ${id}"
			exit 1
		fi
		if is_isolated_project "${project}"; then
			isolated+=("${project}")
		else
			need_common=1
		fi
		log_ok "${id} OK"
	done < <(select_targets "$filter")
	if [[ "$any" -eq 0 ]]; then
		log_error "No hay celdas para verificar"
		exit 1
	fi
	if [[ "$need_common" -eq 1 ]]; then
		gradle_cmd :common:compileJava
	fi
	local proj seen=""
	for proj in "${isolated[@]+"${isolated[@]}"}"; do
		[[ " ${seen} " == *" ${proj} "* ]] && continue
		seen+=" ${proj}"
		isolated_gradle "${proj}" compileJava
	done
	log_ok "verify completado"
}

cmd_build() {
	local filter="${1:-}"
	require_matrix
	verify_mod_semver || exit 1
	local root_projects=()
	local -a isolated=()
	while IFS='|' read -r id mc loader java enabled project; do
		log_info "Build ${id} → ${project}"
		if is_isolated_project "${project}"; then
			isolated+=("${project}")
		else
			root_projects+=("${project}:build")
		fi
	done < <(select_targets "$filter")
	if [[ ${#root_projects[@]} -gt 0 ]]; then
		gradle_cmd ":common:build" "${root_projects[@]}"
	fi
	local proj seen=""
	for proj in "${isolated[@]+"${isolated[@]}"}"; do
		[[ " ${seen} " == *" ${proj} "* ]] && continue
		seen+=" ${proj}"
		isolated_gradle "${proj}" build
	done
	log_ok "build completado"
}

cmd_test() {
	local filter="${1:-}"
	require_matrix
	verify_mod_semver || exit 1
	local root_projects=()
	local -a isolated=()
	while IFS='|' read -r id mc loader java enabled project; do
		log_info "Test ${id} → ${project}"
		if is_isolated_project "${project}"; then
			isolated+=("${project}")
		else
			root_projects+=("${project}:test")
		fi
	done < <(select_targets "$filter")
	if [[ ${#root_projects[@]} -gt 0 ]]; then
		gradle_cmd ":common:test" "${root_projects[@]}"
	elif [[ ${#isolated[@]} -eq 0 ]]; then
		gradle_cmd :common:test
	fi
	local proj seen=""
	for proj in "${isolated[@]+"${isolated[@]}"}"; do
		[[ " ${seen} " == *" ${proj} "* ]] && continue
		seen+=" ${proj}"
		isolated_gradle "${proj}" test
	done
	log_ok "test completado"
}

main() {
	local cmd="${1:-help}"
	shift || true
	case "$cmd" in
		list) list_targets ;;
		verify) cmd_verify "${1:-}" ;;
		build) cmd_build "${1:-}" ;;
		test) cmd_test "${1:-}" ;;
		help|-h|--help) usage ;;
		*) log_error "Comando desconocido: ${cmd}"; usage; exit 1 ;;
	esac
}

main "$@"
