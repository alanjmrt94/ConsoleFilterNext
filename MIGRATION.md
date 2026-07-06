# Migrating from ConsoleFilter (Matthew Czyr)

Console Filter Next is a **fork** with extra features. Config file name and several keys differ.

## Downloads (this fork)

- [CurseForge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext)
- [Modrinth](https://modrinth.com/mod/consolefilternext)
- [GitHub](https://github.com/alanjmrt94/ConsoleFilterNext)

## File location

| Original ConsoleFilter | Console Filter Next |
|------------------------|---------------------|
| `config/consolefilter-common.toml` (varies by version) | `config/consolefilternext-common.toml` |

## Key mapping

| ConsoleFilter (original) | Console Filter Next | Notes |
|--------------------------|---------------------|-------|
| `basicFilters` | `basicFilters` | Same behavior (contains) |
| `regexFilters` | `regexFilters` | Same; invalid regex skipped at load |
| `loggerFilters` | `loggerFilters` **or** `sourceFilters` | Both supported; merged at runtime |
| — | `sourceFilters` | New name; contains match on logger/source |
| — | `levelFilters` | **New** — filter by INFO, WARN, ERROR, etc. |
| — | `threadFilters` | **New** — contains match on thread name |
| — | `modIdFilters` | **New** — filter by Forge mod id (e.g. `jei`) |
| — | `ignoreCase` | **New** — global case-insensitive matching |
| — | `whitelistMode` | **New** — show only matching messages |
| — | `filterLatestLog` | **New** — filter file appenders / latest.log |
| — | `skipMessagesWithStackTrace` | **New** — never hide lines with exceptions |
| — | `activeProfile` | **New** — `default`, `debug`, or `production` |
| — | `[profiles.debug]` / `[profiles.production]` | **New** — per-profile filter lists |

## Example migration

**Original `consolefilter-common.toml`:**

```toml
[general]
basicFilters = ["Loaded all recipes"]
loggerFilters = ["net.minecraftforge"]
regexFilters = []
```

**Equivalent Console Filter Next:**

```toml
[general]
activeProfile = "default"
ignoreCase = false
whitelistMode = false
filterLatestLog = true
skipMessagesWithStackTrace = false
basicFilters = ["Loaded all recipes"]
regexFilters = []
levelFilters = []
threadFilters = []
sourceFilters = ["net.minecraftforge"]
loggerFilters = ["net.minecraftforge"]
modIdFilters = []
```

## Commands (not in original)

Console Filter Next adds `/consolefilter` (OP 2): `reload`, `list`, `status`, `export`, `import`, `profile`.

## In-game config

Use **Options → Mods → Console Filter Next → Config** (Forge Mod List). No Mod Menu required on Forge.

## Reporting issues

- **This fork:** [alanjmrt94/ConsoleFilterNext](https://github.com/alanjmrt94/ConsoleFilterNext/issues)
- **Original:** [MattCzyr/ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter/issues)

Downloads: [CurseForge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext) · [Modrinth](https://modrinth.com/mod/consolefilternext)
