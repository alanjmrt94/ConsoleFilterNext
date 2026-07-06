#!/usr/bin/env bash
# Funciones de publicación de release — incluido desde scripts/release.sh
# GitHub (tag + release), Modrinth y CurseForge.

: "${SCRIPT_DIR:?SCRIPT_DIR must be set by release.sh}"
: "${PROJECT_ROOT:?PROJECT_ROOT must be set by release.sh}"
: "${GRADLE_PROPERTIES:?GRADLE_PROPERTIES must be set by release.sh}"

PUBLISH_TMP_DIR=""

publish_cleanup() {
	if [[ -n "${PUBLISH_TMP_DIR}" && -d "${PUBLISH_TMP_DIR}" ]]; then
		rm -rf "${PUBLISH_TMP_DIR}"
	fi
}

publish_require_command() {
	local cmd="$1"
	command -v "${cmd}" &>/dev/null || {
		log_error "Falta el comando requerido: ${cmd}"
		[[ "${cmd}" == "jq" ]] && log_info "Instalar: sudo apt install jq  (o brew install jq)"
		[[ "${cmd}" == "gh" ]] && log_info "Instalar y autenticar: https://cli.github.com/ → gh auth login"
		return 1
	}
}

publish_load_secrets() {
	load_local_config

	CURSEFORGE_API_TOKEN="${CURSEFORGE_API_TOKEN:-${CF_API_TOKEN:-}}"
	CURSEFORGE_PROJECT_ID="${CURSEFORGE_PROJECT_ID:-}"
	CURSEFORGE_PROJECT_SLUG="${CURSEFORGE_PROJECT_SLUG:-consolefilternext}"
	MODRINTH_TOKEN="${MODRINTH_TOKEN:-}"
	MODRINTH_PROJECT_ID="${MODRINTH_PROJECT_ID:-}"
	MODRINTH_PROJECT_SLUG="${MODRINTH_PROJECT_SLUG:-consolefilternext}"
	GITHUB_REMOTE="${GITHUB_REMOTE:-origin}"
	RELEASE_TYPE="${RELEASE_TYPE:-release}"
}

publish_show_secrets_status() {
	echo -e "${BOLD}Credenciales y destinos${RESET}"
	echo "────────────────────────────────────────"
	if [[ -n "${CURSEFORGE_API_TOKEN}" ]]; then
		log_ok "CURSEFORGE_API_TOKEN configurado"
	else
		log_warn "CURSEFORGE_API_TOKEN no definido (scripts/.release.local)"
	fi
	echo "  CurseForge proyecto : ${CURSEFORGE_PROJECT_ID:-<auto slug: ${CURSEFORGE_PROJECT_SLUG}>}"
	if [[ -n "${MODRINTH_TOKEN}" ]]; then
		log_ok "MODRINTH_TOKEN configurado"
	else
		log_warn "MODRINTH_TOKEN no definido"
	fi
	echo "  Modrinth proyecto   : ${MODRINTH_PROJECT_ID:-<auto slug: ${MODRINTH_PROJECT_SLUG}>}"
	if command -v gh &>/dev/null && gh auth status &>/dev/null; then
		log_ok "GitHub CLI autenticado (gh)"
	else
		log_warn "gh no autenticado — necesario para GitHub Release"
	fi
	echo
}

publish_find_jar() {
	local mod_id version pattern jar
	mod_id="$(get_prop mod_id "${GRADLE_PROPERTIES}")"
	version="$(get_prop mod_version "${GRADLE_PROPERTIES}")"
	pattern="${PROJECT_ROOT}/build/libs/${mod_id}-${version}.jar"

	if [[ -f "${pattern}" ]]; then
		echo "${pattern}"
		return 0
	fi

	jar="$(find "${PROJECT_ROOT}/build/libs" -maxdepth 1 -name "${mod_id}-*.jar" \
		! -name "*-sources.jar" ! -name "*-javadoc.jar" 2>/dev/null | head -1)"
	if [[ -n "${jar}" && -f "${jar}" ]]; then
		echo "${jar}"
		return 0
	fi

	return 1
}

publish_extract_changelog() {
	local tag="$1"
	local semver="${tag#*-}"
	local changelog_file="${PROJECT_ROOT}/changelog.txt"

	if [[ ! -f "${changelog_file}" ]]; then
		echo "Release ${tag}"
		return 0
	fi

	local section
	section="$(awk -v ver="${semver}" '
		$0 ~ "VERSION " ver " " { capture=1; next }
		capture && /^-+$/ { if (started) next; started=1; next }
		capture && started && /^VERSION / { exit }
		capture && started { print }
	' "${changelog_file}")"

	if [[ -n "${section}" ]]; then
		printf '%s\n' "${section}"
	else
		echo "Release ${tag}"
	fi
}

