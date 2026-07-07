# Console Filter Next

An improved fork of [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) for Minecraft Forge. Filter console output by **text**, **regex**, **log level**, **thread**, **logger/source**, and **Forge mod id** — not just plain text. Reduce noise on the client or dedicated server while debugging modpacks and development environments.

Install on **either or both sides** (optional on client and server): use it only where you read logs.

## Features

- **Filter types:** basic text, regex, log level, thread, logger/source, Forge **mod id**
- **Profiles:** `default`, `debug`, `production` — switch in-game, via TOML, or `/consolefilter profile` (persisted)
- **Modes:** blacklist (hide matches) or **whitelist** (show only matches); optional `ignoreCase`
- **In-game editor** (Options → Mods → Config): paginated lists, regex validation, presets, import/export
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

| | |
|---|---|
| **Minecraft** | 1.20.1 |
| **Mod loader** | Forge 47+ |
| **Java** | 17 or 21 (launcher; mod bytecode targets Java 17) |
| **Side** | Client and dedicated server (optional on each) |

Migrating from the original ConsoleFilter? See [MIGRATION.md](https://github.com/alanjmrt94/ConsoleFilterNext/blob/master/MIGRATION.md).

## Credits

| | |
|---|---|
| **Console Filter Next** | **alanjmrt94** |
| **Originally based on** | [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) by **Matthew Czyr** |
| **ConsoleFilter contributors** | **NgLoader**, **MarkKoz**, **ChaosTheDude** |
| **License** | [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) |

Crafted with ❤️ for modders who want a cleaner console.
