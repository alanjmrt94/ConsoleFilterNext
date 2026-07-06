#!/usr/bin/env bash
# Console Filter Next — menú interactivo de entorno de desarrollo
# Verifica y configura Java, Gradle, Forge, Minecraft y herramientas relacionadas.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOCAL_CONFIG="${SCRIPT_DIR}/.release.local"
GRADLE_PROPERTIES="${PROJECT_ROOT}/gradle.properties"
GRADLE_WRAPPER="${PROJECT_ROOT}/gradle/wrapper/gradle-wrapper.properties"
BUILD_GRADLE="${PROJECT_ROOT}/build.gradle"

# shellcheck source=scripts/publish-release.sh disable=SC1091
source "${SCRIPT_DIR}/publish-release.sh"

# true cuando se invoca con argumentos (verify, build, etc.) o sin TTY
INTERACTIVE=true
if [[ ! -t 0 ]] || [[ -n "${1:-}" ]]; then
  INTERACTIVE=false
fi

# Colores (si el terminal lo soporta)
if [[ -t 1 ]] && command -v tput &>/dev/null; then
  BOLD="$(tput bold)"
  DIM="$(tput dim)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  RED="$(tput setaf 1)"
  CYAN="$(tput setaf 6)"
  RESET="$(tput sgr0)"
else
  BOLD="" DIM="" GREEN="" YELLOW="" RED="" CYAN="" RESET=""
fi

# ─── Utilidades ───────────────────────────────────────────────────────────────

pause() {
  if [[ "${INTERACTIVE}" == "true" ]]; then
    echo
    read -r -p "Presiona Enter para continuar..."
  fi
}

screen_clear() {
  if [[ "${INTERACTIVE}" == "true" ]]; then
    clear
  fi
}

log_info()    { echo -e "${CYAN}ℹ${RESET}  $*"; }
log_ok()      { echo -e "${GREEN}✔${RESET}  $*"; }
log_warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
log_error()   { echo -e "${RED}✖${RESET}  $*"; }

require_file() {
  if [[ ! -f "$1" ]]; then
    log_error "No se encontró: $1"
    return 1
  fi
}

load_local_config() {
  if [[ -f "${LOCAL_CONFIG}" ]]; then
    # shellcheck source=/dev/null
    source "${LOCAL_CONFIG}"
  fi
}

save_java_home() {
  local java_home="$1"
  cat > "${LOCAL_CONFIG}" <<EOF
# Configuración local del entorno de desarrollo (no versionar)
# Generado por scripts/release.sh

export JAVA_HOME="${java_home}"
export PATH="\${JAVA_HOME}/bin:\${PATH}"
EOF
  log_ok "JAVA_HOME guardado en ${LOCAL_CONFIG}"
}

get_prop() {
  local key="$1"
  local file="$2"
  grep -E "^${key}=" "${file}" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r'
}

set_prop() {
  local key="$1"
  local value="$2"
  local file="$3"
  if grep -qE "^${key}=" "${file}"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "${file}"
  else
    echo "${key}=${value}" >> "${file}"
  fi
}

get_gradle_version() {
  if [[ -f "${GRADLE_WRAPPER}" ]]; then
    grep 'distributionUrl' "${GRADLE_WRAPPER}" | sed -E 's/.*gradle-([0-9.]+)-bin\.zip.*/\1/'
  else
    echo "desconocido"
  fi
}

get_forgegradle_version() {
  if [[ -f "${BUILD_GRADLE}" ]]; then
    grep "net.minecraftforge.gradle" "${BUILD_GRADLE}" | sed -E "s/.*version ['\"]([^'\"]+)['\"].*/\1/" | head -1
  else
    echo "desconocido"
  fi
}

get_java_toolchain() {
  if [[ -f "${BUILD_GRADLE}" ]]; then
    grep 'JavaLanguageVersion.of' "${BUILD_GRADLE}" | sed -E 's/.*JavaLanguageVersion\.of\(([0-9]+)\).*/\1/' | head -1
  else
    echo "desconocido"
  fi
}

get_java_release() {
  if [[ -f "${BUILD_GRADLE}" ]]; then
    grep 'options.release' "${BUILD_GRADLE}" | sed -E 's/.*options\.release = ([0-9]+).*/\1/' | head -1
  else
    echo "desconocido"
  fi
}

java_major_version() {
  local java_bin="${1:-java}"
  "${java_bin}" -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/'
}

# Launcher JVM aceptado para ejecutar Gradle (no confundir con bytecode del mod → siempre 17)
is_recommended_launcher_java() { [[ "$(java_major_version "${1:-java}")" == "17" ]]; }
is_acceptable_launcher_java() {
  local major
  major="$(java_major_version "${1:-java}")"
  [[ "${major}" == "17" || "${major}" == "21" ]]
}