publish_build_release() {
	log_info "Compilando (clean build)..."
	load_local_config
	if ! gradle_cmd clean build; then
		log_error "La compilación falló"
		return 1
	fi
	log_ok "Compilación exitosa"
	publish_find_jar >/dev/null || {
		log_error "No se encontró el JAR en build/libs/"
		return 1
	}
	return 0
}

publish_resolve_curseforge_project_id() {
	if [[ -n "${CURSEFORGE_PROJECT_ID}" ]]; then
		echo "${CURSEFORGE_PROJECT_ID}"
		return 0
	fi

	publish_require_command curl || return 1
	publish_require_command jq || return 1
	[[ -n "${CURSEFORGE_API_TOKEN}" ]] || return 1

	local response id
	response="$(curl -fsS \
		-H "x-api-key: ${CURSEFORGE_API_TOKEN}" \
		-H "Accept: application/json" \
		"https://api.curseforge.com/v1/mods/search?gameId=432&searchFilter=6&slug=${CURSEFORGE_PROJECT_SLUG}")"
	id="$(echo "${response}" | jq -r '.data[0].id // empty')"
	[[ -n "${id}" && "${id}" != "null" ]] || return 1
	echo "${id}"
}

publish_resolve_modrinth_project_id() {
	if [[ -n "${MODRINTH_PROJECT_ID}" ]]; then
		echo "${MODRINTH_PROJECT_ID}"
		return 0
	fi

	publish_require_command curl || return 1
	publish_require_command jq || return 1

	local response id
	response="$(curl -fsS "https://api.modrinth.com/v2/project/${MODRINTH_PROJECT_SLUG}")"
	id="$(echo "${response}" | jq -r '.id // empty')"
	[[ -n "${id}" && "${id}" != "null" ]] || return 1
	echo "${id}"
}

publish_curseforge_game_version_ids() {
	local mc_version="$1"
	publish_require_command curl || return 1
	publish_require_command jq || return 1
	[[ -n "${CURSEFORGE_API_TOKEN}" ]] || return 1

	local mc_id forge_id
	mc_id="$(curl -fsS \
		-H "x-api-key: ${CURSEFORGE_API_TOKEN}" \
		-H "Accept: application/json" \
		"https://api.curseforge.com/v1/minecraft/game/version" \
		| jq -r --arg mc "${mc_version}" '.data[] | select(.versionString == $mc) | .id' | head -1)"
	forge_id="$(curl -fsS \
		-H "x-api-key: ${CURSEFORGE_API_TOKEN}" \
		-H "Accept: application/json" \
		"https://api.curseforge.com/v1/minecraft/modloader" \
		| jq -r '.data[] | select(.name == "Forge" or .slug == "forge") | .id' | head -1)"

	if [[ -z "${mc_id}" || -z "${forge_id}" ]]; then
		return 1
	fi
	printf '%s,%s' "${mc_id}" "${forge_id}"
}

publish_git_tag_and_push() {
	local tag="$1"
	local push_branch="${2:-false}"

	if [[ "${push_branch}" == "true" ]]; then
		local branch
		branch="$(git -C "${PROJECT_ROOT}" rev-parse --abbrev-ref HEAD)"
		log_info "Subiendo rama ${branch} a ${GITHUB_REMOTE}..."
		git -C "${PROJECT_ROOT}" push "${GITHUB_REMOTE}" "${branch}"
	fi

	if git -C "${PROJECT_ROOT}" rev-parse "${tag}" >/dev/null 2>&1; then
		log_warn "El tag ${tag} ya existe localmente"
	else
		log_info "Creando tag anotado ${tag}..."
		git -C "${PROJECT_ROOT}" tag -a "${tag}" -m "Release ${tag}"
	fi

	log_info "Subiendo tag ${tag} a ${GITHUB_REMOTE}..."
	git -C "${PROJECT_ROOT}" push "${GITHUB_REMOTE}" "${tag}"
}

