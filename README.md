# Console Filter Next

An improved ConsoleFilter mod that filters log messages not only by text, but also by log level, thread, source, mod id, and regex. Reduce console noise on the client or dedicated server while debugging modpacks and development environments. Fork of ConsoleFilter by [Matthew Czyr](https://github.com/MattCzyr).

**Current release:** `1.20.1-4.0.1` · Minecraft **1.20.1** · **Forge 47+** · Client & dedicated server

## Downloads

| Platform | Link |
|----------|------|
| **CurseForge** | [consolefilternext](https://www.curseforge.com/minecraft/mc-mods/consolefilternext) |
| **Modrinth** | [consolefilternext](https://modrinth.com/mod/consolefilternext) |
| **Source & issues** | [GitHub](https://github.com/alanjmrt94/ConsoleFilterNext) |

> **Developers:** run `./scripts/release.sh` for environment setup, builds, and publishing (GitHub + CurseForge + Modrinth).

---

## Features

- **Filter types:** basic text, regex, log level, thread, logger/source, Forge **mod id**
- **Profiles:** `default`, `debug`, `production` — switch in-game, via TOML, or `/consolefilter profile` (persisted)
- **Modes:** blacklist (hide matches) or **whitelist** (show only matches); optional `ignoreCase`
- **`filterLatestLog`:** apply filters to `latest.log` and other Log4j file appenders
- **`skipMessagesWithStackTrace`:** never hide lines with exceptions or stack traces
- **In-game editor** (Forge Mod List → Config): paginated lists, regex validation, presets, import/export
- **Commands** (OP 2): `reload`, `list`, `status`, `export`, `import`, `profile`
- **Statistics:** per-filter-type hit counts in `/consolefilter status`
- **Hot reload** from file, commands, or **Save & Apply** in the config UI

---

## 🙌 Credits & lineage

| | |
|---|---|
| **Original project** | [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) — created and maintained by **Matthew Czyr** ([MattCzyr](https://github.com/MattCzyr)) |
| **Original contributors** | **NgLoader**, **MarkKoz**, **ChaosTheDude** |
| **This fork** | **Console Filter Next** — forked and extended by **alanjmrt94** |
| **License** | [CC BY-NC-SA 4.0](LICENSE.md) (same as upstream) |

Console Filter Next is **not** the official ConsoleFilter project. It is an independent fork with extra features and a separate release track. Please report issues for this fork on [this repository](https://github.com/alanjmrt94/ConsoleFilterNext/issues); for the original mod, use [MattCzyr/ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter/issues).

---

Crafted with ❤️ for modders who want a cleaner console.

## ⚙️ Config

The actual configuration of the mod is done in a separate file generated at runtime.  
To configure the mod, you have two options:

### 🕹️ In-Game

1. Go to **Options → Mods**
2. Find **Console Filter Next**
3. Click **Config**
4. Edit booleans, profiles, and filter lists; use **Save & Apply** to write `consolefilternext-common.toml` and reload filters

No extra mods required — uses Forge's built-in Mod List config button.

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

### ✅ In-game config (Forge)

- **Options → Mods → Console Filter Next → Config** — edit booleans, profiles, and all filter lists
- Paginated list editor (8 entries per page) with **regex validation** for `regexFilters`
- **Presets** (Debug, Silent modpack, Minimal), **Import…** / **Export…** from the config screen
- **Save & Apply** writes the TOML file and reloads filters without restarting

> [Mod Menu](https://modrinth.com/mod/modmenu) is **Fabric-only**. This Forge mod uses the native Mod List Config button (no dependencies).

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
| **Minecraft** | 1.20.1 |
| **Mod loader** | Forge 47+ |
| **Java (runtime)** | 17 (bundled with Minecraft) |
| **Side** | **Client and dedicated server** — install on either or both; filters apply on both sides |
| **Downloads** | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext) · [Modrinth](https://modrinth.com/mod/consolefilternext) |

## 🛠️ Building from source

**Requirements:** The mod targets **Java 17 bytecode** (MC 1.20.1). For running Gradle:

| Launcher JDK | Status |
|--------------|--------|
| **Java 17** | Recommended (official Forge guidance) |
| **Java 21** | Supported alternative — builds successfully in this project |
| **Java 25** | Requires Gradle 8.14.3+ as launcher |

```bash
git clone https://github.com/alanjmrt94/ConsoleFilterNext.git
cd ConsoleFilterNext
./scripts/release.sh verify   # check your setup
./gradlew build
```

The JAR is produced in `build/libs/`. Use `./scripts/release.sh verify` if the build fails due to Java/Gradle mismatch.

### Local development runs (client and server)

The mod is verified for **both** client and dedicated server. Use Gradle from the project root:

| Command | Purpose |
|---------|---------|
| `./gradlew runClient` | Launch the Minecraft **client** with the mod in `run/mods/` |
| `./gradlew runServer` | Launch a local **dedicated server** (auto-accepts EULA via `run/eula.txt`) |

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

See `scripts/.release.local.example` for `CURSEFORGE_API_TOKEN`, `MODRINTH_TOKEN`, and project slugs.

## ⚠️ Known limitations (v4.0.1)

- Config hot-reload via `/consolefilter reload` or **Save & Apply** re-parses rules; filters must already be registered at startup.
- The in-game list editor paginates long lists (8 per page) but has no search yet.
- `modIdFilters` resolution depends on Forge `ModList` and logger/source names; edge cases may need `sourceFilters` instead.

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode) (CC BY-NC-SA 4.0) — same as upstream ConsoleFilter. See [LICENSE.md](LICENSE.md) for attribution and terms.

Free to download on CurseForge and Modrinth; redistribution and derivatives must follow CC BY-NC-SA 4.0 (attribution, non-commercial, share-alike).

## Links

- [CurseForge](https://www.curseforge.com/minecraft/mc-mods/consolefilternext)
- [Modrinth](https://modrinth.com/mod/consolefilternext)
- [GitHub repository](https://github.com/alanjmrt94/ConsoleFilterNext)
- [Report issues (this fork)](https://github.com/alanjmrt94/ConsoleFilterNext/issues)
- [Original ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter)
- [Migration guide](MIGRATION.md)
