#!/usr/bin/env bash
# Reintenta Gradle en una celda platforms/{mc}/{loader} ante 502/Maven transitorio.
set -u

if [[ $# -lt 2 ]]; then
	echo "Uso: $0 <project-dir> [gradle args...]" >&2
	exit 2
fi

DIR="$1"
shift
ATTEMPTS="${CI_GRADLE_RETRIES:-3}"
SLEEP_SEC="${CI_GRADLE_RETRY_SLEEP:-20}"

if [[ ! -f "${DIR}/gradlew" ]]; then
	echo "Falta ${DIR}/gradlew" >&2
	exit 1
fi
chmod +x "${DIR}/gradlew"

attempt=1
while [[ "${attempt}" -le "${ATTEMPTS}" ]]; do
	(cd "${DIR}" && ./gradlew "$@")
	status=$?
	if [[ "${status}" -eq 0 ]]; then
		exit 0
	fi
	if [[ "${attempt}" -eq "${ATTEMPTS}" ]]; then
		echo "Gradle en ${DIR} falló tras ${ATTEMPTS} intento(s) (exit ${status})." >&2
		exit "${status}"
	fi
	echo "Gradle en ${DIR} intento ${attempt} falló (exit ${status}); reintento por 502/Maven transitorio."
	sleep "${SLEEP_SEC}"
	attempt=$((attempt + 1))
done
