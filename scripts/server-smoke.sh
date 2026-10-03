#!/usr/bin/env bash
# Smoke test de servidor dedicado — Forge / Fabric / NeoForge.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOADER="${1:-forge}"
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-300}"

usage() {
	echo "Uso: $0 [forge|fabric|neoforge|forge-1.21|fabric-1.21|neoforge-1.21|forge-1.16.5|fabric-1.16.5|forge-1.16.1|fabric-1.16.1|forge-1.12.2|fabric-1.12.2|forge-1.8.9|fabric-1.8.9|fabric-26.1|neoforge-26.1|forge-26.1|fabric-26.2|neoforge-26.2|forge-26.2|{forge,fabric,neoforge}-1.20.{2-6}]"
	exit 1
}

if [[ "${LOADER}" =~ ^(forge|fabric|neoforge)-1\.20\.[2-6]$ ]]; then
	:
else
	case "${LOADER}" in
		forge|fabric|neoforge|forge-1.21|fabric-1.21|neoforge-1.21|forge-1.16.5|fabric-1.16.5|forge-1.16.1|fabric-1.16.1|forge-1.12.2|fabric-1.12.2|forge-1.8.9|fabric-1.8.9|fabric-26.1|neoforge-26.1|forge-26.1|fabric-26.2|neoforge-26.2|forge-26.2) ;;
		-h|--help) usage ;;
		*) echo "Loader desconocido: ${LOADER}"; usage ;;
	esac
fi

# Alias cortos → (RUN_DIR, PROJECT_DIR). forge 1.20.1 usa el Gradle raíz.
RUN_DIR="runs/1.20.1/forge"
PROJECT_DIR=""
LOG_HINTS=('Done (' 'For help, type "help"' 'Forge mod loading has completed' 'consolefilternext' 'console filter')
REQUIRE_ALL_HINTS=0

if [[ "${LOADER}" =~ ^(forge|fabric|neoforge)-(1\.20\.[2-6])$ ]]; then
	_loader="${BASH_REMATCH[1]}"
	_mc="${BASH_REMATCH[2]}"
	RUN_DIR="runs/${_mc}/${_loader}"
	PROJECT_DIR="platforms/${_mc}/${_loader}"
	if [[ "${_loader}" == "fabric" ]]; then
		LOG_HINTS=('Done (' 'For help, type "help"' 'FabricLoader' 'consolefilternext' 'console filter')
	else
		LOG_HINTS=('Done (' 'message(s) to be filtered')
		REQUIRE_ALL_HINTS=1
	fi
