#!/usr/bin/env bash
# Falla si las copias de platforms/{mc}/client se desincronizan del canónico.
# 1.20.1 tiene UI de 1.20.1 (renderBackground de 1 arg).
# 1.20.2–1.20.6 deben coincidir con 1.21.1 (misma API de Screen).
# 26.1 y 26.2 no se comparan entre sí: 26.2 usa minecraft.gui.setScreen().
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

fail=0

compare_group() {
	local canonical="$1"
	shift
	local other
	if [[ ! -d "${canonical}/src" ]]; then
		echo "[error] Canónico ausente: ${canonical}" >&2
		return 1
	fi
	for other in "$@"; do
		if [[ ! -d "${other}/src" ]]; then
			echo "[error] Cliente ausente: ${other}" >&2
			fail=1
			continue
		fi
		if ! diff -rq "${canonical}/src" "${other}/src" >/dev/null; then
			echo "[error] Drift de UI: ${other} ≠ ${canonical}" >&2
			diff -rq "${canonical}/src" "${other}/src" >&2 || true
			fail=1
		else
			echo "[ok] ${other} = ${canonical}"
		fi
	done
}

compare_group platforms/1.21.1/client \
	platforms/1.20.2/client \
	platforms/1.20.3/client \
	platforms/1.20.4/client \
	platforms/1.20.5/client \
	platforms/1.20.6/client \
	platforms/1.21.2/client \
	platforms/1.21.3/client \
	platforms/1.21.4/client \
	platforms/1.21.5/client \
	platforms/1.21.6/client \
	platforms/1.21.7/client \
	platforms/1.21.8/client \
	platforms/1.21.9/client \
	platforms/1.21.10/client \
	platforms/1.21.11/client

if [[ "${fail}" -ne 0 ]]; then
	echo "[error] Copiá el client canónico o unificá el cambio en todo el grupo." >&2
	exit 1
fi
echo "[ok] Sin drift de client/ entre grupos canónicos."
