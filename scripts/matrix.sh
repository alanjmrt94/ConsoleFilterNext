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
  verify [id]       Compila celdas enabled con el JDK launcher correcto
  build  [id]       Compila common + celdas enabled (o una id)
  test   [id]       Ejecuta tests (common + forge si aplica)
  help              Esta ayuda

JAVA_HOME_8 / 17 / 21 / 25 (o JAVA_HOME_*_X64) lanzan cada wrapper.
El campo java: de la matriz es bytecode; Fabric Loom y RFG 1.12.2 pueden
pedir otro JDK de launcher.

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
	local home=""
	if home="$(resolve_java_home 17)"; then
		log_info "Gradle raíz con JDK 17 (${home})"
		(cd "${PROJECT_ROOT}" && JAVA_HOME="${home}" PATH="${home}/bin:${PATH}" ./gradlew "$@")
	else
		log_info "JDK 17 no encontrado; Gradle raíz usa JAVA_HOME actual"
		(cd "${PROJECT_ROOT}" && ./gradlew "$@")
	fi
}

# JDK con el que se lanza el wrapper (no siempre = bytecode de la celda).
gradle_launcher_java() {
	local mc="$1"
	local loader="$2"
	local bytecode="${3:-}"
	case "${mc}/${loader}" in
		1.8.9/forge) echo 8 ;;
		1.12.2/forge) echo 25 ;;
		1.16.1/forge|1.16.5/forge) echo 17 ;;
		1.19.2/forge|1.19.4/forge) echo 21 ;;
		26.*/*) echo 25 ;;
		*/fabric)
			if [[ "${bytecode}" == "25" ]]; then
				echo 25
			else
				echo 21
			fi
			;;
		1.20.1/neoforge) echo 17 ;;
		*/neoforge)
			if [[ "${bytecode}" == "25" ]]; then
				echo 25
			else
				echo 21
			fi
			;;
		*) echo "${bytecode:-21}" ;;
	esac
}

resolve_java_home() {
	local ver="$1"
	local x64="JAVA_HOME_${ver}_X64"
	local plain="JAVA_HOME_${ver}"
	local candidate
	if [[ -n "${!x64:-}" && -x "${!x64}/bin/java" ]]; then
		echo "${!x64}"
		return 0
	fi
	if [[ -n "${!plain:-}" && -x "${!plain}/bin/java" ]]; then
		echo "${!plain}"
		return 0
	fi
	for candidate in \
		"/usr/lib/jvm/temurin-${ver}-jdk-amd64" \
		"/usr/lib/jvm/temurin-${ver}-jdk" \
		"/usr/lib/jvm/zulu${ver}-ca-amd64" \
		"/usr/lib/jvm/java-${ver}-openjdk-amd64" \
		"/usr/lib/jvm/java-${ver}-openjdk" \
		"/usr/lib/jvm/jdk-${ver}"; do
		if [[ -x "${candidate}/bin/java" ]]; then
			echo "${candidate}"
			return 0
		fi
	done
	return 1
}

# Proyectos con wrapper propio bajo platforms/{mc}/{loader}.
# El único subproyecto del Gradle raíz sigue siendo ":forge".
is_isolated_project() {
	local p="${1#:}"
	[[ "$p" == platforms/* ]]
}

# Ruta en disco del módulo (":forge" → platforms/1.20.1/forge).
project_dir() {
	local p="${1#:}"
	if [[ "$p" == "forge" ]]; then
		echo "platforms/1.20.1/forge"
	else
		echo "$p"
	fi
}

# Gradle wrapper del módulo aislado. $2 = JDK launcher (8/17/21/25).
isolated_gradle() {
	local project="$1"
	local launcher_java="$2"
	shift 2
	local dir home
	dir="$(project_dir "${project}")"
	if ! home="$(resolve_java_home "${launcher_java}")"; then
		log_error "No se encontró JDK ${launcher_java} para ${project} (exportá JAVA_HOME_${launcher_java})."
		exit 1
	fi
	log_info "  ${project} → JAVA_HOME=${home} (launcher JDK ${launcher_java})"
	(cd "${PROJECT_ROOT}/${dir}" && JAVA_HOME="${home}" PATH="${home}/bin:${PATH}" ./gradlew "$@")
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
		local dir
		dir="$(project_dir "${project}")"
		if [[ ! -d "${PROJECT_ROOT}/${dir}" ]]; then
			log_error "No existe el módulo ${dir} para ${id}"
			exit 1
		fi
		if is_isolated_project "${project}"; then
			isolated+=("$(gradle_launcher_java "${mc}" "${loader}" "${java}")|${project}")
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
	local entry proj launcher seen=""
	for entry in "${isolated[@]+"${isolated[@]}"}"; do
		launcher="${entry%%|*}"
		proj="${entry#*|}"
		[[ " ${seen} " == *" ${proj} "* ]] && continue
		seen+=" ${proj}"
		isolated_gradle "${proj}" "${launcher}" compileJava
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
			isolated+=("$(gradle_launcher_java "${mc}" "${loader}" "${java}")|${project}")
		else
			root_projects+=("${project}:build")
		fi
	done < <(select_targets "$filter")
	if [[ ${#root_projects[@]} -gt 0 ]]; then
		gradle_cmd ":common:build" "${root_projects[@]}"
	fi
	local entry proj launcher seen=""
	for entry in "${isolated[@]+"${isolated[@]}"}"; do
		launcher="${entry%%|*}"
		proj="${entry#*|}"
		[[ " ${seen} " == *" ${proj} "* ]] && continue
		seen+=" ${proj}"
		isolated_gradle "${proj}" "${launcher}" build
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
			isolated+=("$(gradle_launcher_java "${mc}" "${loader}" "${java}")|${project}")
		else
			root_projects+=("${project}:test")
		fi
	done < <(select_targets "$filter")
	if [[ ${#root_projects[@]} -gt 0 ]]; then
		gradle_cmd ":common:test" "${root_projects[@]}"
	elif [[ ${#isolated[@]} -eq 0 ]]; then
		gradle_cmd :common:test
	fi
	local entry proj launcher seen=""
	for entry in "${isolated[@]+"${isolated[@]}"}"; do
		launcher="${entry%%|*}"
		proj="${entry#*|}"
		[[ " ${seen} " == *" ${proj} "* ]] && continue
		seen+=" ${proj}"
		isolated_gradle "${proj}" "${launcher}" test
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