publish_github_release() {
	local tag="$1"
	local jar="$2"
	local notes="$3"
	local dry_run="${4:-false}"

	if [[ "${dry_run}" == "true" ]]; then
		log_info "[dry-run] GitHub Release ${tag} con ${jar}"
		return 0
	fi

	publish_require_command gh || return 1

	if gh release view "${tag}" --repo "$(publish_github_repo_slug)" &>/dev/null; then
		log_info "Actualizando GitHub Release existente..."
		gh release upload "${tag}" "${jar}" --clobber --repo "$(publish_github_repo_slug)"
		gh release edit "${tag}" --notes "${notes}" --repo "$(publish_github_repo_slug)"
	else
		log_info "Creando GitHub Release..."
		gh release create "${tag}" "${jar}" \
			--title "Console Filter Next ${tag}" \
			--notes "${notes}" \
			--repo "$(publish_github_repo_slug)"
	fi
	log_ok "GitHub Release publicado: ${tag}"
}

publish_github_repo_slug() {
	local url
	url="$(git -C "${PROJECT_ROOT}" remote get-url "${GITHUB_REMOTE}" 2>/dev/null || true)"
	case "${url}" in
		git@github.com:*)
			echo "${url#git@github.com:}" | sed 's/\.git$//'
			;;
		https://github.com/*)
			echo "${url#https://github.com/}" | sed 's/\.git$//'
			;;
		*)
			gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo ""
			;;
	esac
}

publish_modrinth_upload() {
	local tag="$1"
	local jar="$2"
	local changelog="$3"
	local dry_run="${4:-false}"
	local mc_version project_id json response http_code

	[[ -n "${MODRINTH_TOKEN}" ]] || {
		log_warn "MODRINTH_TOKEN no configurado; omitiendo Modrinth"
		return 0
	}

	publish_require_command curl || return 1
	publish_require_command jq || return 1

	project_id="$(publish_resolve_modrinth_project_id)" || {
		log_error "No se pudo resolver el proyecto Modrinth (slug: ${MODRINTH_PROJECT_SLUG})"
		return 1
	}

	mc_version="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
	PUBLISH_TMP_DIR="$(mktemp -d)"
	json="$(jq -n \
		--arg project_id "${project_id}" \
		--arg version_number "${tag}" \
		--arg name "${tag}" \
		--arg changelog "${changelog}" \
		--arg mc "${mc_version}" \
		--arg vtype "${RELEASE_TYPE}" \
		'{
			project_id: $project_id,
			version_number: $version_number,
			name: $name,
			changelog: $changelog,
			dependencies: [],
			game_versions: [$mc],
			version_type: $vtype,
			loaders: ["forge"],
			featured: false
		}')"

	if [[ "${dry_run}" == "true" ]]; then
		log_info "[dry-run] Modrinth upload → proyecto ${project_id}"
		echo "${json}" | jq .
		return 0
	fi

	http_code="$(curl -sS -o "${PUBLISH_TMP_DIR}/modrinth-response.json" -w "%{http_code}" \
		-X POST "https://api.modrinth.com/v2/version" \
		-H "Authorization: ${MODRINTH_TOKEN}" \
		-F "data=${json};type=application/json" \
		-F "file=@${jar}")"

	if [[ "${http_code}" =~ ^2 ]]; then
		log_ok "Modrinth: versión publicada (HTTP ${http_code})"
		return 0
	fi

	log_error "Modrinth upload falló (HTTP ${http_code})"
	cat "${PUBLISH_TMP_DIR}/modrinth-response.json" 2>/dev/null || true
	return 1
}