else
case "${LOADER}" in
	fabric)
		RUN_DIR="runs/1.20.1/fabric"
		PROJECT_DIR="platforms/1.20.1/fabric"
		LOG_HINTS=('Done (' 'For help, type "help"' 'FabricLoader' 'consolefilternext' 'console filter')
		;;
	neoforge)
		RUN_DIR="runs/1.20.1/neoforge"
		PROJECT_DIR="platforms/1.20.1/neoforge"
		LOG_HINTS=('Done (' 'For help, type "help"' 'mod loading has completed' 'consolefilternext' 'console filter' 'NeoForge')
		;;
	forge-1.21)
		RUN_DIR="runs/1.21.1/forge"
		PROJECT_DIR="platforms/1.21.1/forge"
		LOG_HINTS=('Done (' 'message(s) to be filtered')
		REQUIRE_ALL_HINTS=1
		;;
	fabric-1.21)
		RUN_DIR="runs/1.21.1/fabric"
		PROJECT_DIR="platforms/1.21.1/fabric"
		LOG_HINTS=('Done (' 'For help, type "help"' 'FabricLoader' 'consolefilternext' 'console filter')
		;;
	neoforge-1.21)
		RUN_DIR="runs/1.21.1/neoforge"
		PROJECT_DIR="platforms/1.21.1/neoforge"
		LOG_HINTS=('Done (' 'message(s) to be filtered')
		REQUIRE_ALL_HINTS=1
		;;
	forge-1.16.5)
		RUN_DIR="runs/1.16.5/forge"
		PROJECT_DIR="platforms/1.16.5/forge"
		LOG_HINTS=('Done (' 'message(s) to be filtered')
		REQUIRE_ALL_HINTS=1
		;;
	fabric-1.16.5)
		RUN_DIR="runs/1.16.5/fabric"
		PROJECT_DIR="platforms/1.16.5/fabric"
		LOG_HINTS=('Done (' 'message(s) to be filtered')
		REQUIRE_ALL_HINTS=1
		;;
	forge-1.16.1)
		RUN_DIR="runs/1.16.1/forge"
		PROJECT_DIR="platforms/1.16.1/forge"
		LOG_HINTS=('Done (' 'message(s) to be filtered')
		REQUIRE_ALL_HINTS=1
		;;
	fabric-1.16.1)
		RUN_DIR="runs/1.16.1/fabric"
		PROJECT_DIR="platforms/1.16.1/fabric"
		LOG_HINTS=('Done (' 'message(s) to be filtered')
		REQUIRE_ALL_HINTS=1
		;;
	forge-1.12.2)
		RUN_DIR="runs/1.12.2/forge"
		PROJECT_DIR="platforms/1.12.2/forge"
		LOG_HINTS=('Done (' 'message(s) to be filtered')
		REQUIRE_ALL_HINTS=1
		;;
	fabric-1.12.2)
		RUN_DIR="runs/1.12.2/fabric"
		PROJECT_DIR="platforms/1.12.2/fabric"
		LOG_HINTS=('Done (' 'message(s) to be filtered' 'FabricLoader')
		REQUIRE_ALL_HINTS=1
		;;
	forge-1.8.9)
		RUN_DIR="runs/1.8.9/forge"
		PROJECT_DIR="platforms/1.8.9/forge"
		LOG_HINTS=('Done (' 'message(s) to be filtered')
		REQUIRE_ALL_HINTS=1
		;;
	fabric-1.8.9)
		RUN_DIR="runs/1.8.9/fabric"
		PROJECT_DIR="platforms/1.8.9/fabric"
		LOG_HINTS=('Done (' 'message(s) to be filtered' 'FabricLoader')
		REQUIRE_ALL_HINTS=1
		;;
	fabric-26.1)
		RUN_DIR="runs/26.1/fabric"
		PROJECT_DIR="platforms/26.1/fabric"
		LOG_HINTS=('Done (' 'For help, type "help"' 'FabricLoader' 'consolefilternext' 'console filter')
		;;
	neoforge-26.1)
		RUN_DIR="runs/26.1/neoforge"
		PROJECT_DIR="platforms/26.1/neoforge"
		LOG_HINTS=('Done (' 'For help, type "help"' 'mod loading has completed' 'consolefilternext' 'console filter' 'NeoForge')
		;;
	forge-26.1)
		RUN_DIR="runs/26.1/forge"
		PROJECT_DIR="platforms/26.1/forge"
		LOG_HINTS=('Done (' 'For help, type "help"' 'Forge mod loading has completed' 'consolefilternext' 'console filter')
		;;
	fabric-26.2)
		RUN_DIR="runs/26.2/fabric"
		PROJECT_DIR="platforms/26.2/fabric"
		LOG_HINTS=('Done (' 'For help, type "help"' 'FabricLoader' 'consolefilternext' 'console filter')
		;;
	neoforge-26.2)
		RUN_DIR="runs/26.2/neoforge"
		PROJECT_DIR="platforms/26.2/neoforge"
		LOG_HINTS=('Done (' 'For help, type "help"' 'mod loading has completed' 'consolefilternext' 'console filter' 'NeoForge')
		;;
	forge-26.2)
		RUN_DIR="runs/26.2/forge"
		PROJECT_DIR="platforms/26.2/forge"
		LOG_HINTS=('Done (' 'For help, type "help"' 'Forge mod loading has completed' 'consolefilternext' 'console filter')
		;;
	forge)
		PROJECT_DIR=""
		;;
esac
fi

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
	timeout --signal=INT "${SMOKE_TIMEOUT_SECONDS}" ./gradlew :forge:runServer --no-daemon >"${LOG_FILE}" 2>&1
	EXIT_CODE=$?
else
	timeout --signal=INT "${SMOKE_TIMEOUT_SECONDS}" bash -c "cd '${ROOT}/${PROJECT_DIR}' && ./gradlew runServer --no-daemon" >"${LOG_FILE}" 2>&1
	EXIT_CODE=$?
fi
set -e

smoke_passed() {
	local hint
	if [[ "${REQUIRE_ALL_HINTS}" -eq 1 ]]; then
		for hint in "${LOG_HINTS[@]}"; do
			if ! grep -qiF "${hint}" "${LOG_FILE}"; then
				return 1
			fi
		done
		return 0
	fi
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
