#!/usr/bin/env bash
# Notifica un release al canal Discord del mod vía Incoming Webhook.
# No imprime la URL del webhook (secret). Si falta DISCORD_WEBHOOK_URL, avisa y sale 0.
#
# Uso:
#   ./scripts/discord-notify.sh [--dry-run] [TAG]
#
# Env:
#   DISCORD_WEBHOOK_URL       — obligatorio para enviar
#   MODRINTH_PROJECT_SLUG     — default consolefilternext
#   CURSEFORGE_PROJECT_SLUG   — default consolefilternext
#   GITHUB_REPOSITORY         — owner/repo (CI); si falta, se infiere del remote

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GRADLE_PROPERTIES="${PROJECT_ROOT}/gradle.properties"

DRY_RUN=false
TAG=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--dry-run) DRY_RUN=true ;;
		-h|--help)
			cat <<'EOF'
Uso: discord-notify.sh [--dry-run] [TAG]

Envía un embed al webhook Discord del canal del mod con links a
GitHub Release, Modrinth y CurseForge.

  DISCORD_WEBHOOK_URL     Secret (GitHub environment publish o .release.local)
  MODRINTH_PROJECT_SLUG   default: consolefilternext
  CURSEFORGE_PROJECT_SLUG default: consolefilternext
EOF
			exit 0
			;;
		-*)
			echo "Opción desconocida: $1" >&2
			exit 1
			;;
		*)
			TAG="$1"
			;;
	esac
	shift
done

if [[ -z "${TAG}" ]]; then
	TAG="$(grep -E '^mod_version=' "${GRADLE_PROPERTIES}" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r')"
fi
[[ -n "${TAG}" ]] || {
	echo "✖  No se pudo determinar el tag (pasá TAG o definí mod_version)" >&2
	exit 1
}

MOD_NAME="$(grep -E '^mod_name=' "${GRADLE_PROPERTIES}" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r')"
MOD_NAME="${MOD_NAME:-Console Filter Next}"
MR_SLUG="${MODRINTH_PROJECT_SLUG:-consolefilternext}"
CF_SLUG="${CURSEFORGE_PROJECT_SLUG:-consolefilternext}"

REPO_SLUG="${GITHUB_REPOSITORY:-}"
if [[ -z "${REPO_SLUG}" ]]; then
	remote_url="$(git -C "${PROJECT_ROOT}" remote get-url origin 2>/dev/null || true)"
	case "${remote_url}" in
		git@github.com:*)
			REPO_SLUG="$(echo "${remote_url#git@github.com:}" | sed 's/\.git$//')"
			;;
		https://github.com/*)
			REPO_SLUG="$(echo "${remote_url#https://github.com/}" | sed 's/\.git$//')"
			;;
		*)
			REPO_SLUG="alanjmrt94/ConsoleFilterNext"
			;;
	esac
fi

GH_URL="https://github.com/${REPO_SLUG}/releases/tag/${TAG}"
MR_URL="https://modrinth.com/mod/${MR_SLUG}"
CF_URL="https://www.curseforge.com/minecraft/mc-mods/${CF_SLUG}"

if [[ -z "${DISCORD_WEBHOOK_URL:-}" ]]; then
	echo "⚠  DISCORD_WEBHOOK_URL no definido — omitiendo notificación Discord" >&2
	exit 0
fi

if ! command -v jq &>/dev/null; then
	echo "✖  Falta jq para armar el payload Discord" >&2
	exit 1
fi
if ! command -v curl &>/dev/null; then
	echo "✖  Falta curl para enviar el webhook Discord" >&2
	exit 1
fi

payload="$(jq -n \
	--arg content "**${MOD_NAME}** \`${TAG}\` is out." \
	--arg title "${MOD_NAME} ${TAG}" \
	--arg desc "New release published." \
	--arg gh "${GH_URL}" \
	--arg mr "${MR_URL}" \
	--arg cf "${CF_URL}" \
	'{
		content: $content,
		embeds: [{
			title: $title,
			description: $desc,
			color: 5814783,
			fields: [
				{name: "GitHub", value: $gh, inline: false},
				{name: "Modrinth", value: $mr, inline: true},
				{name: "CurseForge", value: $cf, inline: true}
			]
		}],
		allowed_mentions: {parse: []}
	}')"

if [[ "${DRY_RUN}" == "true" ]]; then
	echo "ℹ  [dry-run] Discord payload (webhook no enviado):" >&2
	echo "${payload}" | jq .
	exit 0
fi

tmp_resp="$(mktemp)"
http_code="$(curl -sS -o "${tmp_resp}" -w "%{http_code}" \
	-X POST "${DISCORD_WEBHOOK_URL}" \
	-H "Content-Type: application/json" \
	--data-binary "${payload}" || true)"
rm -f "${tmp_resp}"

if [[ ! "${http_code}" =~ ^2 ]]; then
	echo "✖  Discord webhook falló (HTTP ${http_code})" >&2
	exit 1
fi

echo "✔  Discord: notificación de release ${TAG} enviada" >&2
