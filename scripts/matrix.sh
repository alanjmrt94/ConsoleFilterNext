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
	[[ "$1" == ":fabric" || "$1" == "fabric" ]]
}

is_neoforge_project() {
	[[ "$1" == ":neoforge" || "$1" == "neoforge" ]]
}

is_isolated_project() {
	is_fabric_project "$1" || is_neoforge_project "$1"
}

cmd_verify() {
	local filter="${1:-}"
	require_matrix
	local any=0
	local need_common=0
	local need_fabric=0
	local need_neoforge=0
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
		if is_fabric_project "${project}"; then
			need_fabric=1
		elif is_neoforge_project "${project}"; then
			need_neoforge=1
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
	if [[ "$need_fabric" -eq 1 ]]; then
		fabric_gradle compileJava
	fi
	if [[ "$need_neoforge" -eq 1 ]]; then
		neoforge_gradle compileJava
	fi
	log_ok "verify completado"
}

cmd_build() {
	local filter="${1:-}"
	require_matrix
	local root_projects=()
	local build_fabric=0
	local build_neoforge=0
	while IFS='|' read -r id mc loader java enabled project; do
		log_info "Build ${id} → ${project}"
		if is_fabric_project "${project}"; then
			build_fabric=1
		elif is_neoforge_project "${project}"; then
			build_neoforge=1
		else
			root_projects+=("${project}:build")
		fi
	done < <(select_targets "$filter")
	if [[ ${#root_projects[@]} -gt 0 ]]; then
		gradle_cmd ":common:build" "${root_projects[@]}"
	fi
	if [[ "$build_fabric" -eq 1 ]]; then
		fabric_gradle build
	fi
	if [[ "$build_neoforge" -eq 1 ]]; then
		neoforge_gradle build
	fi
	log_ok "build completado"
}

cmd_test() {
	local filter="${1:-}"
	require_matrix
	local root_projects=()
	local test_fabric=0
	local test_neoforge=0
	while IFS='|' read -r id mc loader java enabled project; do
		log_info "Test ${id} → ${project}"
		if is_fabric_project "${project}"; then
			test_fabric=1
		elif is_neoforge_project "${project}"; then
			test_neoforge=1
		else
			root_projects+=("${project}:test")
		fi
	done < <(select_targets "$filter")
	if [[ ${#root_projects[@]} -gt 0 ]]; then
		gradle_cmd ":common:test" "${root_projects[@]}"
	elif [[ "$test_fabric" -eq 0 && "$test_neoforge" -eq 0 ]]; then
		gradle_cmd :common:test
	fi
	if [[ "$test_fabric" -eq 1 ]]; then
		fabric_gradle test
	fi
	if [[ "$test_neoforge" -eq 1 ]]; then
		neoforge_gradle test
	fi
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
