# Console Filter Next

[![CurseForge](https://img.shields.io/badge/CurseForge-consolefilternext-F16436?logo=curseforge&logoColor=white)](https://www.curseforge.com/minecraft/mc-mods/consolefilternext)
[![Modrinth](https://img.shields.io/modrinth/dt/consolefilternext?logo=modrinth&label=Modrinth&color=00af5c)](https://modrinth.com/mod/consolefilternext)

An improved console log filter for Minecraft **Forge / Fabric / NeoForge** — by text, regex, log level, thread, source, and mod id. Reduce console noise on the client or dedicated server while debugging modpacks and development environments.

**Current releases** (mismo `mod_semver` `4.2.0`, tags `{mc}-4.2.0`):

| Minecraft | Loaders | Tag |
|-----------|---------|-----|
| **1.20.1** | Forge · Fabric · NeoForge | `1.20.1-4.2.0` |
| **26.1** | Fabric · NeoForge (Java 25) | `26.1-4.2.0` |
| **26.2** | Fabric · NeoForge (Java 25) | `26.2-4.2.0` |

**Discord:** [discord.gg/CcUNTJjPD](https://discord.gg/CcUNTJjPD)

## Downloads

| Loader | CurseForge | Modrinth |
|--------|------------|----------|
| **Forge 1.20.1** | [1.20.1 · Forge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext/files?page=1&pageSize=20&version=1.20.1&gameVersionTypeId=1) | [`1.20.1-4.2.0+forge`](https://modrinth.com/mod/consolefilternext/version/1CZFZaWj) |
| **Fabric 1.20.1** | [1.20.1 · Fabric](https://www.curseforge.com/minecraft/mc-mods/consolefilternext/files?page=1&pageSize=20&version=1.20.1&gameVersionTypeId=4) | [`1.20.1-4.2.0+fabric`](https://modrinth.com/mod/consolefilternext/version/JEPbwMU8) |
| **NeoForge 1.20.1** | [1.20.1 · NeoForge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext/files?page=1&pageSize=20&version=1.20.1&gameVersionTypeId=6) | [`1.20.1-4.2.0+neoforge`](https://modrinth.com/mod/consolefilternext/version/EE1FzT7i) |
| **Fabric / NeoForge 26.1–26.2** | Filtrar por versión de juego | Filtrar por game version |

| Hub | Link |
|-----|------|
| **CurseForge** (proyecto) | [consolefilternext](https://www.curseforge.com/minecraft/mc-mods/consolefilternext) |
| **Modrinth** (proyecto) | [consolefilternext](https://modrinth.com/mod/consolefilternext) |
| **GitHub Releases** | tags `1.20.1-4.2.0`, `26.1-4.2.0`, `26.2-4.2.0` |
| **Source & issues** | [GitHub](https://github.com/alanjmrt94/ConsoleFilterNext) |

> **Developers:** run `./scripts/release.sh` for environment setup, builds, and publishing (GitHub + CurseForge + Modrinth).

---

## Features

- **Filter types:** basic text, regex, log level, thread, logger/source, **mod id**
- **Profiles:** `default`, `debug`, `production` — switch in-game, via TOML, or `/consolefilter profile` (persisted)
- **Modes:** blacklist (hide matches) or **whitelist** (show only matches); optional `ignoreCase`
- **`filterLatestLog`:** apply filters to `latest.log` and other Log4j file appenders
- **`skipMessagesWithStackTrace`:** never hide lines with exceptions or stack traces
- **In-game editor** (Forge/NeoForge Mods → Config; Fabric Mod Menu): paginated lists, regex validation, presets, import/export
- **Commands** (OP 2): `reload`, `list`, `status`, `export`, `import`, `profile`
- **Statistics:** per-filter-type hit counts in `/consolefilter status`
- **Hot reload** from file, commands, or **Save & Apply** in the config UI

---

## 🙌 Credits

| | |
|---|---|
| **Console Filter Next** | **alanjmrt94** |
| **Originally based on** | [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) by **Matthew Czyr** ([MattCzyr](https://github.com/MattCzyr)) |
| **ConsoleFilter contributors** | **NgLoader**, **MarkKoz**, **ChaosTheDude** |
| **License** | [CC BY-NC-SA 4.0](LICENSE.md) |

Issues and pull requests: [github.com/alanjmrt94/ConsoleFilterNext](https://github.com/alanjmrt94/ConsoleFilterNext/issues)  
Discord: [discord.gg/CcUNTJjPD](https://discord.gg/CcUNTJjPD)

---

Crafted with ❤️ for modders who want a cleaner console.

## ⚙️ Config

The actual configuration of the mod is done in a separate file generated at runtime.  
To configure the mod, you have two options:

### 🕹️ In-Game

1. Go to **Options → Mods** (Forge / NeoForge) or open **Mod Menu** (Fabric)
2. Find **Console Filter Next**
3. Open **Config**
4. Edit booleans, profiles, and filter lists; use **Save & Apply** to write `consolefilternext-common.toml` and reload filters

Forge and NeoForge use the built-in Mods config button. Fabric uses [Mod Menu](https://modrinth.com/mod/modmenu) when installed (optional).

### 🛠️ Editing the Configuration File

1. Go to the `config` folder in your Minecraft installation  
2. Open `consolefilternext-common.toml`  
3. Edit the values according to your needs

For example, to filter all `INFO` messages from the `Server thread`, your `consolefilternext-common.toml` should look like this:

````toml
[general]

ignoreCase = false
whitelistMode = false
filterLatestLog = true
skipMessagesWithStackTrace = false
activeProfile = "default"

# Filters messages that contain specific text
basicFilters = ["Killed all storms"]

# Filters messages by their log level (e.g., INFO, WARN, ERROR, DEBUG)
levelFilters = ["INFO"]

# Filters messages coming from specific threads
threadFilters = ["Server thread"]

# Filters messages based on their source (logger or class name). Matches when the source **contains** the string (package prefixes work).
sourceFilters = ["net.minecraft.server"]

# Filters messages from Forge mods by mod id (e.g. jei, create)
modIdFilters = []

# Filters messages using regular expressions (advanced)
regexFilters = []
````

> Migrating from [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) (original)? See [MIGRATION.md](MIGRATION.md).

## 💡 Tips

Here are some useful examples to help you get started with advanced filtering:

### ✅ Filter all DEBUG messages

```toml
levelFilters = ["DEBUG"]
```

`levelFilters` are **case-insensitive** (`debug` matches `DEBUG`).

### ✅ Filter messages from a specific mod or package

```toml
sourceFilters = ["com.example.mymod"]
```

`sourceFilters` match when the logger/source **contains** the configured string, so package prefixes like `net.minecraft.server` match `net.minecraft.server.MinecraftServer`.

### ✅ Filter log messages from a specific thread

```toml
threadFilters = ["Server"]
```

`threadFilters` match when the thread name **contains** the configured string (`Server` matches `Server thread`).

### ✅ Filter messages that contain specific phrases

```toml
basicFilters = ["Could not resolve", "Missing texture"]
```

### ✅ Use regular expressions to match patterns (advanced)

```toml
regexFilters = ["^\\[Render thread\\].*Missing.*$", ".*ERROR.*\\bBlockEntity\\b.*"]
```

> Note: Regex patterns must follow Java regular expression syntax.

### ✅ Whitelist mode (show only matching messages)

```toml
whitelistMode = true
basicFilters = ["ERROR", "WARN"]
```

With `whitelistMode = true`, only messages that match at least one filter are shown; everything else is hidden.

### ✅ Case-insensitive matching

```toml
ignoreCase = true
basicFilters = ["missing texture"]
```

Applies to `basicFilters`, `threadFilters`, `sourceFilters`, `loggerFilters`, and `regexFilters`. `levelFilters` are always case-insensitive.

### ✅ Legacy logger filters

```toml
loggerFilters = ["net.minecraft.server"]
```

Same as `sourceFilters` (contains match on logger/source name). Both lists are applied.

### ✅ Filter by Forge mod id

```toml
modIdFilters = ["jei", "create"]
```

Matches loggers/sources belonging to the given mod id (uses Forge `ModList` when available).

### ✅ Skip messages with stack traces

```toml
skipMessagesWithStackTrace = true
```

When `true`, lines with an attached exception or stack-trace text are never hidden.

### ✅ Filter profiles

```toml
activeProfile = "production"

[profiles.debug]
levelFilters = ["DEBUG"]

[profiles.production]
levelFilters = ["WARN", "ERROR"]
```

Profiles: `default` (uses `[general]`), `debug`, or `production`. Switch at runtime (persisted to TOML):

```
/consolefilter profile debug
/consolefilter profile production
/consolefilter profile default
```

### ✅ Filter latest.log

```toml
filterLatestLog = true
```

When `true`, `latest.log` and other Log4j file appenders are filtered. When `false`, only console output is filtered.

### ✅ Export / import config

```
/consolefilter export backups/consolefilter.toml
/consolefilter import backups/consolefilter.toml
```

### ✅ In-game config

- **Forge / NeoForge:** Options → Mods → Console Filter Next → Config
- **Fabric:** Mod Menu → Console Filter Next → Config (optional dependency)
- Paginated list editor (8 entries per page) with **regex validation** for `regexFilters`
- **Presets** (Debug, Silent modpack, Minimal), **Import…** / **Export…** from the config screen
- **Save & Apply** writes the TOML file and reloads filters without restarting

> All three loaders edit the same `consolefilternext-common.toml`.

### ✅ Reload and manage filters

On a server with OP level 2+:

```
/consolefilter reload
/consolefilter list
/consolefilter status
/consolefilter profile production
/consolefilter export backups/consolefilter.toml
/consolefilter import backups/consolefilter.toml
```

`reload` re-reads `consolefilternext-common.toml`. `status` shows profile, filters, hidden message count, and **hits per filter type** (basic, regex, level, thread, source, logger, modId).

---

You can combine multiple filters to fine-tune what gets shown in your console.  
If **any** of the conditions match, the message will be **filtered out**.

---

## 🧩 Compatibility

| | |
|---|---|
| **Minecraft** | 1.20.1 (Forge/Fabric/NeoForge) · 26.1 / 26.2 (Fabric/NeoForge, Java 25) |
| **Mod loaders** | Forge 47+ · Fabric · NeoForge |
| **Java (runtime)** | 17 (MC 1.20.1) · 25 (MC 26.x) |
| **Side** | **Client and dedicated server** — install on either or both; filters apply on both sides |
| **Downloads** | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext) · [Modrinth](https://modrinth.com/mod/consolefilternext) · tags `{mc}-4.2.0` en GitHub |

## 🛠️ Building from source

**Requirements:**

| Línea MC | Bytecode / toolchain | Build |
|----------|----------------------|-------|
| **1.20.1** | Java 17 | `./gradlew :forge:build` · `cd fabric && ./gradlew build` · `cd neoforge && ./gradlew build` |
| **26.1 / 26.2** | Java 25 | `cd fabric-26.1 && ./gradlew build` (igual `neoforge-26.1`, `fabric-26.2`, `neoforge-26.2`) |

Launcher JDK 17/21 OK para 1.20.1; para 26.x preferí JDK 25 (Gradle 9.5+). Si Mojang no es alcanzable: `USE_BMCL_MIRROR=1` (+ HTTP local de `versions/minecraft-meta` si hace falta).

```bash
git clone https://github.com/alanjmrt94/ConsoleFilterNext.git
cd ConsoleFilterNext
./scripts/release.sh verify   # check your setup
./scripts/matrix.sh test      # common + enabled matrix cells
./gradlew :forge:build
cd fabric && ./gradlew build
cd ../neoforge && ./gradlew build
./scripts/server-smoke.sh forge   # also: fabric | neoforge | fabric-26.1 | neoforge-26.1 | fabric-26.2 | neoforge-26.2
./scripts/lint.sh fix             # autofix imports no usados / whitespace
```
JARs 1.20.1: `forge|fabric|neoforge/build/libs/*-{forge,fabric,neoforge}.jar`. JARs 26.x: `fabric-26.*/build/libs/` y `neoforge-26.*/build/libs/`.

### Local development runs (client and server)

The mod is verified for **both** client and dedicated server. Use Gradle from the project root:

| Command | Purpose |
|---------|---------|
| `./gradlew :forge:runClient` | Launch the Minecraft **client** with the mod in `run/mods/` |
| `./gradlew :forge:runServer` | Launch a local **dedicated server** (auto-accepts EULA via `run/eula.txt`) |

The `run/` directory holds local world data, configs, and logs and is **gitignored**.

**Tip:** use the interactive setup script:

```bash
./scripts/release.sh
```

### Publishing a release (maintainers)

With API tokens in `scripts/.release.local` and `gh auth login`:

```bash
./scripts/release.sh publish --dry-run   # simulate
./scripts/release.sh publish             # build + tag + GitHub + Modrinth + CurseForge
```

Copy and edit the template:

```bash
cp scripts/.release.local.example scripts/.release.local
```

#### Platform IDs

| Platform | Variable | Format | When required |
|----------|----------|--------|---------------|
| **Modrinth** | `MODRINTH_PROJECT_ID` | Base62 (e.g. `tFqJGW2q`) | **Required while the project is in Draft** — the public API cannot resolve the slug until the project is approved |
| **Modrinth** | `MODRINTH_PROJECT_SLUG` | URL slug (e.g. `consolefilternext`) | Used for auto-resolution when `MODRINTH_PROJECT_ID` is empty |
| **CurseForge** | `CURSEFORGE_API_TOKEN` | Profile API key (`cfc_pat_…`) | From [CurseForge profile](https://console.curseforge.com/#/profile) — resolve versions/project |
| **CurseForge** | `CURSEFORGE_AUTHOR_TOKEN` | Author API token | From [curseforge.com/account/api-tokens](https://www.curseforge.com/account/api-tokens) — **required to upload files** |
| **CurseForge** | `CURSEFORGE_PROJECT_ID` | Numeric ID | Optional; leave empty to resolve by `CURSEFORGE_PROJECT_SLUG` |

Find the Modrinth Base62 ID in [Modrinth → Projects](https://modrinth.com/dashboard/projects) (column **ID**). Do **not** put the display name (e.g. `ConsoleFilterNext`) in `MODRINTH_PROJECT_ID` — the API expects Base62 and will reject it.

#### Publish flow

**Recommended (CI-gated tag):**

1. Push to `master` and wait for **Build** to succeed
2. `./scripts/release.sh cut` — creates/pushes `mod_version` tag only if Build is green
3. Tag push runs Actions: GitHub Release + Modrinth/CurseForge + Discord notify

**Local full publish** (build + tag + all platforms):

1. Clean build of **Forge + Fabric + NeoForge** → `*-forge.jar` / `*-fabric.jar` / `*-neoforge.jar`
2. Git annotated tag (`mod_version` from `gradle.properties`) → push to `origin`
3. GitHub Release (`gh`) with **three** JAR assets and `changelog.txt` excerpt
4. Modrinth: **one version per loader** (`version_number` = `TAG+forge` / `TAG+fabric` / `TAG+neoforge`)
5. CurseForge: **one file upload per loader** (gameVersions include Forge / Fabric / NeoForge)
6. Discord: webhook post to the mod’s read-only channel (`DISCORD_WEBHOOK_URL`)

```bash
./scripts/release.sh cut --dry-run
./scripts/release.sh cut
```

#### Partial re-runs

If one step already succeeded, skip the rest:

```bash
./scripts/release.sh publish --skip-build --skip-github              # Modrinth + CurseForge only
./scripts/release.sh publish --skip-build --skip-github --skip-modrinth   # CurseForge only
```

#### Modrinth draft projects

While status is **Draft**, the project page may exist at `modrinth.com/project/<slug>` but `GET /v2/project/<slug>` returns **404** without a known ID. Set `MODRINTH_PROJECT_ID` in `.release.local`, then publish. After moderation approves the project, you can clear `MODRINTH_PROJECT_ID` and rely on slug resolution if you prefer.

#### Modrinth project metadata (`assets/`)

Before or during publish, `publish-release.sh` syncs [assets/modrinth.json](assets/modrinth.json) to the Modrinth API (description, license, links, categories, icon, gallery). Edit:

| File | Purpose |
|------|---------|
| `assets/modrinth.json` | Short description, license, URLs, categories, gallery list |
| `assets/modrinth-body.md` | Long description (project body) |
| `assets/icon.png` | Project icon (also used as featured gallery image by default) |

Sync metadata only (no JAR upload):

```bash
./scripts/release.sh publish --modrinth-sync-only
```

Set `"submit_for_review": true` in `modrinth.json` to send the project to Modrinth moderators on the next metadata sync (currently enabled in this repo).

#### Troubleshooting

| Symptom | Cause | Fix |
|---------|--------|-----|
| `Base62 decoding overflowed` | `MODRINTH_PROJECT_ID` set to display name instead of Base62 ID | Use the ID from Modrinth → Projects |
| `404` resolving Modrinth slug | Project is still in **Draft** | Set `MODRINTH_PROJECT_ID` |
| `403` / `API token is malformed` on CurseForge upload | Profile API key (`cfc_pat_`) used for file upload | Upload requires **Author API token** from [curseforge.com/account/api-tokens](https://www.curseforge.com/account/api-tokens) (`CURSEFORGE_AUTHOR_TOKEN`). Keep `cfc_pat_` as `CURSEFORGE_API_TOKEN` for version/project lookup only |
| `403` resolving CurseForge slug | Wrong or invalid **Profile API key** | Copy **Profile API key** from [console.curseforge.com/#/profile](https://console.curseforge.com/#/profile) (`cfc_pat_…`). Update `scripts/.release.local` and the GitHub `publish` environment. Optional: set `CURSEFORGE_PROJECT_ID` (numeric ID from the project page sidebar, e.g. `1257873`) |
| `EOF while parsing a string` (HTTP 400) | JSON metadata embedded in `curl -F` was truncated by the shell | Fixed in `publish-release.sh` (payload written to a temp file) |
| CI skips Modrinth/CurseForge on tag push | Secrets stored only at repository level, or wrong environment name | Use environment **`publish`** with the secrets below; workflow must set `environment: publish` |
| `404` resolving CurseForge game versions | Outdated API path (`/minecraft/game/version`) | Fixed in `publish-release.sh` — uses `/v1/minecraft/version/{mc}` and `/v1/minecraft/modloader/forge-{version}` |

See `scripts/.release.local.example` for all variables (`CURSEFORGE_API_TOKEN`, `MODRINTH_TOKEN`, `RELEASE_TYPE`, etc.).

### CI/CD (GitHub Actions)

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| [`.github/workflows/build.yml`](.github/workflows/build.yml) | Push and pull request | Job **lint** (Spotless + `-Werror`) y luego build + smoke **aislados** por loader |
| [`.github/workflows/release.yml`](.github/workflows/release.yml) | Tag push (`{mc}-{semver}`) | Build celdas enabled de esa línea MC y crea GitHub Release (3 JARs en 1.20.1; 2 JARs en 26.x) |
| [`.github/workflows/publish-distribution.yml`](.github/workflows/publish-distribution.yml) | Tag push (`*`) | Upload JARs to Modrinth/CurseForge and notify Discord (requires the `publish` environment) |

#### GitHub environment `publish`

Create **Settings → Environments → publish** (or use an existing environment with that name). The `publish-distribution` job sets `environment: publish` so it reads **environment** secrets and variables — not repository-level secrets.

**Environment secrets** (Settings → Environments → **publish** → Environment secrets):

| Secret | Required for | Where to get it |
|--------|--------------|-----------------|
| `MODRINTH_TOKEN` | Modrinth upload | [modrinth.com/settings/account](https://modrinth.com/settings/account) → Personal access tokens (`mrp_…`; needs version upload permission) |
| `MODRINTH_PROJECT_ID` | Modrinth while the project is in **Draft** (Base62 ID, e.g. `tFqJGW2q`) | [modrinth.com/dashboard/projects](https://modrinth.com/dashboard/projects) → column **ID** |
| `CURSEFORGE_API_TOKEN` | Resolve MC/Forge versions and project (Profile API key `cfc_pat_…`) | [console.curseforge.com/#/profile](https://console.curseforge.com/#/profile) |
| `CURSEFORGE_AUTHOR_TOKEN` | **Upload** mod files to CurseForge | [curseforge.com/account/api-tokens](https://www.curseforge.com/account/api-tokens) |
| `CURSEFORGE_PROJECT_ID` | Optional; numeric project ID if slug resolution fails | CurseForge project page sidebar |
| `DISCORD_WEBHOOK_URL` | Release notify to the mod’s Discord channel | Channel → Edit → Integrations → Webhooks → Copy URL (**Secret**, never a public Variable) |

**Environment variables** (same **publish** environment → Environment variables):

| Variable | Default | Purpose |
|----------|---------|---------|
| `MODRINTH_PROJECT_SLUG` | `consolefilternext` | Slug when `MODRINTH_PROJECT_ID` is empty and the project is public |
| `CURSEFORGE_PROJECT_SLUG` | `consolefilternext` | Resolve CurseForge project when `CURSEFORGE_PROJECT_ID` is empty |
| `RELEASE_TYPE` | `release` | Modrinth/CurseForge release channel (`release`, `beta`, `alpha`) |

Local publishes use the same names in `scripts/.release.local` (see `scripts/.release.local.example`).

If neither `MODRINTH_TOKEN` nor `CURSEFORGE_API_TOKEN` is set in the `publish` environment, the workflow skips upload steps with a notice (no failure). If `DISCORD_WEBHOOK_URL` is missing, publish still succeeds and skips the Discord notify with a warning.

## ⚠️ Known limitations (v4.2.0)

- Config hot-reload via `/consolefilter reload` or **Save & Apply** re-parses rules; filters must already be registered at startup.
- The in-game list editor paginates long lists (8 per page) but has no search yet.
- `modIdFilters` resolution depends on the loader mod list and logger/source names; edge cases may need `sourceFilters` instead.

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode) (CC BY-NC-SA 4.0). See [LICENSE.md](LICENSE.md) for attribution and terms.

Free to download on CurseForge and Modrinth; redistribution and derivatives must follow CC BY-NC-SA 4.0 (attribution, non-commercial, share-alike).

## Links

- [CurseForge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext) — [Forge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext/files?page=1&pageSize=20&version=1.20.1&gameVersionTypeId=1) · [Fabric](https://www.curseforge.com/minecraft/mc-mods/consolefilternext/files?page=1&pageSize=20&version=1.20.1&gameVersionTypeId=4) · [NeoForge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext/files?page=1&pageSize=20&version=1.20.1&gameVersionTypeId=6)
- [Modrinth](https://modrinth.com/mod/consolefilternext) — [Forge](https://modrinth.com/mod/consolefilternext/version/1CZFZaWj) · [Fabric](https://modrinth.com/mod/consolefilternext/version/JEPbwMU8) · [NeoForge](https://modrinth.com/mod/consolefilternext/version/EE1FzT7i)
- [GitHub repository](https://github.com/alanjmrt94/ConsoleFilterNext)
- [GitHub Release `1.20.1-4.2.0`](https://github.com/alanjmrt94/ConsoleFilterNext/releases/tag/1.20.1-4.2.0)
- [Report issues](https://github.com/alanjmrt94/ConsoleFilterNext/issues)
- [Discord](https://discord.gg/CcUNTJjPD)
- [ConsoleFilter by Matthew Czyr](https://github.com/MattCzyr/ConsoleFilter)
- [Migration guide](MIGRATION.md)
