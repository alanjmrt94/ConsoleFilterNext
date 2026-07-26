#!/usr/bin/env bash
# Funciones de publicación de release — incluido desde scripts/release.sh
# Publicación de releases: GitHub (tag + release), Modrinth y CurseForge.
#
# Modrinth: proyectos en estado Draft no son visibles por slug en la API pública;
# definir MODRINTH_PROJECT_ID (Base62). La subida usa POST /v2/version con
# file_parts y primary_file. El JSON multipart se escribe en un archivo temporal
# para evitar que el shell trunque comillas en el changelog.

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
	CURSEFORGE_AUTHOR_TOKEN="${CURSEFORGE_AUTHOR_TOKEN:-}"
	CURSEFORGE_PROJECT_ID="${CURSEFORGE_PROJECT_ID:-}"
	CURSEFORGE_PROJECT_SLUG="${CURSEFORGE_PROJECT_SLUG:-consolefilternext}"
	MODRINTH_TOKEN="${MODRINTH_TOKEN:-}"
	MODRINTH_PROJECT_ID="${MODRINTH_PROJECT_ID:-}"
	MODRINTH_PROJECT_SLUG="${MODRINTH_PROJECT_SLUG:-consolefilternext}"
	GITHUB_REMOTE="${GITHUB_REMOTE:-origin}"
	RELEASE_TYPE="${RELEASE_TYPE:-release}"
	DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
}

publish_show_secrets_status() {
	echo -e "${BOLD}Credenciales y destinos${RESET}"
	echo "────────────────────────────────────────"
	if [[ -n "${CURSEFORGE_API_TOKEN}" ]]; then
		log_ok "CURSEFORGE_API_TOKEN configurado (Profile API key / lectura)"
	else
		log_warn "CURSEFORGE_API_TOKEN no definido (scripts/.release.local)"
	fi
	if publish_curseforge_author_token &>/dev/null; then
		log_ok "CURSEFORGE_AUTHOR_TOKEN configurado (subida de archivos)"
	else
		log_warn "CURSEFORGE_AUTHOR_TOKEN no definido — la subida a CurseForge requiere token de autor"
		log_info "Generalo en https://www.curseforge.com/account/api-tokens (cfc_pat_ no sirve para upload)"
	fi
	echo "  CurseForge proyecto : ${CURSEFORGE_PROJECT_ID:-<auto slug: ${CURSEFORGE_PROJECT_SLUG}>}"
	if [[ -n "${MODRINTH_TOKEN}" ]]; then
		log_ok "MODRINTH_TOKEN configurado"
	else
		log_warn "MODRINTH_TOKEN no definido"
	fi
	echo "  Modrinth proyecto   : ${MODRINTH_PROJECT_ID:-<auto slug: ${MODRINTH_PROJECT_SLUG}>}"
	if [[ -n "${DISCORD_WEBHOOK_URL}" ]]; then
		log_ok "DISCORD_WEBHOOK_URL configurado (no se muestra)"
	else
		log_warn "DISCORD_WEBHOOK_URL no definido — no habrá aviso en Discord"
	fi
	if command -v gh &>/dev/null && gh auth status &>/dev/null; then
		log_ok "GitHub CLI autenticado (gh)"
	else
		log_warn "gh no autenticado — necesario para GitHub Release / cut"
	fi
	echo
}

# Loaders publicados para la línea moderna actual (orden estable).
publish_release_loaders() {
	printf '%s\n' forge fabric neoforge
}

publish_loader_display_name() {
	case "$1" in
		forge) echo "Forge" ;;
		fabric) echo "Fabric" ;;
		neoforge) echo "NeoForge" ;;
		*) echo "$1" ;;
	esac
}

# Emite: loader|ruta-absoluta-jar (solo artefactos existentes).
publish_list_artifacts() {
	local mod_id version loader jar
	mod_id="$(get_prop mod_id "${GRADLE_PROPERTIES}")"
	version="$(get_prop mod_version "${GRADLE_PROPERTIES}")"

	while IFS= read -r loader; do
		jar="$(publish_find_jar_for_loader "${loader}" "${mod_id}" "${version}" || true)"
		if [[ -n "${jar}" && -f "${jar}" ]]; then
			printf '%s|%s\n' "${loader}" "${jar}"
		fi
	done < <(publish_release_loaders)
}

publish_find_jar_for_loader() {
	local loader="$1"
	local mod_id="${2:-$(get_prop mod_id "${GRADLE_PROPERTIES}")}"
	local version="${3:-$(get_prop mod_version "${GRADLE_PROPERTIES}")}"
	local jar=""

	case "${loader}" in
		forge)
			for jar in \
				"${PROJECT_ROOT}/forge/build/libs/${mod_id}-${version}-forge.jar" \
				"${PROJECT_ROOT}/forge/build/libs/${mod_id}-${version}.jar" \
				"${PROJECT_ROOT}/build/libs/${mod_id}-${version}-forge.jar" \
				"${PROJECT_ROOT}/build/libs/${mod_id}-${version}.jar"; do
				if [[ -f "${jar}" ]]; then
					echo "${jar}"
					return 0
				fi
			done
			;;
		fabric)
			jar="${PROJECT_ROOT}/fabric/build/libs/${mod_id}-${version}-fabric.jar"
			[[ -f "${jar}" ]] && { echo "${jar}"; return 0; }
			jar="$(find "${PROJECT_ROOT}/fabric/build/libs" -maxdepth 1 -name "${mod_id}-*-fabric.jar" \
				! -name "*-sources.jar" 2>/dev/null | head -1)"
			[[ -n "${jar}" && -f "${jar}" ]] && { echo "${jar}"; return 0; }
			;;
		neoforge)
			jar="${PROJECT_ROOT}/neoforge/build/libs/${mod_id}-${version}-neoforge.jar"
			[[ -f "${jar}" ]] && { echo "${jar}"; return 0; }
			jar="$(find "${PROJECT_ROOT}/neoforge/build/libs" -maxdepth 1 -name "${mod_id}-*-neoforge.jar" \
				! -name "*-sources.jar" 2>/dev/null | head -1)"
			[[ -n "${jar}" && -f "${jar}" ]] && { echo "${jar}"; return 0; }
			;;
		*)
			return 1
			;;
	esac
	return 1
}

# Compat: primer JAR disponible (preferencia forge → fabric → neoforge).
publish_find_jar() {
	local row
	row="$(publish_list_artifacts | head -1)"
	[[ -n "${row}" ]] || return 1
	echo "${row#*|}"
}

