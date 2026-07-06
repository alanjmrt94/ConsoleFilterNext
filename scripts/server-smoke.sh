#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Primer arranque en CI (Gradle userdev + assets) suele tardar varios minutos.
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-420}"

mkdir -p run
cat > run/eula.txt <<'EOF'
# Auto-generated for CI smoke test
eula=true
EOF

LOG_FILE="$(mktemp)"
echo "Server log: $LOG_FILE"
echo "Smoke timeout: ${SMOKE_TIMEOUT_SECONDS}s"

set +e
timeout --signal=INT "${SMOKE_TIMEOUT_SECONDS}" ./gradlew runServer --no-daemon >"$LOG_FILE" 2>&1
EXIT_CODE=$?
set -e

smoke_passed() {
	grep -q 'Done (' "$LOG_FILE" \
		|| grep -q 'For help, type "help"' "$LOG_FILE" \
		|| grep -qi 'Forge mod loading has completed' "$LOG_FILE" \
		|| grep -qi 'consolefilternext' "$LOG_FILE" \
		|| grep -qi 'console filter' "$LOG_FILE"
}

if smoke_passed; then
	echo "Dedicated server smoke test passed."
	exit 0
fi

echo "Dedicated server smoke test failed (exit ${EXIT_CODE})."
if [[ "${EXIT_CODE}" -eq 124 ]]; then
	echo "Hint: runServer exceeded ${SMOKE_TIMEOUT_SECONDS}s (CI cold start). Increase SMOKE_TIMEOUT_SECONDS or enable Gradle cache."
fi
tail -n 80 "$LOG_FILE" || true
exit 1
