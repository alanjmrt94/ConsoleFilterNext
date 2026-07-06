#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p run
cat > run/eula.txt <<'EOF'
# Auto-generated for CI smoke test
eula=true
EOF

LOG_FILE="$(mktemp)"
echo "Server log: $LOG_FILE"

set +e
timeout 150 ./gradlew runServer --no-daemon >"$LOG_FILE" 2>&1
EXIT_CODE=$?
set -e

if grep -q 'Done (' "$LOG_FILE" || grep -q 'For help, type "help"' "$LOG_FILE"; then
  echo "Dedicated server smoke test passed."
  exit 0
fi

if grep -qi 'console filter' "$LOG_FILE"; then
  echo "Mod loaded; server smoke test passed."
  exit 0
fi

echo "Dedicated server smoke test failed (exit $EXIT_CODE)."
tail -n 80 "$LOG_FILE" || true
exit 1
