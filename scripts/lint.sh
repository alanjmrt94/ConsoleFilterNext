#!/usr/bin/env bash
# Lint / autofix Java del monorepo (Spotless + compilación con -Xlint / -Werror).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

MODE="${1:-check}"

usage() {
	cat <<'EOF'
Uso: lint.sh [check|fix|compile|ci]

  check    Spotless check (imports no usados, whitespace) — default
  fix      Autofix Spotless
  compile  Compila common+forge con -Xlint:all -Werror
  ci       Igual que CI: Spotless + compile -Werror + --warning-mode fail

Ejemplos:
  ./scripts/lint.sh
  ./scripts/lint.sh fix
  ./scripts/lint.sh ci
EOF
}

run_ci_lint() {
	# Limpia para no reusar class files compilados sin -Werror.
	./gradlew \
		:common:clean :forge:clean \
		lintCi \
		-PfailOnWarnings=true \
		--warning-mode fail \
		--no-daemon
	echo "[ok] Lint CI OK (Spotless + -Xlint/-Werror + sin deprecaciones Gradle)"
}

case "${MODE}" in
	-h|--help|help) usage; exit 0 ;;
	check)
		./gradlew lintCheck --warning-mode fail --no-daemon
		;;
	fix|apply|autofix)
		./gradlew lintFix --no-daemon
		echo "[ok] Spotless aplicado. Revisá el diff antes de commitear."
		;;
	compile)
		./gradlew :common:clean :forge:clean :common:compileJava :forge:compileJava \
			-PfailOnWarnings=true --warning-mode fail --no-daemon
		echo "[ok] Compilación common+forge con -Xlint:all -Werror"
		;;
	ci)
		run_ci_lint
		;;
	*)
		echo "[error] Modo desconocido: ${MODE}" >&2
		usage
		exit 1
		;;
esac
