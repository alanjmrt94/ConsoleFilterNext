#!/usr/bin/env bash
# Verificación runtime de correcciones audit 1–6 (debug session 0eaa80).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="${ROOT}/.cursor/debug-0eaa80.log"
mkdir -p "${ROOT}/.cursor"

dbg() {
	local hyp="$1" loc="$2" msg="$3" data="$4"
	# #region agent log
	printf '%s\n' "{\"sessionId\":\"0eaa80\",\"runId\":\"audit-verify\",\"hypothesisId\":\"${hyp}\",\"location\":\"${loc}\",\"message\":\"${msg}\",\"data\":${data},\"timestamp\":$(date +%s%3N)}" >>"${LOG}"
	# #endregion
}

fail=0
PROJECT_ROOT="${ROOT}"

# --- H1: Java tags por MC ---
# shellcheck source=/dev/null
source <(sed -n '/^publish_curseforge_java_versions()/,/^}/p' "${ROOT}/scripts/publish-release.sh")
j120="$(publish_curseforge_java_versions '1.20.1' | paste -sd, -)"
j261="$(publish_curseforge_java_versions '26.1' | paste -sd, -)"
j262="$(publish_curseforge_java_versions '26.2' | paste -sd, -)"
j189="$(publish_curseforge_java_versions '1.8.9' | paste -sd, -)"
j1122="$(publish_curseforge_java_versions '1.12.2' | paste -sd, -)"
j192="$(publish_curseforge_java_versions '1.19.2' | paste -sd, -)"
dbg H1 scripts/publish-release.sh:publish_curseforge_java_versions "java versions by MC" \
	"{\"mc120\":\"${j120}\",\"mc261\":\"${j261}\",\"mc262\":\"${j262}\",\"mc189\":\"${j189}\",\"mc1122\":\"${j1122}\",\"mc192\":\"${j192}\"}"
if [[ "${j261}" != "Java 25" || "${j262}" != "Java 25" ]]; then
	echo "FAIL H1: expected Java 25 for 26.x, got 26.1=${j261} 26.2=${j262}"
	fail=1
elif [[ "${j120}" != "Java 17,Java 21" ]]; then
	echo "FAIL H1: 1.20.1 debe ser Java 17,Java 21 (got ${j120})"
	fail=1
elif [[ "${j189}" != "Java 8" || "${j1122}" != "Java 8" ]]; then
	echo "FAIL H1: 1.8.9/1.12.2 deben ser Java 8 (got 1.8.9=${j189} 1.12.2=${j1122})"
	fail=1
elif [[ "${j192}" != "Java 17" ]]; then
	echo "FAIL H1: 1.19.2 debe ser Java 17 (got ${j192})"
	fail=1
else
	echo "OK H1: 26.x → Java 25; 1.20.1 → ${j120}; Java 8/17 en líneas legacy"
fi

# --- H2: release.yml exige COUNT==EXPECTED ---
if rg -q 'test "\$\{COUNT\}" -eq "\$\{EXPECTED\}"' "${ROOT}/.github/workflows/release.yml" \
	&& rg -q 'stage_one' "${ROOT}/.github/workflows/release.yml" \
	&& ! rg -q 'cp .* \|\| true' "${ROOT}/.github/workflows/release.yml"; then
	dbg H2 .github/workflows/release.yml "strict jar staging" '{"strict":true,"expectedEq":true}'
	echo "OK H2: release.yml exige JARs esperados"
else
	dbg H2 .github/workflows/release.yml "strict jar staging" '{"strict":false}'
	echo "FAIL H2: release.yml aún laxo"
	fail=1
fi

# --- H3: Fabric gradle.properties sin BMCL hardcode ---
if rg -q 'loom_libraries_base=https://bmclapi' "${ROOT}/platforms/26.1/fabric/gradle.properties" "${ROOT}/platforms/26.2/fabric/gradle.properties" 2>/dev/null; then
	dbg H3 "platforms/26.*/fabric/gradle.properties" "BMCL hardcode" '{"hardcoded":true}'
	echo "FAIL H3: BMCL aún hardcodeado en fabric gradle.properties"
	fail=1
else
	dbg H3 "platforms/26.*/fabric/gradle.properties" "BMCL hardcode" '{"hardcoded":false}'
	echo "OK H3: fabric gradle.properties sin BMCL fijo"
fi
if ! rg -q "useBmclMirror" "${ROOT}/platforms/26.1/fabric/build.gradle" || ! rg -q "useBmclMirror" "${ROOT}/platforms/26.2/fabric/build.gradle"; then
	echo "FAIL H3: build.gradle Fabric sin gate useBmclMirror"
	fail=1
fi

# --- H4: NeoForge BMCL rewrite gated ---
for f in platforms/26.1/neoforge/build.gradle platforms/26.2/neoforge/build.gradle; do
	if rg -n 'libraries.minecraft.net' "${ROOT}/${f}" | rg -q 'useBmclMirror|bmclapi'; then
		# Must be inside if (useBmclMirror)
		if awk '/def useBmclMirror/{g=1} g && /libraries.minecraft.net/{found=1} END{exit !found}' "${ROOT}/${f}"; then
			dbg H4 "${f}" "BMCL rewrite gated" '{"gated":true}'
			echo "OK H4: ${f} BMCL gated"
		else
			dbg H4 "${f}" "BMCL rewrite gated" '{"gated":false}'
			echo "FAIL H4: ${f} BMCL no gated"
			fail=1
		fi
	else
		echo "FAIL H4: ${f} sin rewrite BMCL esperado"
		fail=1
	fi
done

# --- H5: logoFile + pack_format ---
for pair in 'platforms/26.1/neoforge:84' 'platforms/26.2/neoforge:88'; do
	dir="${pair%%:*}"
	fmt="${pair##*:}"
	toml="${ROOT}/${dir}/src/main/resources/META-INF/neoforge.mods.toml"
	meta="${ROOT}/${dir}/src/main/resources/pack.mcmeta"
	has_logo=false
	rg -q 'logoFile="icon.png"' "${toml}" && has_logo=true
	got_fmt="$(python3 -c "import json; print(json.load(open('${meta}'))['pack']['pack_format'])")"
	dbg H5 "${dir}" "neoforge meta" "{\"logoFile\":${has_logo},\"pack_format\":${got_fmt},\"expected\":${fmt}}"
	if [[ "${has_logo}" != "true" || "${got_fmt}" != "${fmt}" ]]; then
		echo "FAIL H5: ${dir} logo=${has_logo} pack_format=${got_fmt} (want ${fmt})"
		fail=1
	else
		echo "OK H5: ${dir} logoFile + pack_format=${fmt}"
	fi
done

# --- H6: docs mention platforms layout / 26.x smoke ---
if rg -q 'platforms/' "${ROOT}/MIGRATION.md" "${ROOT}/README.md" \
	&& rg -q 'platforms/26.1/fabric|fabric-26.1' "${ROOT}/README.md"; then
	dbg H6 docs "multi-mc docs" '{"updated":true}'
	echo "OK H6: docs actualizados"
else
	dbg H6 docs "multi-mc docs" '{"updated":false}'
	echo "FAIL H6: docs incompletos"
	fail=1
fi

# Assets java_versions include 25
for f in assets/curseforge.json assets/modrinth.json; do
	if jq -e '.java_versions | index("Java 25")' "${ROOT}/${f}" >/dev/null; then
		echo "OK assets: ${f} incluye Java 25"
	else
		echo "FAIL assets: ${f} sin Java 25"
		fail=1
	fi
done

exit "${fail}"
