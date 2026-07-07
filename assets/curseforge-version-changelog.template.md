<!--
  Plantilla del changelog de versión para CurseForge (campo changelog al publicar).
  Copiar a curseforge-version-changelog.md y actualizar antes de cada release.

  - Solo cambios de código/funcionalidad (sin CI, publicación ni distribución).
  - Añadir la nueva versión arriba; conservar el historial relevante.
  - Referenciado desde assets/curseforge.json → version_changelog_file
-->

# Console Filter Next — Changelog (solo código)

## X.Y.Z · Minecraft 1.20.1

- Cambio funcional o corrección de bug
- Otro cambio de código

---

## 4.0.3 · Minecraft 1.20.1

_Sin cambios funcionales en el mod._

---

## 4.0.2 · Minecraft 1.20.1

_Sin cambios funcionales en el mod._

---

## 4.0.1 · Minecraft 1.20.1

_Sin cambios funcionales en el mod._

---

## 4.0.0 · Minecraft 1.20.1

- Editor in-game: listas paginadas, validación de regex, import/export y presets integrados
- **modIdFilters** — filtrar líneas por mod id de Forge (resuelto desde el nombre del logger)
- **skipMessagesWithStackTrace** — no ocultar líneas con excepciones o stack traces
- Estadísticas por tipo de filtro en `/consolefilter status`
- `/consolefilter profile` persiste `activeProfile` en `consolefilternext-common.toml`
- Editor: pantalla de ruta de config, edición de listas mejorada y round-trip con Save & Apply
- Nuevas piezas: `ModIdResolver`, `StackTraceDetector`, `RegexValidator`, `ConfigPreset`, `FilterStats`

---

## 3.5.0 · Minecraft 1.20.1

- Editor de configuración in-game completo (Forge Mod List → Config; sin dependencias extra)
- Edición de booleanos, perfiles activos/edición y todas las listas de filtros desde la UI
- **Save & Apply** escribe el TOML y recarga filtros en caliente
- `ConfigEditorModel`, `FilterListEditScreen` y ampliación de `ConsoleFilterConfigScreen`

---

## 3.4.0 · Minecraft 1.20.1

- **loggerFilters** (alias legacy, unificado con source filtering)
- Perfiles de filtro: `default`, `debug`, `production`
- Comandos `/consolefilter export`, `import` y `profile`
- **filterLatestLog** — aplicar filtros a `latest.log` y otros appenders Log4j (`Log4jAppenderFilters`)
- Pantalla de config en cliente (botón Config del Mod List)
- `ConfigFileHelper` para lectura/escritura del TOML desde comandos y UI

---

## 3.3.1 · Minecraft 1.20.1

- **threadFilters** usan coincidencia por `contains` (alineado con `sourceFilters`)
- Refactor de `Log4jFilter` para extender `AbstractFilter`

---

## 3.3.0 · Minecraft 1.20.1

- Comandos `/consolefilter reload`, `list` y `status` (OP nivel 2)
- Opciones de config **ignoreCase** y **whitelistMode**
- Contador de mensajes filtrados en `/consolefilter status`

---

## 3.2.0 · Minecraft 1.20.1

- **sourceFilters** por `contains`; **levelFilters** case-insensitive
- Precompilación de patrones regex al cargar la config (menos fallos en runtime)
- Migración al constructor `FMLJavaModLoadingContext` (compatibilidad Forge 47.4+)
- Rangos de dependencias Minecraft/Forge declarados en `mods.toml`

---

## 3.1.0 · Minecraft 1.20.1

- Integración de `JavaFilter`, `Log4jFilter`, `SystemOutFilter` y `SystemErrFilter`
- Config solo vía ForgeConfig (sin creación manual de archivos)
- Hot-reload de config con `ModConfigEvent`
- Filtrado de líneas de consola en texto plano (basic/regex) sin exigir formato de log parseado
- Separación de `SystemFilter` en stdout/stderr dedicados

---

## 3.0.1 · Minecraft 1.20.1

- Atribución del fork y descripción del mod actualizada en `mods.toml`

---

## 3.0.0 · Minecraft 1.20.1

- Release inicial del fork para MC 1.20.1 (basado en [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) de Matthew Czyr)
- Filtros por nivel, thread, source, texto básico y regex
- Config Forge en `consolefilternext-common.toml`

---

## Pre-3.0.0 · Fundación del fork

Cambios de código anteriores al versionado 3.0.0, en orden cronológico inverso (más reciente primero).

### Icono del mod

- Añadido `icon.png` y referencia en `mods.toml`

### Renombrado y config automática

- Renombrado del mod a **Console Filter Next** en código y metadatos
- Creación automática del archivo de configuración si no existe al iniciar

### Corrección de lógica de filtrado

- `JavaFilter`, `Log4jFilter` y `SystemFilter` delegan en `LogMessage` y `ConsoleFilterConfig.shouldFilter(LogMessage)`
- `CustomFilter` expone `shouldFilter(LogMessage)` para unificar el pipeline
- `Log4jFilter` registrado como plugin Log4j (`@Plugin`) para integración con el core de logging

### Modelo `LogMessage`

- Clase `LogMessage` con timestamp, thread, level, source y mensaje
- `FilterEntry` opera sobre `LogMessage` en lugar de `String` plano

### Filtros extendidos y refactor — commit `0d7ef73`

- Migración de paquete `com.chaosthedude.consolefilter` → `com.alanjmrt94.consolefilternext`
- Nuevos tipos de filtro en config: **levelFilters**, **threadFilters**, **sourceFilters**
- `FilterEntry` ampliado con factories `level()`, `thread()` y `source()`
- `ConsoleFilter.shouldFilter(String)` parsea líneas con patrón `[time] [thread/level] [source]: message`
- Reorganización de clases de filtro (`CustomFilter`, `JavaFilter`, `Log4jFilter`, `SystemFilter`)

---

## Linaje

Basado originalmente en [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) por **Matthew Czyr** (MattCzyr).  
**Console Filter Next** por **alanjmrt94** · [CC BY-NC-SA 4.0](LICENSE.md)
