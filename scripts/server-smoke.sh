#!/usr/bin/env bash
# Smoke test de servidor dedicado — Forge / Fabric / NeoForge.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOADER="${1:-forge}"
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-420}"

usage() {
	echo "Uso: $0 [forge|fabric|neoforge]"
	exit 1
}

case "${LOADER}" in
	forge|fabric|neoforge) ;;
	-h|--help) usage ;;
	*) echo "Loader desconocido: ${LOADER}"; usage ;;
esac

RUN_DIR="run"
GRADLE_CMD=(./gradlew :forge:runServer --no-daemon)
LOG_HINTS=('Done (' 'For help, type "help"' 'Forge mod loading has completed' 'consolefilternext' 'console filter')

case "${LOADER}" in
	fabric)
		RUN_DIR="run-fabric"
		GRADLE_CMD=(./gradlew runServer --no-daemon)
		LOG_HINTS=('Done (' 'For help, type "help"' 'FabricLoader' 'consolefilternext' 'console filter')
		;;
	neoforge)
		RUN_DIR="run-neoforge"
		GRADLE_CMD=(./gradlew runServer --no-daemon)
		LOG_HINTS=('Done (' 'For help, type "help"' 'mod loading has completed' 'consolefilternext' 'console filter' 'NeoForge')
		;;
esac

mkdir -p "${RUN_DIR}"
cat > "${RUN_DIR}/eula.txt" <<'EOF'
# Auto-generated for CI smoke test
eula=true
EOF

LOG_FILE="$(mktemp)"
echo "Loader: ${LOADER}"
echo "Server log: ${LOG_FILE}"
echo "Smoke timeout: ${SMOKE_TIMEOUT_SECONDS}s"

set +e
if [[ "${LOADER}" == "forge" ]]; then
	timeout --signal=INT "${SMOKE_TIMEOUT_SECONDS}" "${GRADLE_CMD[@]}" >"${LOG_FILE}" 2>&1
	EXIT_CODE=$?
elif [[ "${LOADER}" == "fabric" ]]; then
	timeout --signal=INT "${SMOKE_TIMEOUT_SECONDS}" bash -lc "cd '${ROOT}/fabric' && ./gradlew runServer --no-daemon" >"${LOG_FILE}" 2>&1
	EXIT_CODE=$?
else
	timeout --signal=INT "${SMOKE_TIMEOUT_SECONDS}" bash -lc "cd '${ROOT}/neoforge' && ./gradlew runServer --no-daemon" >"${LOG_FILE}" 2>&1
	EXIT_CODE=$?
fi
set -e

smoke_passed() {
	local hint
	for hint in "${LOG_HINTS[@]}"; do
		if grep -qiF "${hint}" "${LOG_FILE}"; then
			return 0
		fi
	done
	return 1
}

if smoke_passed; then
	echo "Dedicated server smoke test passed (${LOADER})."
	exit 0
fi

echo "Dedicated server smoke test failed (${LOADER}, exit ${EXIT_CODE})."
if [[ "${EXIT_CODE}" -eq 124 ]]; then
	echo "Hint: runServer exceeded ${SMOKE_TIMEOUT_SECONDS}s (CI cold start). Increase SMOKE_TIMEOUT_SECONDS or enable Gradle cache."
fi
tail -n 80 "${LOG_FILE}" || true
exit 1