publish_curseforge_upload() {
	local tag="$1"
	local jar="$2"
	local changelog="$3"
	local dry_run="${4:-false}"
	local mc_version project_id version_ids metadata http_code

	[[ -n "${CURSEFORGE_API_TOKEN}" ]] || {
		log_warn "CURSEFORGE_API_TOKEN no configurado; omitiendo CurseForge"
		return 0
	}

	publish_require_command curl || return 1
	publish_require_command jq || return 1

	project_id="$(publish_resolve_curseforge_project_id)" || {
		log_error "No se pudo resolver el proyecto CurseForge (slug: ${CURSEFORGE_PROJECT_SLUG})"
		return 1
	}

	mc_version="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
	version_ids="$(publish_curseforge_game_version_ids "${mc_version}")" || {
		log_error "No se pudieron resolver IDs de juego CurseForge para ${mc_version} + Forge"
		return 1
	}

	local mc_id forge_id
	mc_id="${version_ids%%,*}"
	forge_id="${version_ids##*,}"

	metadata="$(jq -n \
		--arg changelog "${changelog}" \
		--arg displayName "${tag}" \
		--arg releaseType "${RELEASE_TYPE}" \
		--argjson mcId "${mc_id}" \
		--argjson forgeId "${forge_id}" \
		'{
			changelog: $changelog,
			changelogType: "markdown",
			displayName: $displayName,
			gameVersions: [$mcId, $forgeId],
			releaseType: $releaseType
		}')"

	if [[ "${dry_run}" == "true" ]]; then
		log_info "[dry-run] CurseForge upload → proyecto ${project_id}"
		echo "${metadata}" | jq .
		return 0
	fi

	PUBLISH_TMP_DIR="${PUBLISH_TMP_DIR:-$(mktemp -d)}"
	http_code="$(curl -sS -o "${PUBLISH_TMP_DIR}/curseforge-response.json" -w "%{http_code}" \
		-X POST "https://api.curseforge.com/v1/mods/${project_id}/files" \
		-H "x-api-key: ${CURSEFORGE_API_TOKEN}" \
		-H "Accept: application/json" \
		-F "metadata=${metadata};type=application/json" \
		-F "file=@${jar}")"

	if [[ "${http_code}" =~ ^2 ]]; then
		log_ok "CurseForge: archivo subido (HTTP ${http_code})"
		return 0
	fi

	# Fallback API legacy de Minecraft
	log_warn "API REST falló (HTTP ${http_code}); probando endpoint legacy..."
	http_code="$(curl -sS -o "${PUBLISH_TMP_DIR}/curseforge-legacy-response.json" -w "%{http_code}" \
		-X POST "https://minecraft.curseforge.com/api/projects/${project_id}/upload-file" \
		-H "X-Api-Token: ${CURSEFORGE_API_TOKEN}" \
		-F "metadata=${metadata}" \
		-F "file=@${jar}")"

	if [[ "${http_code}" =~ ^2 ]]; then
		log_ok "CurseForge (legacy): archivo subido (HTTP ${http_code})"
		return 0
	fi

	log_error "CurseForge upload falló (HTTP ${http_code})"
	cat "${PUBLISH_TMP_DIR}/curseforge-response.json" 2>/dev/null || true
	cat "${PUBLISH_TMP_DIR}/curseforge-legacy-response.json" 2>/dev/null || true
	return 1
}

publish_check_prerequisites() {
	local ok=true

	publish_require_command git || ok=false
	publish_require_command curl || ok=false
	publish_require_command jq || ok=false

	if [[ "${SKIP_GITHUB:-false}" != "true" ]]; then
		publish_require_command gh || ok=false
		gh auth status &>/dev/null || {
			log_error "GitHub CLI no autenticado (gh auth login)"
			ok=false
		}
	fi

	publish_load_secrets
	publish_show_secrets_status

	if [[ "${SKIP_CURSEFORGE:-false}" != "true" && -z "${CURSEFORGE_API_TOKEN}" ]]; then
		log_warn "Sin CURSEFORGE_API_TOKEN — CurseForge se omitirá"
	fi
	if [[ "${SKIP_MODRINTH:-false}" != "true" && -z "${MODRINTH_TOKEN}" ]]; then
		log_warn "Sin MODRINTH_TOKEN — Modrinth se omitirá"
	fi

	[[ "${ok}" == "true" ]]
}