find_installed_jdks() {
  local paths=(
    "/usr/lib/jvm"
    "/usr/local/lib/jvm"
    "${HOME}/.sdkman/candidates/java"
    "${HOME}/.jabba/jdk"
  )
  for base in "${paths[@]}"; do
    [[ -d "${base}" ]] || continue
    for jdk in "${base}"/*; do
      [[ -d "${jdk}" && -x "${jdk}/bin/java" ]] && echo "${jdk}"
    done
  done | sort -u
}

gradle_cmd() {
  load_local_config
  (cd "${PROJECT_ROOT}" && ./gradlew "$@")
}

# JDK compatible para ejecutar Gradle (launcher JVM), no el bytecode del mod
pick_gradle_launcher_java() {
  local gradle_ver="${1:-$(get_gradle_version)}"
  local jdk preferred=()

  while IFS= read -r jdk; do
    [[ -n "${jdk}" ]] && preferred+=("${jdk}")
  done < <(find_installed_jdks)

  # Preferir 17, luego 21
  for jdk in "${preferred[@]}"; do
    if [[ "${jdk}" == *"java-17"* || "${jdk}" == *"jdk-17"* || "${jdk}" == *"openjdk-17"* ]]; then
      echo "${jdk}"
      return 0
    fi
  done
  for jdk in "${preferred[@]}"; do
    if [[ "${jdk}" == *"java-21"* || "${jdk}" == *"jdk-21"* || "${jdk}" == *"openjdk-21"* ]]; then
      echo "${jdk}"
      return 0
    fi
  done

  # Java 25 solo si Gradle es reciente
  if [[ "$(printf '%s\n' "${gradle_ver}" "8.14.4" | sort -V | head -1)" != "${gradle_ver}" ]]; then
    for jdk in "${preferred[@]}"; do
      if [[ "${jdk}" == *"java-25"* || "${jdk}" == *"jdk-25"* ]]; then
        echo "${jdk}"
        return 0
      fi
    done
  fi

  return 1
}

run_gradlew_with_bootstrap() {
  local args=("$@")
  load_local_config

  if (cd "${PROJECT_ROOT}" && ./gradlew "${args[@]}" 2>/dev/null); then
    return 0
  fi

  local launcher
  launcher="$(pick_gradle_launcher_java "$(get_gradle_version)" || true)"
  if [[ -n "${launcher}" ]]; then
    log_warn "gradlew falló con Java actual; reintentando con ${launcher}"
    (cd "${PROJECT_ROOT}" && JAVA_HOME="${launcher}" PATH="${launcher}/bin:${PATH}" ./gradlew "${args[@]}")
    return $?
  fi

  return 1
}

update_gradle_wrapper() {
  local new="$1"
  local current
  current="$(get_gradle_version)"

  if [[ "${new}" == "${current}" ]]; then
    log_info "Gradle Wrapper ya está en ${current}"
    return 0
  fi

  # Intento 1: gradlew con JDK launcher adecuado
  if run_gradlew_with_bootstrap wrapper --gradle-version="${new}"; then
    log_ok "Gradle Wrapper actualizado a ${new} vía gradlew"
    return 0
  fi

  # Intento 2: bootstrap manual (Gradle viejo + Java nuevo = error circular)
  log_warn "gradlew no pudo actualizarse; aplicando bootstrap manual en gradle-wrapper.properties"
  sed -i "s|distributionUrl=.*|distributionUrl=https\\\\://services.gradle.org/distributions/gradle-${new}-bin.zip|" "${GRADLE_WRAPPER}"

  local launcher
  launcher="$(pick_gradle_launcher_java "${new}" || true)"
  if [[ -n "${launcher}" ]]; then
    if (cd "${PROJECT_ROOT}" && JAVA_HOME="${launcher}" PATH="${launcher}/bin:${PATH}" ./gradlew wrapper --gradle-version="${new}"); then
      log_ok "Gradle Wrapper actualizado a ${new} tras bootstrap manual"
      save_java_home "${launcher}"
      return 0
    fi
  fi

  log_ok "distributionUrl → gradle-${new}-bin.zip (descarga pendiente al próximo ./gradlew)"
  log_info "Configura JAVA_HOME con Java 17 o 21: ./scripts/release.sh java"
  return 1
}

detect_platform() {
  local os
  os="$(uname -s 2>/dev/null || echo unknown)"
  case "${os}" in
    Darwin) echo "macos" ;;
    Linux)
      if [[ -f /etc/debian_version ]] || command -v apt-get &>/dev/null; then
        echo "debian"
      elif [[ -f /etc/fedora-release ]] || command -v dnf &>/dev/null; then
        echo "fedora"
      elif [[ -f /etc/arch-release ]] || command -v pacman &>/dev/null; then
        echo "arch"
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

has_jdk_version() {
  local want="$1"
  while IFS= read -r jdk; do
    [[ -z "${jdk}" ]] && continue
    if [[ "${jdk}" == *"java-${want}"* || "${jdk}" == *"jdk-${want}"* || "${jdk}" == *"-${want}-"* ]]; then
      return 0
    fi
    local major
    major="$("${jdk}/bin/java" -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/')"
    [[ "${major}" == "${want}" ]] && return 0
  done < <(find_installed_jdks)
  return 1
}

# Imprime bloques de comandos sugeridos (copiables)
print_cmd() {
  echo -e "  ${DIM}\$${RESET} $*"
}

show_java_install_commands() {
  local platform toolchain
  platform="$(detect_platform)"
  toolchain="$(get_java_toolchain)"

  echo -e "${BOLD}Java — instalar JDK ${toolchain}${RESET}"
  echo "────────────────────────────────────────"

  case "${platform}" in
    debian)
      print_cmd "sudo apt update"
      print_cmd "sudo apt install -y openjdk-${toolchain}-jdk"
      print_cmd "sudo update-alternatives --config java    # elegir Java ${toolchain}"
      ;;
    fedora)
      print_cmd "sudo dnf install -y java-${toolchain}-openjdk-devel"
      print_cmd "sudo alternatives --config java"
      ;;
    arch)
      print_cmd "sudo pacman -S jdk${toolchain}-openjdk"
      ;;
    macos)
      print_cmd "brew install openjdk@${toolchain}"
      print_cmd "sudo ln -sfn \$(brew --prefix)/opt/openjdk@${toolchain}/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-${toolchain}.jdk"
      ;;
    *)
      log_info "Instalador genérico no detectado; usa SDKMAN o descarga Temurin"
      ;;
  esac

  echo
  echo "  Alternativas multiplataforma:"
  print_cmd "curl -s \"https://get.sdkman.io\" | bash"
  print_cmd "source \"\$HOME/.sdkman/bin/sdkman-init.sh\""
  print_cmd "sdk install java ${toolchain}.0.13-tem"
  print_cmd "sdk use java ${toolchain}.0.13-tem"
  echo
  echo "  Temurin (Adoptium) — descarga manual:"
  print_cmd "xdg-open https://adoptium.net/temurin/releases/?version=${toolchain}"
  echo
  echo "  Configurar en este proyecto:"
  print_cmd "export JAVA_HOME=/usr/lib/jvm/java-${toolchain}-openjdk-amd64"
  print_cmd "export PATH=\"\${JAVA_HOME}/bin:\${PATH}\""
  print_cmd "./scripts/release.sh java"
  echo
}

show_java_switch_commands() {
  echo -e "${BOLD}Java — cambiar versión activa${RESET}"
  echo "────────────────────────────────────────"
  case "$(detect_platform)" in
    debian)
      print_cmd "sudo update-alternatives --config java"
      print_cmd "sudo update-alternatives --config javac"
      ;;
    fedora)
      print_cmd "sudo alternatives --config java"
      ;;
    macos)
      print_cmd "export JAVA_HOME=\$(/usr/libexec/java_home -v 17)"
      ;;
    *)
      print_cmd "export JAVA_HOME=/ruta/al/jdk"
      print_cmd "export PATH=\"\${JAVA_HOME}/bin:\${PATH}\""
      ;;
  esac
  print_cmd "java -version"
  print_cmd "./scripts/release.sh java"
  echo
}

show_gradle_update_commands() {
  local current recommended
  current="$(get_gradle_version)"
  recommended="8.14.3"

  echo -e "${BOLD}Gradle — actualizar Wrapper (${current} → ${recommended})${RESET}"
  echo "────────────────────────────────────────"
  echo "  Desde el proyecto (recomendado):"
  print_cmd "cd ${PROJECT_ROOT}"
  print_cmd "./gradlew wrapper --gradle-version=${recommended}"
  print_cmd "./gradlew --version"
  echo
  echo "  Si gradlew falla con Java 21/25, primero actualiza el wrapper manualmente:"
  print_cmd "sed -i 's|gradle-.*-bin|gradle-${recommended}-bin|' gradle/wrapper/gradle-wrapper.properties"
  print_cmd "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
  print_cmd "export PATH=\"\${JAVA_HOME}/bin:\${PATH}\""
  print_cmd "./gradlew wrapper --gradle-version=${recommended}"
  echo
  echo "  Instalar Gradle global (opcional, no necesario con wrapper):"
  case "$(detect_platform)" in
    debian) print_cmd "sudo apt install -y gradle" ;;
    fedora) print_cmd "sudo dnf install -y gradle" ;;
    arch)   print_cmd "sudo pacman -S gradle" ;;
    macos)  print_cmd "brew install gradle" ;;
  esac
  print_cmd "sdk install gradle ${recommended}"
  echo
  echo "  Desde este script:"
  print_cmd "./scripts/release.sh    # menú → 2 → 4 (Gradle) o 3 (perfil recomendado)"
  echo
}

show_forge_update_commands() {
  local mc forge current
  mc="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
  current="$(get_prop forge_version "${GRADLE_PROPERTIES}")"
  forge="47.4.10"

  echo -e "${BOLD}Forge — actualizar dependencia del mod (MC ${mc})${RESET}"
  echo "────────────────────────────────────────"
  echo "  Forge no se instala globalmente; se declara en gradle.properties."
  echo "  Versión actual: ${current} | Recomendada para ${mc}: ${forge}"
  echo
  echo "  Editar gradle.properties:"
  print_cmd "sed -i 's|^forge_version=.*|forge_version=${forge}|' gradle.properties"
  print_cmd "sed -i 's|^forge_version_range=.*|forge_version_range=[47,)|' gradle.properties"
  echo
  echo "  Refrescar dependencias y compilar:"
  print_cmd "cd ${PROJECT_ROOT}"
  print_cmd "./gradlew --refresh-dependencies clean build"
  echo
  echo "  Consultar versiones disponibles:"
  print_cmd "xdg-open https://files.minecraftforge.net/net/minecraftforge/forge/index_${mc}.html"
  print_cmd "curl -s https://maven.minecraftforge.net/net/minecraftforge/forge/maven-metadata.xml | head -20"
  echo
  echo "  Desde este script:"
  print_cmd "./scripts/release.sh    # menú → 2 → 2 (Forge) o 3 (perfil recomendado)"
  echo
}

show_forgegradle_update_commands() {
  local current
  current="$(get_forgegradle_version)"

  echo -e "${BOLD}ForgeGradle — actualizar plugin de build${RESET}"
  echo "────────────────────────────────────────"
  echo "  Versión actual: ${current} | Recomendada: 6.0.47"
  echo
  echo "  Editar build.gradle:"
  print_cmd "sed -i \"s|id 'net.minecraftforge.gradle' version '[^']*'|id 'net.minecraftforge.gradle' version '6.0.47'|\" build.gradle"
  echo
  echo "  Sincronizar proyecto:"
  print_cmd "cd ${PROJECT_ROOT}"
  print_cmd "./gradlew --refresh-dependencies"
  print_cmd "./gradlew build"
  echo
  echo "  Desde este script:"
  print_cmd "./scripts/release.sh    # menú → 2 → 5 (ForgeGradle)"
  echo
}

show_toolchain_refresh_commands() {
  echo -e "${BOLD}Proyecto — refrescar toolchain y dependencias${RESET}"
  echo "────────────────────────────────────────"
  print_cmd "cd ${PROJECT_ROOT}"
  print_cmd "./gradlew --stop"
  print_cmd "./gradlew --refresh-dependencies"
  print_cmd "./gradlew clean build"
  print_cmd "./gradlew runClient"
  echo
}

show_all_suggested_commands() {
  screen_clear
  echo -e "${BOLD}${CYAN}═══ Comandos sugeridos — instalar / actualizar ═══${RESET}"
  echo
  show_java_install_commands
  show_java_switch_commands
  show_gradle_update_commands
  show_forge_update_commands
  show_forgegradle_update_commands
  show_toolchain_refresh_commands
  pause
}

show_contextual_commands() {
  local gradle_ver forge_ver java_tc
  gradle_ver="$(get_gradle_version)"
  forge_ver="$(get_prop forge_version "${GRADLE_PROPERTIES}")"
  java_tc="$(get_java_toolchain)"

  echo -e "${BOLD}Comandos sugeridos${RESET}"
  echo "────────────────────────────────────────"

  if ! has_jdk_version "${java_tc}"; then
    if has_jdk_version "21"; then
      echo -e "  ${YELLOW}JDK ${java_tc} no instalado localmente${RESET} — OK con Java 21 como launcher:"
      print_cmd "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
      print_cmd "./scripts/release.sh java"
      echo "  (Gradle descarga JDK ${java_tc} para el toolchain; Java 21 launcher compila OK)"
      echo
    else
      echo -e "  ${YELLOW}Java ${java_tc}${RESET} — instalar:"
      case "$(detect_platform)" in
        debian) print_cmd "sudo apt install -y openjdk-${java_tc}-jdk" ;;
        fedora) print_cmd "sudo dnf install -y java-${java_tc}-openjdk-devel" ;;
        arch)   print_cmd "sudo pacman -S jdk${java_tc}-openjdk" ;;
        macos)  print_cmd "brew install openjdk@${java_tc}" ;;
        *)      print_cmd "sdk install java ${java_tc}.0.13-tem" ;;
      esac
      print_cmd "./scripts/release.sh java"
      echo
    fi
  fi

  if command -v java &>/dev/null && [[ "$(java_major_version java)" == "21" ]]; then
    echo -e "  ${YELLOW}Java 21 activo${RESET} — alternativa válida (recomendado: JDK 17):"
    print_cmd "# compilar con configuración actual"
    print_cmd "./gradlew build"
    echo
  fi

  if command -v java &>/dev/null; then
    local major
    major="$(java_major_version java)"
    if [[ "${major}" -ge 22 && "$(printf '%s\n' "${gradle_ver}" "8.14.3" | sort -V | head -1)" == "${gradle_ver}" ]]; then
      echo -e "  ${YELLOW}Launcher Java ${major} + Gradle ${gradle_ver}${RESET}:"
      print_cmd "./gradlew wrapper --gradle-version=8.14.3"
      print_cmd "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
      echo
    fi
  fi

  if [[ "$(printf '%s\n' "${gradle_ver}" "8.14.3" | sort -V | head -1)" == "${gradle_ver}" && "${gradle_ver}" != "8.14.3" ]]; then
    echo -e "  ${YELLOW}Gradle desactualizado (${gradle_ver})${RESET}:"
    print_cmd "./gradlew wrapper --gradle-version=8.14.3"
    echo
  fi

  if [[ "${forge_ver}" == "47.1.0" ]]; then
    echo -e "  ${YELLOW}Forge desactualizado (${forge_ver})${RESET}:"
    print_cmd "sed -i 's|^forge_version=.*|forge_version=47.4.10|' gradle.properties"
    print_cmd "./gradlew --refresh-dependencies clean build"
    echo
  fi

  echo "  Ver todos los comandos: menú → 8 o ./scripts/release.sh commands"
  echo
}


show_java_status() {
  echo -e "${BOLD}Java${RESET}"
  echo "────────────────────────────────────────"

  local active_java
  active_java="$(command -v java 2>/dev/null || echo 'no encontrado')"
  echo "  java en PATH : ${active_java}"
  if command -v java &>/dev/null; then
    echo "  versión      : $(java -version 2>&1 | head -1)"
    local major
    major="$(java_major_version java)"
    if is_recommended_launcher_java java; then
      log_ok "Java ${major} como launcher (recomendado para Forge 1.20.1)"
    elif [[ "${major}" == "21" ]]; then
      log_warn "Java 21 como launcher: alternativa válida — compila correctamente (recomendado oficial: JDK 17)"
    elif [[ "${major}" -ge 22 ]]; then
      log_warn "Java ${major} como launcher puede fallar con Gradle antiguo (usar JDK 17/21 o Gradle ≥ 8.14.3)"
    fi
  fi

  echo "  Bytecode mod : Java $(get_java_release) (fijo para MC 1.20.1, independiente del launcher)"

  echo "  JAVA_HOME    : ${JAVA_HOME:-<no definido>}"
  local toolchain release
  toolchain="$(get_java_toolchain)"
  release="$(get_java_release)"
  echo "  toolchain    : Java ${toolchain} (build.gradle)"
  echo "  release      : Java ${release} (bytecode del mod)"

  if [[ "${toolchain}" != "${release}" ]]; then
    log_warn "toolchain (${toolchain}) y release (${release}) no coinciden"
  fi

  echo
  echo "  JDKs detectados:"
  local found=0
  while IFS= read -r jdk; do
    [[ -z "${jdk}" ]] && continue
    found=1
    local ver mark=""
    ver="$("${jdk}/bin/java" -version 2>&1 | head -1)"
    [[ -n "${JAVA_HOME:-}" && "${jdk}" == "${JAVA_HOME}" ]] && mark=" ${GREEN}← activo${RESET}"
    echo "    • ${jdk}"
    echo "      ${ver}${mark}"
  done < <(find_installed_jdks)

  if [[ "${found}" -eq 0 ]]; then
    log_warn "No se detectaron JDKs en rutas estándar"
    echo
    show_java_install_commands
  fi
  echo
}

show_gradle_status() {
  echo -e "${BOLD}Gradle${RESET}"
  echo "────────────────────────────────────────"
  echo "  Wrapper      : $(get_gradle_version)"
  echo "  ForgeGradle  : $(get_forgegradle_version)"
  echo "  Daemon       : $(get_prop org.gradle.daemon "${GRADLE_PROPERTIES}" 2>/dev/null || echo 'no definido')"
  echo "  JVM args     : $(get_prop org.gradle.jvmargs "${GRADLE_PROPERTIES}" 2>/dev/null || echo 'no definido')"

  if [[ -x "${PROJECT_ROOT}/gradlew" ]]; then
    load_local_config
    if (cd "${PROJECT_ROOT}" && ./gradlew --version &>/dev/null); then
      echo
      (cd "${PROJECT_ROOT}" && ./gradlew --version 2>/dev/null | sed -n '1,6p' | sed 's/^/  /')
      log_ok "gradlew ejecutable correctamente"
    else
      log_error "gradlew no puede ejecutarse con el Java actual"
      echo
      show_gradle_update_commands
    fi
  else
    log_error "gradlew no encontrado o sin permisos de ejecución"
  fi
  echo
}

show_forge_status() {
  echo -e "${BOLD}Minecraft / Forge${RESET}"
  echo "────────────────────────────────────────"
  local mc forge mc_range forge_range mapping_ch mapping_ver mod_ver
  mc="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
  forge="$(get_prop forge_version "${GRADLE_PROPERTIES}")"
  mc_range="$(get_prop minecraft_version_range "${GRADLE_PROPERTIES}")"
  forge_range="$(get_prop forge_version_range "${GRADLE_PROPERTIES}")"
  mapping_ch="$(get_prop mapping_channel "${GRADLE_PROPERTIES}")"
  mapping_ver="$(get_prop mapping_version "${GRADLE_PROPERTIES}")"
  mod_ver="$(get_prop mod_version "${GRADLE_PROPERTIES}")"

  echo "  Minecraft    : ${mc}"
  echo "  MC range     : ${mc_range}"
  echo "  Forge        : ${forge}"
  echo "  Forge range  : ${forge_range}"
  echo "  Mappings     : ${mapping_ch} / ${mapping_ver}"
  echo "  Mod version  : ${mod_ver}"
  echo
}

check_recommendations() {
  echo -e "${BOLD}Recomendaciones${RESET}"
  echo "────────────────────────────────────────"
  local issues=0

  local gradle_ver forge_ver java_tc
  gradle_ver="$(get_gradle_version)"
  forge_ver="$(get_prop forge_version "${GRADLE_PROPERTIES}")"
  java_tc="$(get_java_toolchain)"

  if [[ "${gradle_ver}" == "8.1.1" ]]; then
    log_warn "Gradle ${gradle_ver} está desactualizado → recomendado 8.14.3+"
    issues=$((issues + 1))
  fi

  if [[ "${forge_ver}" == "47.1.0" ]]; then
    log_warn "Forge ${forge_ver} está desactualizado → recomendado 47.4.10"
    issues=$((issues + 1))
  fi

  if [[ "${java_tc}" != "17" ]]; then
    log_warn "Para MC 1.20.1 el toolchain debería ser Java 17 (actual: ${java_tc})"
    issues=$((issues + 1))
  fi

  if command -v java &>/dev/null; then
    local major
    major="$(java_major_version java)"
    if is_recommended_launcher_java java; then
      : # Java 17 launcher — sin advertencia
    elif [[ "${major}" == "21" ]]; then
      log_warn "Launcher Java 21: alternativa válida verificada (recomendado oficial: JDK 17)"
    elif [[ "${major}" -ge 25 && "$(printf '%s\n' "${gradle_ver}" "8.14.3" | sort -V | head -1)" == "${gradle_ver}" ]]; then
      log_warn "Java ${major} + Gradle ${gradle_ver} → usar JDK 17/21 como launcher o actualizar Gradle"
      issues=$((issues + 1))
    elif [[ "${major}" -ge 22 ]]; then
      log_warn "Java ${major} como launcher → preferir JDK 17 o 21"
      issues=$((issues + 1))
    fi
  fi

  if [[ "${issues}" -eq 0 ]]; then
    log_ok "No hay advertencias críticas"
  else
    show_contextual_commands
  fi
  echo
}

verify_environment() {
  screen_clear
  echo -e "${BOLD}${CYAN}═══ Verificación del entorno ═══${RESET}"
  echo
  show_java_status
  show_gradle_status
  show_forge_status
  check_recommendations
  pause
}

# ─── Configuración de versiones ───────────────────────────────────────────────

set_minecraft_version() {
  local current new major
  current="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
  echo "Minecraft actual: ${current}"
  read -r -p "Nueva versión de Minecraft [${current}]: " new
  new="${new:-${current}}"

  set_prop "minecraft_version" "${new}" "${GRADLE_PROPERTIES}"
  major="${new%%.*}"
  set_prop "minecraft_version_range" "[${new})" "${GRADLE_PROPERTIES}"
  set_prop "mapping_version" "${new}" "${GRADLE_PROPERTIES}"

  log_ok "minecraft_version → ${new}"
  log_info "Revisa manualmente mod_version en gradle.properties si cambias de rama MC"
  pause
}

set_forge_version() {
  local current mc major new
  current="$(get_prop forge_version "${GRADLE_PROPERTIES}")"
  mc="$(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
  major="${mc%%.*}"

  echo "Forge actual: ${current} (MC ${mc})"
  echo "Sugerencias para MC ${mc}:"
  echo "  • 47.4.10 (recomendado oficial)"
  echo "  • 47.4.20 (último disponible)"
  echo "  • 47.1.0  (actual del proyecto)"
  read -r -p "Nueva versión de Forge [${current}]: " new
  new="${new:-${current}}"

  set_prop "forge_version" "${new}" "${GRADLE_PROPERTIES}"
  local forge_major
  forge_major="${new%%.*}"
  set_prop "forge_version_range" "[${forge_major},)" "${GRADLE_PROPERTIES}"
  set_prop "loader_version_range" "[${forge_major},)" "${GRADLE_PROPERTIES}"

  log_ok "forge_version → ${new}"
  echo
  log_info "Refrescar dependencias tras cambiar Forge:"
  print_cmd "./gradlew --refresh-dependencies clean build"
  pause
}

set_java_toolchain() {
  local current_tc current_rel new
  current_tc="$(get_java_toolchain)"
  current_rel="$(get_java_release)"

  echo "Toolchain actual : Java ${current_tc}"
  echo "Bytecode release : Java ${current_rel}"
  echo
  echo "Versiones habituales:"
  echo "  • 17 — MC 1.18 – 1.20.1 (recomendado para este proyecto)"
  echo "  • 21 — MC 1.20.2+"
  echo "  • 25 — solo con Gradle ≥ 8.14 y MC reciente"
  read -r -p "Versión de Java para compilar [${current_tc}]: " new
  new="${new:-${current_tc}}"

  if [[ ! "${new}" =~ ^[0-9]+$ ]]; then
    log_error "Versión inválida"
    pause
    return
  fi

  sed -i "s/JavaLanguageVersion\.of([0-9]\+)/JavaLanguageVersion.of(${new})/" "${BUILD_GRADLE}"
  sed -i "s/options\.release = [0-9]\+/options.release = ${new}/" "${BUILD_GRADLE}"

  log_ok "Toolchain y release → Java ${new}"
  if [[ "${new}" != "17" && "$(get_prop minecraft_version "${GRADLE_PROPERTIES}")" == "1.20.1" ]]; then
    log_warn "MC 1.20.1 requiere bytecode Java 17 en producción"
  fi
  if ! has_jdk_version "${new}"; then
    echo
    show_java_install_commands
  fi
  pause
}

set_gradle_version() {
  local current new
  current="$(get_gradle_version)"
  echo "Gradle Wrapper actual: ${current}"
  echo "Recomendado: 8.14.3 (compatible con ForgeGradle 6 y Java 21/25 como launcher)"
  echo
  echo "  Nota: Gradle 8.1.x no arranca con Java 21+. Si falla, el script"
  echo "        actualiza gradle-wrapper.properties y usa JDK 17/21 automáticamente."
  read -r -p "Nueva versión de Gradle [${current}]: " new
  new="${new:-${current}}"

  if [[ ! "${new}" =~ ^[0-9.]+$ ]]; then
    log_error "Versión inválida"
    pause
    return
  fi

  update_gradle_wrapper "${new}"
  echo
  print_cmd "./gradlew --version"
  pause
}

set_forgegradle_version() {
  local current new
  current="$(get_forgegradle_version)"
  echo "ForgeGradle actual: ${current}"
  echo "Recomendado: 6.0.47 (compatible con Gradle 8.14.3; no usar 6.0.29 fijado)"
  read -r -p "Nueva versión de ForgeGradle [${current}]: " new
  new="${new:-${current}}"

  sed -i "s|id 'net.minecraftforge.gradle' version '[^']*'|id 'net.minecraftforge.gradle' version '${new}'|" "${BUILD_GRADLE}"
  log_ok "ForgeGradle → ${new}"
  echo
  print_cmd "./gradlew --refresh-dependencies build"
  pause
}

set_mod_version() {
  local current new
  current="$(get_prop mod_version "${GRADLE_PROPERTIES}")"
  read -r -p "Nueva mod_version [${current}]: " new
  new="${new:-${current}}"
  set_prop "mod_version" "${new}" "${GRADLE_PROPERTIES}"
  log_ok "mod_version → ${new}"
  pause
}

configure_versions_menu() {
  while true; do
    clear
    echo -e "${BOLD}${CYAN}═══ Configurar versiones de compilación ═══${RESET}"
    echo
    echo "  Minecraft  : $(get_prop minecraft_version "${GRADLE_PROPERTIES}")"
    echo "  Forge      : $(get_prop forge_version "${GRADLE_PROPERTIES}")"
    echo "  Java       : $(get_java_toolchain) (toolchain / release)"
    echo "  Gradle     : $(get_gradle_version)"
    echo "  ForgeGradle: $(get_forgegradle_version)"
    echo "  mod_version: $(get_prop mod_version "${GRADLE_PROPERTIES}")"
    echo
    echo "  1) Versión de Minecraft"
    echo "  2) Versión de Forge"
    echo "  3) Versión de Java (toolchain + bytecode)"
    echo "  4) Versión de Gradle Wrapper"
    echo "  5) Versión de ForgeGradle"
    echo "  6) Versión del mod (mod_version)"
    echo "  0) Volver"
    echo
    read -r -p "Opción: " choice
    case "${choice}" in
      1) set_minecraft_version ;;
      2) set_forge_version ;;
      3) set_java_toolchain ;;
      4) set_gradle_version ;;
      5) set_forgegradle_version ;;
      6) set_mod_version ;;
      0) return ;;
      *) log_error "Opción inválida"; pause ;;
    esac
  done
}

find_first_jdk_for_major() {
  local want="$1"
  while IFS= read -r jdk; do
    [[ -z "${jdk}" ]] && continue
    local major
    major="$("${jdk}/bin/java" -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/')"
    if [[ "${major}" == "${want}" ]]; then
      echo "${jdk}"
      return 0
    fi
  done < <(find_installed_jdks)
  return 1
}

# Elige JDK 17 o 21 como launcher de Gradle al aplicar un perfil
select_profile_launcher_java() {
  local jdk17 jdk21 choice default_choice

  jdk17="$(find_first_jdk_for_major 17 || true)"
  jdk21="$(find_first_jdk_for_major 21 || true)"

  echo
  echo -e "${BOLD}Launcher JVM para Gradle${RESET} (el mod sigue compilando a bytecode Java 17):"
  echo

  if [[ -n "${jdk17}" ]]; then
    echo "  1) Java 17 — recomendado (Forge oficial)"
    echo "     ${jdk17}"
  else
    echo "  1) Java 17 — recomendado (no instalado en este sistema)"
  fi

  if [[ -n "${jdk21}" ]]; then
    echo "  2) Java 21 — alternativa válida (compila OK en este proyecto)"
    echo "     ${jdk21}"
  else
    echo "  2) Java 21 — alternativa válida (no instalado en este sistema)"
  fi

  echo "  0) Omitir (no cambiar JAVA_HOME)"
  echo

  if [[ -n "${jdk17}" ]]; then
    default_choice="1"
  elif [[ -n "${jdk21}" ]]; then
    default_choice="2"
  else
    log_warn "No se encontró JDK 17 ni 21. Instala uno antes de continuar."
    show_java_install_commands
    return 1
  fi

  read -r -p "Selecciona launcher Java [${default_choice}]: " choice
  choice="${choice:-${default_choice}}"

  case "${choice}" in
    1)
      if [[ -z "${jdk17}" ]]; then
        log_error "JDK 17 no está instalado"
        print_cmd "sudo apt install -y openjdk-17-jdk"
        return 1
      fi
      save_java_home "${jdk17}"
      export JAVA_HOME="${jdk17}"
      export PATH="${JAVA_HOME}/bin:${PATH}"
      log_ok "JAVA_HOME → ${jdk17} (Java 17, recomendado)"
      ;;
    2)
      if [[ -z "${jdk21}" ]]; then
        log_error "JDK 21 no está instalado"
        print_cmd "sudo apt install -y openjdk-21-jdk"
        return 1
      fi
      save_java_home "${jdk21}"
      export JAVA_HOME="${jdk21}"
      export PATH="${JAVA_HOME}/bin:${PATH}"
      log_warn "JAVA_HOME → ${jdk21} (Java 21, alternativa válida)"
      ;;
    0)
      log_info "JAVA_HOME sin cambios"
      ;;
    *)
      log_error "Opción inválida"
      return 1
      ;;
  esac
  return 0
}

# ─── Perfiles predefinidos ────────────────────────────────────────────────────

apply_profile_1201_recommended() {
  echo -e "${BOLD}Perfil recomendado: MC 1.20.1 (desarrollo actual)${RESET}"
  echo
  echo "  Minecraft   → 1.20.1"
  echo "  Forge       → 47.4.10"
  echo "  Bytecode    → Java 17 (target del mod, fijo)"
  echo "  Launcher    → Java 17 (recomendado) o Java 21 (alternativa válida)"
  echo "  Gradle      → 8.14.3"
  echo "  ForgeGradle → 6.0.47"
  echo
  read -r -p "¿Aplicar este perfil? [s/N]: " confirm
  [[ "${confirm,,}" == "s" || "${confirm,,}" == "si" ]] || return

  set_prop "minecraft_version" "1.20.1" "${GRADLE_PROPERTIES}"
  set_prop "minecraft_version_range" "[1.20.1)" "${GRADLE_PROPERTIES}"
  set_prop "forge_version" "47.4.10" "${GRADLE_PROPERTIES}"
  set_prop "forge_version_range" "[47,)" "${GRADLE_PROPERTIES}"
  set_prop "loader_version_range" "[47,)" "${GRADLE_PROPERTIES}"
  set_prop "mapping_channel" "parchment" "${GRADLE_PROPERTIES}"
  set_prop "mapping_version" "2023.09.03-1.20.1" "${GRADLE_PROPERTIES}"

  sed -i 's/JavaLanguageVersion\.of([0-9]\+)/JavaLanguageVersion.of(17)/' "${BUILD_GRADLE}"
  sed -i 's/options\.release = [0-9]\+/options.release = 17/' "${BUILD_GRADLE}"
  sed -i "s|id 'net.minecraftforge.gradle' version '[^']*'|id 'net.minecraftforge.gradle' version '6.0.47'|" "${BUILD_GRADLE}"

  load_local_config
  update_gradle_wrapper "8.14.3" || true

  select_profile_launcher_java || true

  log_ok "Perfil MC 1.20.1 recomendado aplicado"
  pause
}

apply_profile_1201_legacy() {
  echo -e "${BOLD}Perfil legacy: MC 1.20.1 (configuración original del fork)${RESET}"
  read -r -p "¿Restaurar Forge 47.1.0 + Gradle 8.1.1? [s/N]: " confirm
  [[ "${confirm,,}" == "s" || "${confirm,,}" == "si" ]] || return

  set_prop "forge_version" "47.1.0" "${GRADLE_PROPERTIES}"
  sed -i "s|id 'net.minecraftforge.gradle' version '[^']*'|id 'net.minecraftforge.gradle' version '6.0.47'|" "${BUILD_GRADLE}"
  sed -i 's|distributionUrl=.*|distributionUrl=https\\://services.gradle.org/distributions/gradle-8.1.1-bin.zip|' "${GRADLE_WRAPPER}"
  log_ok "Perfil legacy restaurado"
  pause
}

profiles_menu() {
  while true; do
    clear
    echo -e "${BOLD}${CYAN}═══ Perfiles predefinidos ═══${RESET}"
    echo
    echo "  1) MC 1.20.1 recomendado (Forge 47.4.10, launcher Java 17 o 21, Gradle 8.14.3)"
    echo "  2) MC 1.20.1 legacy (Forge 47.1.0, Gradle 8.1.1)"
    echo "  0) Volver"
    echo
    read -r -p "Opción: " choice
    case "${choice}" in
      1) apply_profile_1201_recommended ;;
      2) apply_profile_1201_legacy ;;
      0) return ;;
      *) log_error "Opción inválida"; pause ;;
    esac
  done
}

# ─── JAVA_HOME ────────────────────────────────────────────────────────────────

configure_java_home() {
  clear
  echo -e "${BOLD}${CYAN}═══ Configurar JAVA_HOME ═══${RESET}"
  echo
  show_java_status

  local jdks=()
  while IFS= read -r jdk; do
    [[ -n "${jdk}" ]] && jdks+=("${jdk}")
  done < <(find_installed_jdks)

  if [[ "${#jdks[@]}" -eq 0 ]]; then
    log_error "No se encontraron JDKs instalados"
    echo
    show_java_install_commands
    pause
    return
  fi

  echo "Selecciona un JDK:"
  local i=1
  for jdk in "${jdks[@]}"; do
    local ver
    ver="$("${jdk}/bin/java" -version 2>&1 | head -1)"
    echo "  ${i}) ${jdk}"
    echo "     ${ver}"
    i=$((i + 1))
  done
  echo "  0) Cancelar"
  echo
  read -r -p "Opción: " choice

  if [[ "${choice}" == "0" || -z "${choice}" ]]; then
    return
  fi

  if [[ "${choice}" =~ ^[0-9]+$ && "${choice}" -le "${#jdks[@]}" && "${choice}" -ge 1 ]]; then
    local selected="${jdks[$((choice - 1))]}"
    save_java_home "${selected}"
    export JAVA_HOME="${selected}"
    export PATH="${JAVA_HOME}/bin:${PATH}"
    log_ok "Sesión actual configurada con JAVA_HOME=${selected}"
  else
    log_error "Opción inválida"
  fi
  pause
}

# ─── Compilación ──────────────────────────────────────────────────────────────

run_build() {
  clear
  echo -e "${BOLD}Compilando proyecto...${RESET}"
  load_local_config
  if gradle_cmd build; then
    log_ok "Build exitoso"
    echo
    ls -la "${PROJECT_ROOT}/build/libs/" 2>/dev/null | sed 's/^/  /' || true
  else
    log_error "Build falló"
  fi
  pause
}

run_clean_build() {
  clear
  echo -e "${BOLD}Limpiando y compilando...${RESET}"
  load_local_config
  if gradle_cmd clean build; then
    log_ok "Clean build exitoso"
  else
    log_error "Clean build falló"
  fi
  pause
}

run_gradle_task() {
  local task="$1"
  clear
  echo -e "${BOLD}Ejecutando: ./gradlew ${task}${RESET}"
  load_local_config
  gradle_cmd "${task}" || log_error "Tarea falló"
  pause
}

build_menu() {
  while true; do
    clear
    echo -e "${BOLD}${CYAN}═══ Compilar / Ejecutar ═══${RESET}"
    echo
    echo "  1) ./gradlew build"
    echo "  2) ./gradlew clean build"
    echo "  3) ./gradlew runClient   — cliente local (desarrollo)"
    echo "  4) ./gradlew runServer   — servidor dedicado (EULA auto en run/)"
    echo "  5) ./gradlew --version"
    echo "  6) Tarea personalizada"
    echo "  0) Volver"
    echo
    read -r -p "Opción: " choice
    case "${choice}" in
      1) run_build ;;
      2) run_clean_build ;;
      3) run_gradle_task runClient ;;
      4) run_gradle_task runServer ;;
      5) run_gradle_task --version ;;
      6)
        read -r -p "Nombre de la tarea Gradle: " task
        [[ -n "${task}" ]] && run_gradle_task "${task}"
        ;;
      0) return ;;
      *) log_error "Opción inválida"; pause ;;
    esac
  done
}

# ─── Utilidades adicionales ───────────────────────────────────────────────────

toggle_gradle_daemon() {
  local current
  current="$(get_prop org.gradle.daemon "${GRADLE_PROPERTIES}")"
  if [[ "${current}" == "true" ]]; then
    set_prop "org.gradle.daemon" "false" "${GRADLE_PROPERTIES}"
    log_ok "Gradle daemon desactivado"
  else
    set_prop "org.gradle.daemon" "true" "${GRADLE_PROPERTIES}"
    log_ok "Gradle daemon activado (recomendado en desarrollo)"
  fi
  pause
}

fix_permissions() {
  echo "Corrigiendo permisos del proyecto..."
  find "${PROJECT_ROOT}" -type d -not -path "${PROJECT_ROOT}/.git/*" -exec chmod 755 {} + 2>/dev/null || true
  find "${PROJECT_ROOT}" -type f -not -path "${PROJECT_ROOT}/.git/*" ! -name 'gradlew' -exec chmod 644 {} + 2>/dev/null || true
  chmod 755 "${PROJECT_ROOT}/gradlew" 2>/dev/null || true
  chmod 755 "${SCRIPT_DIR}/release.sh" 2>/dev/null || true
  chmod 755 "${SCRIPT_DIR}/publish-release.sh" 2>/dev/null || true
  chmod 755 "${SCRIPT_DIR}/server-smoke.sh" 2>/dev/null || true
  log_ok "Permisos corregidos (dirs 755, archivos 644, gradlew 755)"
  pause
}

open_config_file() {
  local file="$1"
  local editor="${EDITOR:-${VISUAL:-nano}}"
  if [[ -f "${file}" ]]; then
    "${editor}" "${file}"
  else
    log_error "Archivo no encontrado: ${file}"
    pause
  fi
}

tools_menu() {
  while true; do
    clear
    echo -e "${BOLD}${CYAN}═══ Herramientas ═══${RESET}"
    echo
    echo "  1) Alternar Gradle daemon (actual: $(get_prop org.gradle.daemon "${GRADLE_PROPERTIES}"))"
    echo "  2) Corregir permisos de archivos"
    echo "  3) Editar gradle.properties"
    echo "  4) Editar build.gradle"
    echo "  5) Editar gradle-wrapper.properties"
    echo "  6) Ver comandos de instalación/actualización"
    echo "  0) Volver"
    echo
    read -r -p "Opción: " choice
    case "${choice}" in
      1) toggle_gradle_daemon ;;
      2) fix_permissions ;;
      3) open_config_file "${GRADLE_PROPERTIES}" ;;
      4) open_config_file "${BUILD_GRADLE}" ;;
      5) open_config_file "${GRADLE_WRAPPER}" ;;
      6) show_all_suggested_commands ;;
      0) return ;;
      *) log_error "Opción inválida"; pause ;;
    esac
  done
}

show_help() {
  clear
  cat <<'EOF'
═══ Ayuda — release.sh ═══

Este script gestiona el entorno de desarrollo de Console Filter Next.

REGLAS IMPORTANTES
  • MC 1.20.1 requiere bytecode Java 17 (target del mod, no del launcher).
  • Launcher Gradle: JDK 17 recomendado; JDK 21 alternativa válida (compila OK).
  • Java 25 como launcher requiere Gradle ≥ 8.14.3.
  • Forge y Minecraft deben ser versiones compatibles entre sí.
  • El mod funciona en cliente y servidor; ambos entornos se pueden probar con Gradle.

EJECUCIÓN LOCAL (cliente y servidor)
  • ./gradlew runClient  — inicia el cliente con el mod cargado desde run/
  • ./gradlew runServer  — inicia servidor dedicado; genera run/eula.txt (eula=true)
  • run/ está en .gitignore (datos locales de desarrollo, no versionar)

ARCHIVOS QUE MODIFICA
  • gradle.properties      — minecraft_version, forge_version, mod_version
  • build.gradle           — Java toolchain, ForgeGradle
  • gradle/wrapper/...     — versión de Gradle
  • scripts/.release.local — JAVA_HOME local (no versionar)

PERFIL RECOMENDADO (menú 3 → opción 1)
  Minecraft 1.20.1 | Forge 47.4.10 | Launcher Java 17 o 21 | Gradle 8.14.3 | FG 6.0.47

DOCUMENTACIÓN
  README.md                    — información del mod y fork de Matthew Czyr
  scripts/release.sh           — entorno de desarrollo interactivo

USO RÁPIDO
  ./scripts/release.sh          # menú interactivo
  ./scripts/release.sh verify   # solo verificar entorno
  ./scripts/release.sh profile  # aplicar perfil recomendado
  ./scripts/release.sh publish  # build + tag + GitHub + Modrinth + CurseForge
  ./scripts/release.sh commands # ver comandos de instalar/actualizar

PUBLICACIÓN DE RELEASES (opción 9 / publish)
  Requiere: gh auth login, jq, curl
  Tokens en scripts/.release.local (ver .release.local.example):
    CURSEFORGE_API_TOKEN, MODRINTH_TOKEN
  Flujo: clean build → tag (mod_version) → push → GitHub Release → Modrinth → CurseForge
  Dry-run: ./scripts/release.sh publish --dry-run

COMANDOS EXTERNOS FRECUENTES
  Java 17 (recomendado): sudo apt install openjdk-17-jdk
  Java 21 (alternativa): sudo apt install openjdk-21-jdk
  Gradle:          ./gradlew wrapper --gradle-version=8.14.3
  Forge:           sed -i 's|^forge_version=.*|forge_version=47.4.10|' gradle.properties
                   ./gradlew --refresh-dependencies clean build
EOF
  pause
}

# ─── Menú principal ───────────────────────────────────────────────────────────

main_menu() {
  while true; do
    clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║   Console Filter Next — Entorno de desarrollo        ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${DIM}  MC $(get_prop minecraft_version "${GRADLE_PROPERTIES}") │ Forge $(get_prop forge_version "${GRADLE_PROPERTIES}") │ Java $(get_java_toolchain) │ Gradle $(get_gradle_version)${RESET}"
    echo
    echo "  1) Verificar entorno (Java, Gradle, Forge, SDK...)"
    echo "  2) Configurar versiones de compilación"
    echo "  3) Aplicar perfil predefinido"
    echo "  4) Configurar JAVA_HOME"
    echo "  5) Compilar / Ejecutar (Gradle)"
    echo "  6) Herramientas y utilidades"
    echo "  7) Ayuda"
    echo "  8) Comandos de instalación / actualización"
    echo "  9) Publicar release (GitHub + Modrinth + CurseForge)"
    echo "  0) Salir"
    echo
    read -r -p "Opción: " choice
    case "${choice}" in
      1) verify_environment ;;
      2) configure_versions_menu ;;
      3) profiles_menu ;;
      4) configure_java_home ;;
      5) build_menu ;;
      6) tools_menu ;;
      7) show_help ;;
      8) show_all_suggested_commands ;;
      9) publish_release_menu ;;
      0) echo "Hasta luego."; exit 0 ;;
      *) log_error "Opción inválida"; pause ;;
    esac
  done
}

# ─── Entrada ──────────────────────────────────────────────────────────────────

cd "${PROJECT_ROOT}"
load_local_config

require_file "${GRADLE_PROPERTIES}" || exit 1
require_file "${BUILD_GRADLE}" || exit 1

case "${1:-}" in
  verify|check)
    verify_environment
    ;;
  profile|recommended)
    apply_profile_1201_recommended
    ;;
  java)
    configure_java_home
    ;;
  build)
    run_build
    ;;
  help|-h|--help)
    show_help
    ;;
  commands|cmds)
    show_all_suggested_commands
    ;;
  publish|release)
    publish_release_cli "${@:2}"
    ;;
  "")
    main_menu
    ;;
  *)
    echo "Uso: $(basename "$0") [verify|profile|java|build|publish|commands|help]"
    exit 1
    ;;
esac
