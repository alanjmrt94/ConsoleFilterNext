# Console Filter Next

An improved fork of [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) for Minecraft **Forge, Fabric, and NeoForge**. Filter console output by **text**, **regex**, **log level**, **thread**, **logger/source**, and **mod id** — not just plain text. Reduce noise on the client or dedicated server while debugging modpacks and development environments.

**Loaders:** Forge · Fabric · NeoForge (separate JAR per loader)  
**Discord:** [discord.gg/CcUNTJjPD](https://discord.gg/CcUNTJjPD) · **Issues:** [GitHub](https://github.com/alanjmrt94/ConsoleFilterNext/issues) · **Releases:** [GitHub Releases](https://github.com/alanjmrt94/ConsoleFilterNext/releases)

Install on **either or both sides** (optional on client and server): use it only where you read logs.

## Features

- **Filter types:** basic text, regex, log level, thread, logger/source, **mod id**
- **Profiles:** `default`, `debug`, `production` — switch in-game, via TOML, or `/consolefilter profile` (persisted)
- **Modes:** blacklist (hide matches) or **whitelist** (show only matches); optional `ignoreCase`
- **In-game editor** (Forge/NeoForge Mods → Config; Fabric Mod Menu): paginated lists, regex validation, presets, import/export
- **Commands** (OP 2): `reload`, `list`, `status`, `export`, `import`, `profile`
- **`filterLatestLog`** — apply filters to `latest.log` and other Log4j file appenders
- **`skipMessagesWithStackTrace`** — never hide lines with exceptions or stack traces
- **Statistics:** per-filter-type hit counts in `/consolefilter status`
- **Hot reload** from file, commands, or **Save & Apply** in the config UI

## Configuration

### In-game

1. Go to **Options → Mods**
2. Find **Console Filter Next**
3. Click **Config**
4. Edit filters and options; **Save & Apply** writes `consolefilternext-common.toml` and reloads filters

### Config file

Edit `config/consolefilternext-common.toml` in your instance folder.

Example — filter `INFO` messages from the `Server thread`:

```toml
[general]
activeProfile = "default"
ignoreCase = false
whitelistMode = false
filterLatestLog = true
skipMessagesWithStackTrace = false

basicFilters = []
levelFilters = ["INFO"]
threadFilters = ["Server thread"]
sourceFilters = []
modIdFilters = []
regexFilters = []
```

More examples (whitelist mode, mod id filters, profiles, regex): [README](https://github.com/alanjmrt94/ConsoleFilterNext#readme).

## Tips

**Filter all DEBUG messages**

```toml
levelFilters = ["DEBUG"]
```

**Filter messages from a specific package**

```toml
sourceFilters = ["com.example.mymod"]
```

**Whitelist mode** — show only matching messages

```toml
whitelistMode = true
basicFilters = ["ERROR", "WARN"]
```

If **any** filter matches, the message is **filtered out** (unless whitelist mode is enabled).

## Compatibility

Not every loader exists on every Minecraft version. Pick the file that matches your game + loader. Tags are `{mc}-4.2.0`.

- **1.8.9 / 1.12.2** — Forge · Legacy Fabric (Java 8; no in-game editor). On Modrinth the Fabric JARs are tagged **Legacy Fabric**.
- **1.16.1 / 1.16.5** — Forge · Fabric (Java 8)
- **1.19.2 / 1.19.4** — Forge · Fabric (Java 17; no in-game editor)
- **1.20.1 / 1.20.4 / 1.20.6** — Forge · Fabric · NeoForge
- **1.20.2 / 1.20.3** — Forge · Fabric
- **1.20.5** — Fabric
- **1.21.1 / 1.21.3–1.21.5 / 1.21.8 / 1.21.10 / 1.21.11** — Forge · Fabric · NeoForge
- **1.21.2** — Fabric
- **1.21.6 / 1.21.7 / 1.21.9** — Forge · Fabric
- **26.1 / 26.2** — Forge · Fabric · NeoForge (Java 25)
- **26.3** — Fabric · NeoForge (Java 25)

| | |
|---|---|
| **Java** | 8 (1.16 / 1.12.2 / 1.8.9) · 17 (1.19 / 1.20.1–1.20.4) · 21 (1.20.5+ / 1.21.x) · 25 (26.x) |
| **Side** | Client and dedicated server (optional on each) |

Migrating from the original ConsoleFilter? See [MIGRATION.md](https://github.com/alanjmrt94/ConsoleFilterNext/blob/master/MIGRATION.md).

## Support

| | |
|---|---|
| **Discord** | [discord.gg/CcUNTJjPD](https://discord.gg/CcUNTJjPD) |
| **Issues** | [GitHub Issues](https://github.com/alanjmrt94/ConsoleFilterNext/issues) |
| **Source** | [alanjmrt94/ConsoleFilterNext](https://github.com/alanjmrt94/ConsoleFilterNext) |
| **Releases** | [GitHub Releases](https://github.com/alanjmrt94/ConsoleFilterNext/releases) |

## Credits

| | |
|---|---|
| **Console Filter Next** | **alanjmrt94** |
| **Originally based on** | [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) by **Matthew Czyr** |
| **ConsoleFilter contributors** | **NgLoader**, **MarkKoz**, **ChaosTheDude** |
| **License** | [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) |

Crafted with ❤️ for modders who want a cleaner console.
