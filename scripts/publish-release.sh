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
	local mc_version project_id json response http_code modrinth_env

	[[ -n "${MODRINTH_TOKEN}" ]] || {
		log_warn "MODRINTH_TOKEN no configurado; omitiendo Modrinth"
		return 0
	}

	publish_require_command curl || return 1
	publish_require_command jq || return 1

	project_id="$(publish_resolve_modrinth_project_id)" || return 1

	publish_modrinth_sync_metadata "${project_id}" "${dry_run}" || return 1

	if [[ "${SKIP_MODRINTH_VERSION_UPLOAD:-false}" == "true" ]]; then
		[[ "${dry_run}" != "true" ]] && log_ok "Modrinth: omitida subida de versión (--skip-modrinth-version-upload)"
		return 0
	fi

	mc_version="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
	PUBLISH_TMP_DIR="$(mktemp -d)"
	modrinth_env="$(publish_modrinth_version_environment)"
	json="$(jq -n \
		--arg project_id "${project_id}" \
		--arg version_number "${tag}" \
		--arg name "${tag}" \
		--arg changelog "${changelog}" \
		--arg mc "${mc_version}" \
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
			loaders: ["forge"],
			environment: $environment,
			featured: false,
			file_parts: ["file"],
			primary_file: "file"
		}')"

	if [[ "${dry_run}" == "true" ]]; then
		log_info "[dry-run] Modrinth upload → proyecto ${project_id}"
		echo "${json}" | jq .
		return 0
	fi

	printf '%s' "${json}" >"${PUBLISH_TMP_DIR}/modrinth-payload.json"
	http_code="$(curl -sS -o "${PUBLISH_TMP_DIR}/modrinth-response.json" -w "%{http_code}" \
		-X POST "https://api.modrinth.com/v2/version" \
		-H "Authorization: ${MODRINTH_TOKEN}" \
		-F "data=@${PUBLISH_TMP_DIR}/modrinth-payload.json;type=application/json" \
		-F "file=@${jar}")"

	if [[ "${http_code}" =~ ^2 ]]; then
		log_ok "Modrinth: versión publicada (HTTP ${http_code})"
		return 0
	fi

	log_error "Modrinth upload falló (HTTP ${http_code})"
	cat "${PUBLISH_TMP_DIR}/modrinth-response.json" 2>/dev/null || true
	return 1
}

publish_curseforge_upload_game_version_ids() {
	local mc_version="$1"
	local author_token="$2"
	local mc_series="${mc_version%.*}"
	local forge_id=7498
	local tmp types_id mc_id java_name java_id
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
	rm -f "${tmp}"

	game_ids+=("${forge_id}")
	log_info "CurseForge: gameVersions → ${mc_version}=${mc_id}, Java=$(publish_curseforge_java_versions "${mc_version}" | paste -sd, -), Forge=${forge_id}"
	jq -n --argjson ids "$(printf '%s\n' "${game_ids[@]}" | jq -R 'tonumber' | jq -s '.')" '$ids'
}

publish_curseforge_upload() {
	local tag="$1"
	local jar="$2"
	local changelog="$3"
	local dry_run="${4:-false}"
	local mc_version project_id metadata http_code author_token game_version_ids

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
	game_version_ids="$(publish_curseforge_upload_game_version_ids "${mc_version}" "${author_token}")" || {
		log_error "No se pudieron resolver gameVersions de CurseForge para ${mc_version} + Forge + Java"
		return 1
	}

	metadata="$(jq -n \
		--arg changelog "${changelog}" \
		--arg displayName "${tag}" \
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
		log_info "[dry-run] CurseForge upload → proyecto ${project_id}"
		echo "${metadata}" | jq .
		return 0
	fi

	PUBLISH_TMP_DIR="${PUBLISH_TMP_DIR:-$(mktemp -d)}"
	printf '%s' "${metadata}" >"${PUBLISH_TMP_DIR}/curseforge-metadata.json"
	# Upload API espera metadata como campo de texto JSON, no como file part (@file).
	http_code="$(curl -sS -o "${PUBLISH_TMP_DIR}/curseforge-response.json" -w "%{http_code}" \
		-X POST "https://minecraft.curseforge.com/api/projects/${project_id}/upload-file" \
		-H "X-Api-Token: ${author_token}" \
		-F "metadata=<${PUBLISH_TMP_DIR}/curseforge-metadata.json" \
		-F "file=@${jar}")"

	if [[ "${http_code}" =~ ^2 ]]; then
		log_ok "CurseForge: archivo subido (HTTP ${http_code})"
		publish_curseforge_remind_gallery
		return 0
	fi

	log_error "CurseForge upload falló (HTTP ${http_code})"
	if jq -e . "${PUBLISH_TMP_DIR}/curseforge-response.json" &>/dev/null; then
		jq -r '.errorMessage // .message // .' "${PUBLISH_TMP_DIR}/curseforge-response.json" >&2
	else
		head -c 800 "${PUBLISH_TMP_DIR}/curseforge-response.json" >&2 2>/dev/null || true
	fi
	return 1
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

	local tag jar changelog modrinth_changelog curseforge_changelog mc_version mod_name
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
		publish_modrinth_upload "${tag}" "${jar}" "${modrinth_changelog}" "${dry_run}" || { pause; return 1; }
	fi

	if [[ "${SKIP_CURSEFORGE:-false}" != "true" ]]; then
		publish_curseforge_upload "${tag}" "${jar}" "${curseforge_changelog}" "${dry_run}" || { pause; return 1; }
	fi

	echo
	log_ok "Proceso de publicación completado para ${tag}"
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
	SKIP_MODRINTH_METADATA=false
	SKIP_MODRINTH_VERSION_UPLOAD=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--dry-run) dry_run=true ;;
			--skip-build) skip_build=true ;;
			--no-push-branch) push_branch=false ;;
			--push-branch) push_branch=true ;;
			--skip-github) SKIP_GITHUB=true ;;
			--skip-modrinth) SKIP_MODRINTH=true ;;
			--skip-curseforge) SKIP_CURSEFORGE=true ;;
			--skip-modrinth-metadata) SKIP_MODRINTH_METADATA=true ;;
			--skip-modrinth-version-upload) SKIP_MODRINTH_VERSION_UPLOAD=true ;;
			--modrinth-sync-only)
				SKIP_GITHUB=true
				SKIP_CURSEFORGE=true
				skip_build=true
				SKIP_MODRINTH_VERSION_UPLOAD=true
				;;
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
  --skip-modrinth-metadata         No actualizar descripción/licencia/icono/galería
  --skip-modrinth-version-upload   Solo metadatos Modrinth (sin subir JAR)
  --modrinth-sync-only             Igual que --skip-build --skip-github --skip-curseforge
                                   y solo sincronizar assets/modrinth.json

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