publish_require_artifacts() {
	local missing=0
	local loader jar
	local -a found=()

	while IFS= read -r loader; do
		jar="$(publish_find_jar_for_loader "${loader}" || true)"
		if [[ -n "${jar}" && -f "${jar}" ]]; then
			found+=("${loader}:$(basename "${jar}")")
		else
			log_error "Falta JAR para loader ${loader}"
			missing=1
		fi
	done < <(publish_release_loaders)

	if [[ "${missing}" -ne 0 ]]; then
		log_error "Se esperan JARs para: $(publish_release_loaders | paste -sd', ' -)"
		return 1
	fi
	log_ok "Artefactos: ${found[*]}"
	return 0
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
		$0 ~ "VERSION " ver "[^0-9]" { capture=1; next }
		capture && /^-+$/ { if (started) next; started=1; next }
		capture && started && /^[[:space:]]*VERSION / { exit }
		capture && started { print }
	' "${changelog_file}")"

	if [[ -n "${section}" ]]; then
		printf '%s\n' "${section}"
	else
		echo "Release ${tag}"
	fi
}

publish_extract_assets_version_changelog() {
	local config_json="$1"
	local assets_dir="${PROJECT_ROOT}/assets"
	local rel_path abs_path

	[[ -f "${config_json}" ]] || return 1
	publish_require_command jq || return 1

	rel_path="$(jq -r '.version_changelog_file // empty' "${config_json}")"
	[[ -n "${rel_path}" && "${rel_path}" != "null" ]] || return 1

	if [[ "${rel_path}" == */* ]]; then
		abs_path="${PROJECT_ROOT}/${rel_path}"
	else
		abs_path="${assets_dir}/${rel_path}"
	fi

	[[ -f "${abs_path}" ]] || return 1
	cat "${abs_path}"
}

publish_extract_modrinth_changelog() {
	publish_extract_assets_version_changelog "${PROJECT_ROOT}/assets/modrinth.json"
}

publish_extract_curseforge_changelog() {
	publish_extract_assets_version_changelog "${PROJECT_ROOT}/assets/curseforge.json"
}

publish_build_release() {
	log_info "Compilando loaders de release (Forge + Fabric + NeoForge)..."
	load_local_config

	if ! gradle_cmd clean :common:build :forge:build; then
		log_error "Falló la compilación common/forge"
		return 1
	fi
	if ! (cd "${PROJECT_ROOT}/fabric" && ./gradlew clean build); then
		log_error "Falló la compilación Fabric"
		return 1
	fi
	if ! (cd "${PROJECT_ROOT}/neoforge" && ./gradlew clean build); then
		log_error "Falló la compilación NeoForge"
		return 1
	fi

	log_ok "Compilación multi-loader exitosa"
	publish_require_artifacts || return 1
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

	local response id http_code tmp
	tmp="$(mktemp)"
	http_code="$(curl -sS -o "${tmp}" -w "%{http_code}" \
		-H "x-api-key: ${CURSEFORGE_API_TOKEN}" \
		-H "Accept: application/json" \
		"https://api.curseforge.com/v1/mods/search?gameId=432&searchFilter=6&slug=${CURSEFORGE_PROJECT_SLUG}")"
	response="$(cat "${tmp}")"
	rm -f "${tmp}"

	if [[ "${http_code}" == "403" ]]; then
		log_error "CurseForge API rechazó el token (HTTP 403)"
		log_error "Regenera CURSEFORGE_API_TOKEN: https://console.curseforge.com/#/profile → Profile API key"
		return 1
	fi

	if [[ ! "${http_code}" =~ ^2 ]]; then
		log_error "CurseForge search falló (HTTP ${http_code})"
		echo "${response}" >&2
		return 1
	fi

	id="$(echo "${response}" | jq -r '.data[0].id // empty')"
	if [[ -z "${id}" || "${id}" == "null" ]]; then
		log_error "No se encontró proyecto CurseForge con slug: ${CURSEFORGE_PROJECT_SLUG}"
		log_error "Define CURSEFORGE_PROJECT_ID (numérico) en scripts/.release.local"
		return 1
	fi
	echo "${id}"
}

publish_resolve_modrinth_project_id() {
	if [[ -n "${MODRINTH_PROJECT_ID}" ]]; then
		echo "${MODRINTH_PROJECT_ID}"
		return 0
	fi

	publish_require_command curl || return 1
	publish_require_command jq || return 1

	local response id auth_header=()
	[[ -n "${MODRINTH_TOKEN}" ]] && auth_header=(-H "Authorization: ${MODRINTH_TOKEN}")

	response="$(curl -fsS "${auth_header[@]}" "https://api.modrinth.com/v2/project/${MODRINTH_PROJECT_SLUG}" 2>/dev/null || true)"
	id="$(echo "${response}" | jq -r '.id // empty')"
	if [[ -n "${id}" && "${id}" != "null" ]]; then
		echo "${id}"
		return 0
	fi

	log_error "No se pudo resolver el proyecto Modrinth (slug: ${MODRINTH_PROJECT_SLUG})"
	log_error "Si el proyecto está en draft, define MODRINTH_PROJECT_ID con el ID Base62 (panel de Modrinth → Projects)."
	return 1
}

# Token de autor para Upload API (minecraft.curseforge.com). No acepta Profile API keys (cfc_pat_…).
publish_curseforge_author_token() {
	if [[ -n "${CURSEFORGE_AUTHOR_TOKEN:-}" ]]; then
		echo "${CURSEFORGE_AUTHOR_TOKEN}"
		return 0
	fi
	if [[ -n "${CURSEFORGE_API_TOKEN:-}" && "${CURSEFORGE_API_TOKEN}" != cfc_pat_* ]]; then
		echo "${CURSEFORGE_API_TOKEN}"
		return 0
	fi
	return 1
}

publish_modrinth_version_environment() {
	local config_file
	config_file="$(publish_modrinth_config_file)" || {
		echo "client_or_server"
		return 0
	}
	jq -r '.version_environment // "client_or_server"' "${config_file}"
}

publish_curseforge_java_versions() {
	local mc_version="$1"
	local cf_json="${PROJECT_ROOT}/assets/curseforge.json"
	local from_config

	if [[ -f "${cf_json}" ]]; then
		from_config="$(jq -r '.java_versions[]? // empty' "${cf_json}" 2>/dev/null)"
		if [[ -n "${from_config}" ]]; then
			printf '%s\n' "${from_config}"
			return 0
		fi
	fi

	case "${mc_version}" in
		1.21.*) echo "Java 21" ;;
		*) printf '%s\n' "Java 17" "Java 21" ;;
	esac
}

publish_curseforge_java_version_name() {
	publish_curseforge_java_versions "$1" | head -1
}

publish_curseforge_game_version_ids() {
	local mc_version="$1"
	local forge_version="${2:-$(get_prop forge_version "${GRADLE_PROPERTIES}")}"
	publish_require_command curl || return 1
	publish_require_command jq || return 1
	[[ -n "${CURSEFORGE_API_TOKEN}" ]] || return 1

	local tmp http_code mc_gv_id forge_gv_id forge_name
	forge_name="forge-${forge_version}"

	tmp="$(mktemp)"
	http_code="$(curl -sS -o "${tmp}" -w "%{http_code}" \
		-H "x-api-key: ${CURSEFORGE_API_TOKEN}" \
		-H "Accept: application/json" \
		"https://api.curseforge.com/v1/minecraft/version/${mc_version}")"
	if [[ ! "${http_code}" =~ ^2 ]]; then
		log_error "CurseForge: versión MC ${mc_version} no encontrada (HTTP ${http_code})"
		cat "${tmp}" >&2 2>/dev/null || true
		rm -f "${tmp}"
		return 1
	fi
	mc_gv_id="$(jq -r '.data.gameVersionId // empty' "${tmp}")"
	rm -f "${tmp}"

	tmp="$(mktemp)"
	http_code="$(curl -sS -o "${tmp}" -w "%{http_code}" \
		-H "x-api-key: ${CURSEFORGE_API_TOKEN}" \
		-H "Accept: application/json" \
		"https://api.curseforge.com/v1/minecraft/modloader/${forge_name}")"
	if [[ ! "${http_code}" =~ ^2 ]]; then
		log_warn "CurseForge: modloader ${forge_name} no encontrado (HTTP ${http_code}); buscando en la lista..."
		rm -f "${tmp}"
		tmp="$(mktemp)"
		http_code="$(curl -sS -o "${tmp}" -w "%{http_code}" \
			-H "x-api-key: ${CURSEFORGE_API_TOKEN}" \
			-H "Accept: application/json" \
			"https://api.curseforge.com/v1/minecraft/modloader?version=${mc_version}")"
		if [[ ! "${http_code}" =~ ^2 ]]; then
			log_error "CurseForge: no se listaron modloaders para ${mc_version} (HTTP ${http_code})"
			cat "${tmp}" >&2 2>/dev/null || true
			rm -f "${tmp}"
			return 1
		fi
		forge_name="$(jq -r --arg v "${forge_version}" '
			(.data[] | select(.name == ("forge-" + $v)) | .name),
			(.data[] | select(.recommended == true) | .name),
			(.data[0].name // empty)
		' "${tmp}" | head -1)"
		rm -f "${tmp}"
		if [[ -z "${forge_name}" ]]; then
			log_error "CurseForge: no hay modloader Forge para ${mc_version}"
			return 1
		fi
		tmp="$(mktemp)"
		http_code="$(curl -sS -o "${tmp}" -w "%{http_code}" \
			-H "x-api-key: ${CURSEFORGE_API_TOKEN}" \
			-H "Accept: application/json" \
			"https://api.curseforge.com/v1/minecraft/modloader/${forge_name}")"
		if [[ ! "${http_code}" =~ ^2 ]]; then
			log_error "CurseForge: modloader ${forge_name} no resolvió (HTTP ${http_code})"
			cat "${tmp}" >&2 2>/dev/null || true
			rm -f "${tmp}"
			return 1
		fi
	fi
	forge_gv_id="$(jq -r '.data.gameVersionId // empty' "${tmp}")"
	rm -f "${tmp}"

	if [[ -z "${mc_gv_id}" || -z "${forge_gv_id}" ]]; then
		log_error "CurseForge: IDs incompletos (MC gameVersionId=${mc_gv_id:-?}, Forge gameVersionId=${forge_gv_id:-?})"
		return 1
	fi
	log_info "CurseForge: gameVersionIds → ${mc_version}=${mc_gv_id}, ${forge_name}=${forge_gv_id}"
	printf '%s,%s' "${mc_gv_id}" "${forge_gv_id}"
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

# Exige que el workflow Build del commit HEAD haya terminado en success.
publish_require_ci_green() {
	local sha short runs conclusion status count
	publish_require_command gh || return 1
	gh auth status &>/dev/null || {
		log_error "GitHub CLI no autenticado (gh auth login)"
		return 1
	}

	sha="$(git -C "${PROJECT_ROOT}" rev-parse HEAD)"
	short="${sha:0:7}"
	log_info "Verificando CI Build para ${short}..."

	runs="$(gh run list --workflow=build.yml --commit "${sha}" --limit 10 \
		--json conclusion,status,databaseId,displayTitle 2>/dev/null || true)"
	count="$(echo "${runs}" | jq 'length' 2>/dev/null || echo 0)"
	if [[ -z "${runs}" || "${count}" == "0" ]]; then
		log_error "No hay runs del workflow Build para el commit ${short}"
		log_info "Hacé push a GitHub, esperá a que Build termine en verde, y reintentá cut"
		return 1
	fi

	if echo "${runs}" | jq -e '[.[] | select(.status != "completed")] | length > 0' &>/dev/null; then
		log_error "Build aún en curso para ${short} — esperá a que termine"
		return 1
	fi

	conclusion="$(echo "${runs}" | jq -r '[.[] | select(.status == "completed")][0].conclusion // empty')"
	status="$(echo "${runs}" | jq -r '[.[] | select(.status == "completed")][0].status // empty')"
	if [[ "${status}" != "completed" || "${conclusion}" != "success" ]]; then
		log_error "Build no está en success para ${short} (conclusion=${conclusion:-<none>})"
		return 1
	fi

	log_ok "Build CI verde para ${short}"
	return 0
}

# Crea y pushea el tag mod_version solo si CI Build está verde.
publish_cut_release() {
	local dry_run="${1:-false}"
	local tag remote_ref

	publish_load_secrets
	publish_require_command git || return 1
	publish_require_command jq || return 1

	tag="$(get_prop mod_version "${GRADLE_PROPERTIES}")"
	[[ -n "${tag}" ]] || {
		log_error "mod_version vacío en gradle.properties"
		return 1
	}

	screen_clear
	echo -e "${BOLD}${CYAN}═══ Cut release (tag) ═══${RESET}"
	echo
	echo "  Tag     : ${tag}"
	echo "  Commit  : $(git -C "${PROJECT_ROOT}" rev-parse --short HEAD)"
	echo "  Rama    : $(git -C "${PROJECT_ROOT}" rev-parse --abbrev-ref HEAD)"
	[[ "${dry_run}" == "true" ]] && echo -e "  ${YELLOW}Modo dry-run${RESET}"
	echo

	if [[ -n "$(git -C "${PROJECT_ROOT}" status --porcelain)" ]]; then
		log_warn "El árbol de git tiene cambios sin commitear"
		if [[ "${INTERACTIVE}" == "true" && "${dry_run}" != "true" ]]; then
			read -r -p "¿Continuar de todos modos? [s/N]: " cont
			[[ "${cont,,}" == "s" || "${cont,,}" == "si" ]] || return 0
		fi
	fi

	publish_require_ci_green || return 1

	remote_ref="$(git -C "${PROJECT_ROOT}" ls-remote --tags "${GITHUB_REMOTE}" "refs/tags/${tag}" 2>/dev/null || true)"
	if [[ -n "${remote_ref}" ]]; then
		log_error "El tag ${tag} ya existe en ${GITHUB_REMOTE}"
		return 1
	fi

	if [[ "${dry_run}" == "true" ]]; then
		log_info "[dry-run] se crearía y pushearía el tag anotado ${tag}"
		log_info "[dry-run] eso dispararía release.yml + publish-distribution.yml → Discord"
		return 0
	fi

	if [[ "${INTERACTIVE}" == "true" ]]; then
		read -r -p "¿Crear y pushear tag ${tag}? [s/N]: " confirm
		[[ "${confirm,,}" == "s" || "${confirm,,}" == "si" ]] || return 0
	fi

	publish_git_tag_and_push "${tag}" false || return 1
	echo
	log_ok "Tag ${tag} en remoto. GitHub Actions debería publicar JARs y notificar Discord."
	log_info "Seguí: Actions → Release + Publish distribution"
}

publish_discord_notify() {
	local tag="$1"
	local dry_run="${2:-false}"
	local -a args=()

	publish_load_secrets
	[[ "${dry_run}" == "true" ]] && args+=(--dry-run)
	args+=("${tag}")

	if [[ ! -x "${SCRIPT_DIR}/discord-notify.sh" ]]; then
		chmod +x "${SCRIPT_DIR}/discord-notify.sh" 2>/dev/null || true
	fi
	"${SCRIPT_DIR}/discord-notify.sh" "${args[@]}"
}

publish_github_release() {
	local tag="$1"
	local notes="$2"
	local dry_run="${3:-false}"
	shift 3 || true
	local -a jars=("$@")
	local jar slug

	if [[ ${#jars[@]} -eq 0 ]]; then
		while IFS='|' read -r _ jar; do
			[[ -n "${jar}" ]] && jars+=("${jar}")
		done < <(publish_list_artifacts)
	fi

	if [[ ${#jars[@]} -eq 0 ]]; then
		log_error "GitHub Release: no hay JARs para subir"
		return 1
	fi

	if [[ "${dry_run}" == "true" ]]; then
		log_info "[dry-run] GitHub Release ${tag} con ${#jars[@]} JAR(s):"
		for jar in "${jars[@]}"; do
			echo "  - $(basename "${jar}")"
		done
		return 0
	fi

	publish_require_command gh || return 1
	slug="$(publish_github_repo_slug)"

	if gh release view "${tag}" --repo "${slug}" &>/dev/null; then
		log_info "Actualizando GitHub Release existente..."
		gh release upload "${tag}" "${jars[@]}" --clobber --repo "${slug}"
		gh release edit "${tag}" --notes "${notes}" --repo "${slug}"
	else
		log_info "Creando GitHub Release con ${#jars[@]} asset(s)..."
		gh release create "${tag}" "${jars[@]}" \
			--title "Console Filter Next ${tag}" \
			--notes "${notes}" \
			--repo "${slug}"
	fi
	log_ok "GitHub Release publicado: ${tag} (${#jars[@]} JAR(s))"
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

publish_modrinth_config_file() {
	local assets="${PROJECT_ROOT}/assets"
	if [[ -f "${assets}/modrinth.json" ]]; then
		echo "${assets}/modrinth.json"
		return 0
	fi
	if [[ -f "${assets}/modrinth.template.json" ]]; then
		log_warn "assets/modrinth.json no existe; usando assets/modrinth.template.json"
		echo "${assets}/modrinth.template.json"
		return 0
	fi
	return 1
}

publish_modrinth_image_ext() {
	local file="$1"
	local ext="${file##*.}"
	case "${ext}" in
		png | jpg | jpeg | bmp | gif | webp | svg | svgz | rgb) echo "${ext}" ;;
		*) echo "png" ;;
	esac
}

publish_modrinth_image_mime() {
	local ext="$1"
	case "${ext}" in
		jpg | jpeg) echo "image/jpeg" ;;
		svg) echo "image/svg+xml" ;;
		svgz) echo "image/svg+xml" ;;
		*) echo "image/${ext}" ;;
	esac
}

publish_modrinth_build_patch_json() {
	local config_file="$1"
	local assets_dir="${PROJECT_ROOT}/assets"
	local body_file body submit patch

	body_file="$(jq -r '.body_file // empty' "${config_file}")"
	[[ -n "${body_file}" && -f "${assets_dir}/${body_file}" ]] || {
		log_error "No se encontró body_file en assets/ (campo body_file de modrinth.json)"
		return 1
	}
	body="$(cat "${assets_dir}/${body_file}")"
	submit="$(jq '.submit_for_review // false' "${config_file}")"

	patch="$(jq \
		--arg body "${body}" \
		--argjson submit "${submit}" \
		'del(._comment, .body_file, .version_changelog_file, .version_environment, .java_versions, .icon_file, .gallery, .submit_for_review)
		| .body = $body
		| if $submit then .requested_status = "approved" else . end' "${config_file}")"
	printf '%s' "${patch}"
}

publish_modrinth_upload_binary_image() {
	local method="$1"
	local url="$2"
	local file="$3"
	local ext mime http_code

	ext="$(publish_modrinth_image_ext "${file}")"
	mime="$(publish_modrinth_image_mime "${ext}")"
	http_code="$(curl -sS -o "${PUBLISH_TMP_DIR}/modrinth-image-response.json" -w "%{http_code}" \
		-X "${method}" "${url}" \
		-H "Authorization: ${MODRINTH_TOKEN}" \
		-H "Content-Type: ${mime}" \
		--data-binary @"${file}")"
	printf '%s' "${http_code}"
}

publish_modrinth_sync_metadata() {
	local project_id="$1"
	local dry_run="${2:-false}"
	local config_file assets_dir patch icon_file http_code submit

	[[ "${SKIP_MODRINTH_METADATA:-false}" == "true" ]] && return 0

	publish_require_command curl || return 1
	publish_require_command jq || return 1

	config_file="$(publish_modrinth_config_file)" || {
		log_warn "Sin assets/modrinth.json; omitiendo sincronización de metadatos Modrinth"
		return 0
	}

	assets_dir="${PROJECT_ROOT}/assets"
	patch="$(publish_modrinth_build_patch_json "${config_file}")" || return 1
	submit="$(jq -r '.submit_for_review // false' "${config_file}")"

	if [[ "${dry_run}" == "true" ]]; then
		log_info "[dry-run] Modrinth PATCH proyecto ${project_id}"
		echo "${patch}" | jq .
		jq -c '.gallery[]? // empty' "${config_file}" 2>/dev/null || true
		return 0
	fi

	PUBLISH_TMP_DIR="${PUBLISH_TMP_DIR:-$(mktemp -d)}"
	printf '%s' "${patch}" >"${PUBLISH_TMP_DIR}/modrinth-patch.json"

	http_code="$(curl -sS -o "${PUBLISH_TMP_DIR}/modrinth-patch-response.json" -w "%{http_code}" \
		-X PATCH "https://api.modrinth.com/v2/project/${project_id}" \
		-H "Authorization: ${MODRINTH_TOKEN}" \
		-H "Content-Type: application/json" \
		--data-binary @"${PUBLISH_TMP_DIR}/modrinth-patch.json")"
	if [[ ! "${http_code}" =~ ^2 ]]; then
		log_error "Modrinth PATCH proyecto falló (HTTP ${http_code})"
		cat "${PUBLISH_TMP_DIR}/modrinth-patch-response.json" 2>/dev/null || true
		return 1
	fi
	log_ok "Modrinth: metadatos del proyecto actualizados"

	icon_file="$(jq -r '.icon_file // empty' "${config_file}")"
	if [[ -n "${icon_file}" && -f "${assets_dir}/${icon_file}" ]]; then
		local ext icon_code
		ext="$(publish_modrinth_image_ext "${assets_dir}/${icon_file}")"
		icon_code="$(publish_modrinth_upload_binary_image PATCH \
			"https://api.modrinth.com/v2/project/${project_id}/icon?ext=${ext}" \
			"${assets_dir}/${icon_file}")"
		if [[ "${icon_code}" =~ ^2 ]]; then
			log_ok "Modrinth: icono subido"
		else
			log_warn "Modrinth: falló la subida del icono (HTTP ${icon_code})"
		fi
	fi

	local gallery_count i file featured title description ordering ext query_url gal_code gal_err
	gallery_count="$(jq '.gallery | length // 0' "${config_file}")"
	for ((i = 0; i < gallery_count; i++)); do
		file="$(jq -r ".gallery[${i}].file // empty" "${config_file}")"
		[[ -n "${file}" && -f "${assets_dir}/${file}" ]] || continue
		featured="$(jq -r ".gallery[${i}].featured // false" "${config_file}")"
		title="$(jq -r ".gallery[${i}].title // \"\"" "${config_file}")"
		description="$(jq -r ".gallery[${i}].description // \"\"" "${config_file}")"
		ordering="$(jq -r ".gallery[${i}].ordering // ${i}" "${config_file}")"
		ext="$(publish_modrinth_image_ext "${assets_dir}/${file}")"
		query_url="https://api.modrinth.com/v2/project/${project_id}/gallery?ext=${ext}&featured=${featured}&ordering=${ordering}"
		[[ -n "${title}" ]] && query_url+="&title=$(printf '%s' "${title}" | jq -sRr @uri)"
		[[ -n "${description}" ]] && query_url+="&description=$(printf '%s' "${description}" | jq -sRr @uri)"
		gal_code="$(publish_modrinth_upload_binary_image POST "${query_url}" "${assets_dir}/${file}")"
		if [[ "${gal_code}" =~ ^2 ]]; then
			log_ok "Modrinth: imagen de galería subida (${file})"
		else
			gal_err="$(jq -r '.description // empty' "${PUBLISH_TMP_DIR}/modrinth-image-response.json" 2>/dev/null || true)"
			if [[ "${gal_err}" == *duplicate* ]]; then
				log_info "Modrinth: galería ya contenía ${file} (omitida)"
			else
				log_warn "Modrinth: falló galería ${file} (HTTP ${gal_code})"
			fi
		fi
	done

	if [[ "${submit}" == "true" ]]; then
		log_info "Modrinth: solicitada revisión (requested_status=approved)"
	else
		log_info "Modrinth: proyecto aún en draft — activá submit_for_review en assets/modrinth.json o enviá desde el panel"
	fi
	return 0
}

publish_modrinth_upload() {
	local tag="$1"
	local jar="$2"
	local changelog="$3"
	local dry_run="${4:-false}"
	local loader="${5:-forge}"
	local sync_metadata="${6:-true}"
	local mc_version project_id json http_code modrinth_env version_number version_name

	[[ -n "${MODRINTH_TOKEN}" ]] || {
		log_warn "MODRINTH_TOKEN no configurado; omitiendo Modrinth"
		return 0
	}

	publish_require_command curl || return 1
	publish_require_command jq || return 1

	project_id="$(publish_resolve_modrinth_project_id)" || return 1

	if [[ "${sync_metadata}" == "true" ]]; then
		publish_modrinth_sync_metadata "${project_id}" "${dry_run}" || return 1
	fi

	if [[ "${SKIP_MODRINTH_VERSION_UPLOAD:-false}" == "true" ]]; then
		[[ "${dry_run}" != "true" ]] && log_ok "Modrinth: omitida subida de versión (--skip-modrinth-version-upload)"
		return 0
	fi

	mc_version="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
	PUBLISH_TMP_DIR="${PUBLISH_TMP_DIR:-$(mktemp -d)}"
	modrinth_env="$(publish_modrinth_version_environment)"
	version_number="${tag}+${loader}"
	version_name="${tag} ($(publish_loader_display_name "${loader}"))"
	json="$(jq -n \
		--arg project_id "${project_id}" \
		--arg version_number "${version_number}" \
		--arg name "${version_name}" \
		--arg changelog "${changelog}" \
		--arg mc "${mc_version}" \
		--arg loader "${loader}" \
		--arg vtype "${RELEASE_TYPE}" \
		--arg environment "${modrinth_env}" \
		'{
			project_id: $project_id,
			version_number: $version_number,
			name: $name,
			changelog: $changelog,
			dependencies: [],
			game_versions: [$mc],
			version_type: $vtype,
			loaders: [$loader],
			environment: $environment,
			featured: false,
			file_parts: ["file"],
			primary_file: "file"
		}')"

	if [[ "${dry_run}" == "true" ]]; then
		log_info "[dry-run] Modrinth upload [${loader}] → proyecto ${project_id} ($(basename "${jar}"))"
		echo "${json}" | jq .
		return 0
	fi

	printf '%s' "${json}" >"${PUBLISH_TMP_DIR}/modrinth-payload-${loader}.json"
	http_code="$(curl -sS -o "${PUBLISH_TMP_DIR}/modrinth-response-${loader}.json" -w "%{http_code}" \
		-X POST "https://api.modrinth.com/v2/version" \
		-H "Authorization: ${MODRINTH_TOKEN}" \
		-F "data=@${PUBLISH_TMP_DIR}/modrinth-payload-${loader}.json;type=application/json" \
		-F "file=@${jar}")"

	if [[ "${http_code}" =~ ^2 ]]; then
		log_ok "Modrinth [${loader}]: versión ${version_number} publicada (HTTP ${http_code})"
		return 0
	fi

	log_error "Modrinth upload [${loader}] falló (HTTP ${http_code})"
	cat "${PUBLISH_TMP_DIR}/modrinth-response-${loader}.json" 2>/dev/null || true
	return 1
}

publish_modrinth_upload_all() {
	local tag="$1"
	local changelog="$2"
	local dry_run="${3:-false}"
	local loader jar sync_metadata=true
	local project_id
	local found=0

	while IFS='|' read -r loader jar; do
		[[ -n "${loader}" && -n "${jar}" ]] || continue
		found=1
		publish_modrinth_upload "${tag}" "${jar}" "${changelog}" "${dry_run}" "${loader}" "${sync_metadata}" || return 1
		sync_metadata=false
	done < <(publish_list_artifacts)

	# Solo metadatos (sin JARs): p. ej. --modrinth-sync-only
	if [[ "${found}" -eq 0 ]]; then
		if [[ "${SKIP_MODRINTH_VERSION_UPLOAD:-false}" != "true" ]]; then
			log_error "Modrinth: no hay JARs para subir"
			return 1
		fi
		[[ -n "${MODRINTH_TOKEN}" ]] || {
			log_warn "MODRINTH_TOKEN no configurado; omitiendo Modrinth"
			return 0
		}
		project_id="$(publish_resolve_modrinth_project_id)" || return 1
		publish_modrinth_sync_metadata "${project_id}" "${dry_run}" || return 1
		[[ "${dry_run}" != "true" ]] && log_ok "Modrinth: omitida subida de versión (--skip-modrinth-version-upload)"
	fi
}

publish_curseforge_fallback_loader_id() {
	case "$1" in
		forge) echo "7498" ;;
		fabric) echo "7499" ;;
		neoforge) echo "10150" ;;
		*) return 1 ;;
	esac
}

# Resuelve el gameVersion id del loader (Forge/Fabric/NeoForge) vía Upload API.
publish_curseforge_resolve_loader_id() {
	local loader="$1"
	local author_token="$2"
	local versions_json="$3"
	local display_name id

	display_name="$(publish_loader_display_name "${loader}")"
	if [[ -n "${versions_json}" && -f "${versions_json}" ]]; then
		id="$(jq -r --arg name "${display_name}" \
			'.[] | select(.name == $name) | .id' "${versions_json}" | head -1)"
		if [[ -n "${id}" && "${id}" != "null" ]]; then
			echo "${id}"
			return 0
		fi
	fi

	if [[ -n "${author_token}" ]]; then
		local tmp
		tmp="$(mktemp)"
		if curl -fsS -o "${tmp}" -H "X-Api-Token: ${author_token}" \
			"https://minecraft.curseforge.com/api/game/versions"; then
			id="$(jq -r --arg name "${display_name}" \
				'.[] | select(.name == $name) | .id' "${tmp}" | head -1)"
			rm -f "${tmp}"
			if [[ -n "${id}" && "${id}" != "null" ]]; then
				echo "${id}"
				return 0
			fi
		else
			rm -f "${tmp}"
		fi
	fi

	publish_curseforge_fallback_loader_id "${loader}"
}

publish_curseforge_upload_game_version_ids() {
	local mc_version="$1"
	local author_token="$2"
	local loader="${3:-forge}"
	local mc_series="${mc_version%.*}"
	local tmp types_id mc_id java_name java_id loader_id env_id
	local -a game_ids=()

	tmp="$(mktemp)"
	if ! curl -fsS -o "${tmp}" -H "X-Api-Token: ${author_token}" \
		"https://minecraft.curseforge.com/api/game/version-types"; then
		rm -f "${tmp}"
		return 1
	fi
	types_id="$(jq -r --arg series "Minecraft ${mc_series}" '.[] | select(.name == $series) | .id' "${tmp}" | head -1)"
	rm -f "${tmp}"
	[[ -n "${types_id}" && "${types_id}" != "null" ]] || return 1

	tmp="$(mktemp)"
	if ! curl -fsS -o "${tmp}" -H "X-Api-Token: ${author_token}" \
		"https://minecraft.curseforge.com/api/game/versions"; then
		rm -f "${tmp}"
		return 1
	fi
	mc_id="$(jq -r --arg mc "${mc_version}" --argjson tid "${types_id}" \
		'.[] | select(.name == $mc and .gameVersionTypeID == $tid) | .id' "${tmp}" | head -1)"
	[[ -n "${mc_id}" && "${mc_id}" != "null" ]] || {
		rm -f "${tmp}"
		return 1
	}

	game_ids+=("${mc_id}")
	while IFS= read -r java_name; do
		[[ -n "${java_name}" ]] || continue
		java_id="$(jq -r --arg j "${java_name}" '.[] | select(.name == $j) | .id' "${tmp}" | head -1)"
		if [[ -z "${java_id}" || "${java_id}" == "null" ]]; then
			log_error "CurseForge: versión ${java_name} no encontrada en game/versions"
			rm -f "${tmp}"
			return 1
		fi
		game_ids+=("${java_id}")
	done < <(publish_curseforge_java_versions "${mc_version}")

	loader_id="$(publish_curseforge_resolve_loader_id "${loader}" "${author_token}" "${tmp}")" || {
		rm -f "${tmp}"
		return 1
	}
	game_ids+=("${loader_id}")

	# CurseForge exige ≥1 versión del grupo Environment (Client / Server).
	for env_name in Client Server; do
		env_id="$(jq -r --arg n "${env_name}" '.[] | select(.name == $n) | .id' "${tmp}" | head -1)"
		if [[ -z "${env_id}" || "${env_id}" == "null" ]]; then
			log_error "CurseForge: versión Environment '${env_name}' no encontrada"
			rm -f "${tmp}"
			return 1
		fi
		game_ids+=("${env_id}")
	done
	rm -f "${tmp}"

	log_info "CurseForge [${loader}]: gameVersions → ${mc_version}=${mc_id}, Java=$(publish_curseforge_java_versions "${mc_version}" | paste -sd, -), $(publish_loader_display_name "${loader}")=${loader_id}, Environment=Client+Server"
	jq -n --argjson ids "$(printf '%s\n' "${game_ids[@]}" | jq -R 'tonumber' | jq -s '.')" '$ids'
}

publish_curseforge_upload() {
	local tag="$1"
	local jar="$2"
	local changelog="$3"
	local dry_run="${4:-false}"
	local loader="${5:-forge}"
	local mc_version project_id metadata http_code author_token game_version_ids display_name

	author_token="$(publish_curseforge_author_token)" || {
		log_error "CurseForge upload requiere CURSEFORGE_AUTHOR_TOKEN"
		log_error "Generalo en https://www.curseforge.com/account/api-tokens"
		log_error "El Profile API key (cfc_pat_…, console.curseforge.com) solo resuelve versiones/proyecto; no sube archivos."
		return 1
	}

	publish_require_command curl || return 1
	publish_require_command jq || return 1

	project_id="$(publish_resolve_curseforge_project_id)" || return 1

	mc_version="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
	game_version_ids="$(publish_curseforge_upload_game_version_ids "${mc_version}" "${author_token}" "${loader}")" || {
		log_error "No se pudieron resolver gameVersions de CurseForge para ${mc_version} + $(publish_loader_display_name "${loader}") + Java"
		return 1
	}

	display_name="${tag} [$(publish_loader_display_name "${loader}")]"
	metadata="$(jq -n \
		--arg changelog "${changelog}" \
		--arg displayName "${display_name}" \
		--arg releaseType "${RELEASE_TYPE}" \
		--argjson gameVersions "${game_version_ids}" \
		'{
			changelog: $changelog,
			changelogType: "markdown",
			displayName: $displayName,
			gameVersions: $gameVersions,
			releaseType: $releaseType
		}')"

	if [[ "${dry_run}" == "true" ]]; then
		log_info "[dry-run] CurseForge upload [${loader}] → proyecto ${project_id} ($(basename "${jar}"))"
		echo "${metadata}" | jq .
		return 0
	fi

	PUBLISH_TMP_DIR="${PUBLISH_TMP_DIR:-$(mktemp -d)}"
	printf '%s' "${metadata}" >"${PUBLISH_TMP_DIR}/curseforge-metadata-${loader}.json"
	# Upload API espera metadata como campo de texto JSON, no como file part (@file).
	http_code="$(curl -sS -o "${PUBLISH_TMP_DIR}/curseforge-response-${loader}.json" -w "%{http_code}" \
		-X POST "https://minecraft.curseforge.com/api/projects/${project_id}/upload-file" \
		-H "X-Api-Token: ${author_token}" \
		-F "metadata=<${PUBLISH_TMP_DIR}/curseforge-metadata-${loader}.json" \
		-F "file=@${jar}")"

	if [[ "${http_code}" =~ ^2 ]]; then
		log_ok "CurseForge [${loader}]: archivo subido (HTTP ${http_code})"
		return 0
	fi

	log_error "CurseForge upload [${loader}] falló (HTTP ${http_code})"
	if jq -e . "${PUBLISH_TMP_DIR}/curseforge-response-${loader}.json" &>/dev/null; then
		jq -r '.errorMessage // .message // .' "${PUBLISH_TMP_DIR}/curseforge-response-${loader}.json" >&2
	else
		head -c 800 "${PUBLISH_TMP_DIR}/curseforge-response-${loader}.json" >&2 2>/dev/null || true
	fi
	return 1
}

publish_curseforge_upload_all() {
	local tag="$1"
	local changelog="$2"
	local dry_run="${3:-false}"
	local loader jar
	local any=0

	while IFS='|' read -r loader jar; do
		[[ -n "${loader}" && -n "${jar}" ]] || continue
		any=1
		publish_curseforge_upload "${tag}" "${jar}" "${changelog}" "${dry_run}" "${loader}" || return 1
	done < <(publish_list_artifacts)

	[[ "${any}" -eq 1 ]] || {
		log_error "CurseForge: no hay JARs para subir"
		return 1
	}
	[[ "${dry_run}" != "true" ]] && publish_curseforge_remind_gallery
	return 0
}

publish_curseforge_expand_social_url() {
	local template="$1"
	local username="$2"
	printf '%s' "${template//\{username\}/${username}}"
}

publish_curseforge_remind_social_links() {
	local cf_json="${PROJECT_ROOT}/assets/curseforge.json"
	local username key template url label

	[[ -f "${cf_json}" ]] || return 0
	publish_require_command jq || return 0

	username="$(jq -r '.social_username // "alanjmrt94"' "${cf_json}")"
	if ! jq -e '.social_links | length > 0' "${cf_json}" &>/dev/null; then
		return 0
	fi

	log_info "CurseForge: configurá Social Links manualmente (Authors → Console Filter Next → Links):"
	local project_id="${CURSEFORGE_PROJECT_ID:-1257873}"
	log_info "  https://authors.curseforge.com/#/projects/${project_id}/settings/links"
	while IFS=$'\t' read -r key template; do
		[[ -n "${key}" && -n "${template}" ]] || continue
		url="$(publish_curseforge_expand_social_url "${template}" "${username}")"
		case "${key}" in
			discord) label="Discord" ;;
			github) label="GitHub" ;;
			x) label="X (Twitter)" ;;
			instagram) label="Instagram" ;;
			facebook) label="Facebook" ;;
			*) label="${key}" ;;
		esac
		echo "  ${label}: ${url}"
	done < <(jq -r '.social_links | to_entries[] | "\(.key)\t\(.value)"' "${cf_json}")

	if jq -e '.project_links' "${cf_json}" &>/dev/null; then
		echo
		log_info "CurseForge: Project Links (misma pantalla o Project settings):"
		jq -r '.project_links | to_entries[] | "  \(.key): \(.value)"' "${cf_json}"
	fi
}

publish_curseforge_remind_gallery() {
	publish_curseforge_remind_social_links
	local cf_json="${PROJECT_ROOT}/assets/curseforge.json"
	local assets_dir="${PROJECT_ROOT}/assets"
	local count i file title description abs

	[[ -f "${cf_json}" ]] || return 0

	publish_require_command jq || return 0

	count="$(jq '.gallery | length // 0' "${cf_json}")"
	[[ "${count}" -gt 0 ]] || return 0

	log_info "CurseForge: subí estas capturas manualmente en el panel del proyecto (Images / Gallery):"
	for ((i = 0; i < count; i++)); do
		file="$(jq -r ".gallery[${i}].file // empty" "${cf_json}")"
		title="$(jq -r ".gallery[${i}].title // \"\"" "${cf_json}")"
		description="$(jq -r ".gallery[${i}].description // \"\"" "${cf_json}")"
		[[ -n "${file}" ]] || continue
		abs="${assets_dir}/${file}"
		if [[ -f "${abs}" ]]; then
			echo "  → ${abs}"
			[[ -n "${title}" ]] && echo "    ${title}"
			[[ -n "${description}" ]] && echo "    ${description}"
		else
			log_warn "  Falta archivo de galería: ${abs}"
		fi
	done
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

	if [[ "${SKIP_CURSEFORGE:-false}" != "true" && -z "${CURSEFORGE_API_TOKEN}" && -z "${CURSEFORGE_PROJECT_ID}" ]]; then
		log_warn "Sin CURSEFORGE_API_TOKEN ni CURSEFORGE_PROJECT_ID — CurseForge se omitirá"
	fi
	if [[ "${SKIP_CURSEFORGE:-false}" != "true" ]] && ! publish_curseforge_author_token &>/dev/null; then
		log_warn "Sin CURSEFORGE_AUTHOR_TOKEN — la subida a CurseForge fallará (cfc_pat_ no es válido para upload)"
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

	local tag changelog modrinth_changelog curseforge_changelog mc_version mod_name
	local -a jars=()
	local loader jar
	tag="$(get_prop mod_version "${GRADLE_PROPERTIES}")"
	mod_name="$(get_prop mod_name "${GRADLE_PROPERTIES}")"
	mc_version="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
	changelog="$(publish_extract_changelog "${tag}")"
	modrinth_changelog="$(publish_extract_modrinth_changelog 2>/dev/null || true)"
	curseforge_changelog="$(publish_extract_curseforge_changelog 2>/dev/null || true)"
	[[ -n "${modrinth_changelog}" ]] || modrinth_changelog="${changelog}"
	[[ -n "${curseforge_changelog}" ]] || curseforge_changelog="${changelog}"

	screen_clear
	echo -e "${BOLD}${CYAN}═══ Publicar release ═══${RESET}"
	echo
	echo "  Mod          : ${mod_name}"
	echo "  Versión/tag  : ${tag}"
	echo "  Minecraft    : ${mc_version}"
	echo "  Loaders      : $(publish_release_loaders | awk '{printf sep$0; sep=", "}')"
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
		read -r -p "¿Publicar ${tag} (Forge+Fabric+NeoForge) en GitHub + Modrinth + CurseForge? [s/N]: " confirm
		[[ "${confirm,,}" == "s" || "${confirm,,}" == "si" ]] || return 0
	fi

	if [[ "${skip_build}" != "true" ]]; then
		publish_build_release || { pause; return 1; }
	fi

	# Metadatos Modrinth sin re-subir JARs (p. ej. --modrinth-sync-only).
	if [[ "${SKIP_MODRINTH_VERSION_UPLOAD:-false}" == "true" && "${SKIP_CURSEFORGE:-false}" == "true" && "${SKIP_GITHUB:-false}" == "true" ]]; then
		if [[ "${SKIP_MODRINTH:-false}" != "true" ]]; then
			publish_modrinth_upload_all "${tag}" "${modrinth_changelog}" "${dry_run}" || { pause; return 1; }
		fi
		echo
		log_ok "Sincronización Modrinth completada para ${tag}"
		pause
		return 0
	fi

	publish_require_artifacts || {
		log_error "JARs incompletos. Ejecuta la compilación multi-loader primero."
		pause
		return 1
	}

	while IFS='|' read -r loader jar; do
		jars+=("${jar}")
		log_ok "JAR [${loader}]: $(basename "${jar}")"
	done < <(publish_list_artifacts)

	if [[ "${SKIP_GITHUB:-false}" != "true" ]]; then
		if [[ "${dry_run}" != "true" ]]; then
			publish_git_tag_and_push "${tag}" "${push_branch}" || { pause; return 1; }
		fi
		publish_github_release "${tag}" "${changelog}" "${dry_run}" "${jars[@]}" || { pause; return 1; }
	fi

	if [[ "${SKIP_MODRINTH:-false}" != "true" ]]; then
		publish_modrinth_upload_all "${tag}" "${modrinth_changelog}" "${dry_run}" || { pause; return 1; }
	fi

	if [[ "${SKIP_CURSEFORGE:-false}" != "true" ]]; then
		publish_curseforge_upload_all "${tag}" "${curseforge_changelog}" "${dry_run}" || { pause; return 1; }
	fi

	# Aviso Discord tras Modrinth/CurseForge (o publish local completo).
	if [[ "${SKIP_DISCORD:-false}" != "true" ]]; then
		publish_discord_notify "${tag}" "${dry_run}" || log_warn "Notificación Discord falló (release ya publicado)"
	fi

	echo
	log_ok "Proceso de publicación completado para ${tag} (${#jars[@]} JAR(s))"
	if [[ "${SKIP_CURSEFORGE:-false}" == "true" ]]; then
		publish_curseforge_remind_gallery
	fi
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
		echo "  4) Solo compilar JARs de release (Forge+Fabric+NeoForge)"
		echo "  5) Cut: verificar CI verde y pushear tag (dispara Actions + Discord)"
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
			4) publish_build_release && publish_require_artifacts; pause ;;
			5) publish_cut_release false; pause ;;
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
	SKIP_MODRINTH_METADATA=false
	SKIP_MODRINTH_VERSION_UPLOAD=false
	SKIP_DISCORD=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--dry-run) dry_run=true ;;
			--skip-build) skip_build=true ;;
			--no-push-branch) push_branch=false ;;
			--push-branch) push_branch=true ;;
			--skip-github) SKIP_GITHUB=true ;;
			--skip-modrinth) SKIP_MODRINTH=true ;;
			--skip-curseforge) SKIP_CURSEFORGE=true ;;
			--skip-discord) SKIP_DISCORD=true ;;
			--skip-modrinth-metadata) SKIP_MODRINTH_METADATA=true ;;
			--skip-modrinth-version-upload) SKIP_MODRINTH_VERSION_UPLOAD=true ;;
			--modrinth-sync-only)
				SKIP_GITHUB=true
				SKIP_CURSEFORGE=true
				skip_build=true
				SKIP_MODRINTH_VERSION_UPLOAD=true
				SKIP_DISCORD=true
				;;
			-h|--help)
				cat <<EOF
Uso: $(basename "$0") publish [opciones]

  --dry-run           Simular sin git push ni subidas
  --skip-build        Usar JARs existentes (forge/fabric/neoforge build/libs)
  --push-branch       Subir la rama actual antes del tag (default en menú opción 2)
  --no-push-branch    No subir la rama
  --skip-github       Omitir tag y GitHub Release
  --skip-modrinth     Omitir Modrinth
  --skip-curseforge   Omitir CurseForge
  --skip-discord      Omitir notificación Discord
  --skip-modrinth-metadata         No actualizar descripción/licencia/icono/galería
  --skip-modrinth-version-upload   Solo metadatos Modrinth (sin subir JARs)
  --modrinth-sync-only             Igual que --skip-build --skip-github --skip-curseforge
                                   y solo sincronizar assets/modrinth.json

También: $(basename "$0") cut [--dry-run]
  Verifica que Build CI esté verde en HEAD, crea el tag mod_version y lo pushea.
  El tag dispara release.yml + publish-distribution.yml (Modrinth/CF + Discord).

Publica un tag (mod_version) con 3 JARs:
  • GitHub Release: forge + fabric + neoforge como assets
  • Modrinth: una versión por loader (version_number = TAG+loader)
  • CurseForge: un archivo por loader con gameVersions del loader correcto
  • Discord: webhook del canal del mod (DISCORD_WEBHOOK_URL)

Configura tokens en scripts/.release.local (ver .release.local.example)
Metadatos Modrinth: assets/modrinth.json, assets/modrinth-body.md, assets/icon.png

Modrinth:
  • MODRINTH_PROJECT_ID = ID Base62 (panel → Projects → columna ID).
  • Obligatorio en proyectos Draft; el slug no resuelve hasta aprobar el proyecto.
  • No usar el nombre del proyecto (solo Base62).
  • Tras publicar, reintentar con --skip-build --skip-github si GitHub ya terminó.
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

publish_cut_cli() {
	local dry_run=false
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--dry-run) dry_run=true ;;
			-h|--help)
				cat <<EOF
Uso: $(basename "$0") cut [--dry-run]

  1) Comprueba que el workflow Build del commit HEAD terminó en success
  2) Crea el tag anotado = mod_version (si no existe)
  3) Pushea el tag → Actions publica JARs y notifica Discord

Requiere: gh autenticado, push del commit a GitHub, Build verde.
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
	publish_cut_release "${dry_run}"
}