publish_release_full() {
	local dry_run="${1:-false}"
	local skip_build="${2:-false}"
	local push_branch="${3:-false}"

	trap publish_cleanup EXIT
	publish_load_secrets

	local tag jar changelog mc_version mod_name
	tag="$(get_prop mod_version "${GRADLE_PROPERTIES}")"
	mod_name="$(get_prop mod_name "${GRADLE_PROPERTIES}")"
	mc_version="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
	changelog="$(publish_extract_changelog "${tag}")"

	screen_clear
	echo -e "${BOLD}${CYAN}═══ Publicar release ═══${RESET}"
	echo
	echo "  Mod          : ${mod_name}"
	echo "  Versión/tag  : ${tag}"
	echo "  Minecraft    : ${mc_version}"
	echo "  Tipo         : ${RELEASE_TYPE}"
	[[ "${dry_run}" == "true" ]] && echo -e "  ${YELLOW}Modo dry-run (sin subidas reales)${RESET}"
	echo

	if ! publish_check_prerequisites; then
		log_error "Prerrequisitos incompletos"
		pause
		return 1
	fi

	if [[ -n "$(git -C "${PROJECT_ROOT}" status --porcelain)" ]]; then
		log_warn "El árbol de git tiene cambios sin commitear"
		if [[ "${INTERACTIVE}" == "true" && "${dry_run}" != "true" ]]; then
			read -r -p "¿Continuar de todos modos? [s/N]: " cont
			[[ "${cont,,}" == "s" || "${cont,,}" == "si" ]] || return 0
		fi
	fi

	if [[ "${INTERACTIVE}" == "true" && "${dry_run}" != "true" ]]; then
		read -r -p "¿Publicar ${tag} en GitHub + Modrinth + CurseForge? [s/N]: " confirm
		[[ "${confirm,,}" == "s" || "${confirm,,}" == "si" ]] || return 0
	fi

	if [[ "${skip_build}" != "true" ]]; then
		publish_build_release || { pause; return 1; }
	fi

	jar="$(publish_find_jar)" || {
		log_error "JAR no encontrado. Ejecuta primero la compilación."
		pause
		return 1
	}
	log_ok "JAR: $(basename "${jar}")"

	if [[ "${SKIP_GITHUB:-false}" != "true" ]]; then
		if [[ "${dry_run}" != "true" ]]; then
			publish_git_tag_and_push "${tag}" "${push_branch}" || { pause; return 1; }
		fi
		publish_github_release "${tag}" "${jar}" "${changelog}" "${dry_run}" || { pause; return 1; }
	fi

	if [[ "${SKIP_MODRINTH:-false}" != "true" ]]; then
		publish_modrinth_upload "${tag}" "${jar}" "${changelog}" "${dry_run}" || { pause; return 1; }
	fi

	if [[ "${SKIP_CURSEFORGE:-false}" != "true" ]]; then
		publish_curseforge_upload "${tag}" "${jar}" "${changelog}" "${dry_run}" || { pause; return 1; }
	fi

	echo
	log_ok "Proceso de publicación completado para ${tag}"
	if [[ "${dry_run}" == "true" ]]; then
		log_info "Dry-run: no se realizaron subidas ni cambios en git remoto"
	fi
	pause
}

publish_release_menu() {
	while true; do
		clear
		echo -e "${BOLD}${CYAN}═══ Publicar release (GitHub + Modrinth + CurseForge) ═══${RESET}"
		echo
		echo "  mod_version : $(get_prop mod_version "${GRADLE_PROPERTIES}")"
		echo
		echo "  1) Verificar prerequisitos y credenciales"
		echo "  2) Publicar release completo (build + tag + subidas)"
		echo "  3) Dry-run (simular sin subir)"
		echo "  4) Solo compilar JAR de release"
		echo "  0) Volver"
		echo
		read -r -p "Opción: " choice
		case "${choice}" in
			1)
				screen_clear
				publish_check_prerequisites || true
				pause
				;;
			2) publish_release_full false false true ;;
			3) publish_release_full true ;;
			4) publish_build_release && publish_find_jar && log_ok "JAR: $(basename "$(publish_find_jar)")"; pause ;;
			0) return ;;
			*) log_error "Opción inválida"; pause ;;
		esac
	done
}

publish_release_cli() {
	local dry_run=false
	local skip_build=false
	local push_branch=false
	SKIP_GITHUB=false
	SKIP_MODRINTH=false
	SKIP_CURSEFORGE=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--dry-run) dry_run=true ;;
			--skip-build) skip_build=true ;;
			--no-push-branch) push_branch=false ;;
			--push-branch) push_branch=true ;;
			--skip-github) SKIP_GITHUB=true ;;
			--skip-modrinth) SKIP_MODRINTH=true ;;
			--skip-curseforge) SKIP_CURSEFORGE=true ;;
			-h|--help)
				cat <<EOF
Uso: $(basename "$0") publish [opciones]

  --dry-run           Simular sin git push ni subidas
  --skip-build        Usar JAR existente en build/libs/
  --push-branch       Subir la rama actual antes del tag (default en menú opción 2)
  --no-push-branch    No subir la rama
  --skip-github       Omitir tag y GitHub Release
  --skip-modrinth     Omitir Modrinth
  --skip-curseforge   Omitir CurseForge

Configura tokens en scripts/.release.local (ver .release.local.example)
EOF
				return 0
				;;
			*)
				log_error "Opción desconocida: $1"
				return 1
				;;
		esac
		shift
	done

	INTERACTIVE=false
	publish_release_full "${dry_run}" "${skip_build}" "${push_branch}"
}
