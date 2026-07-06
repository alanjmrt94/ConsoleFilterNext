# Console Filter Next

Filter Minecraft console output by **text**, **regex**, **log level**, **thread**, **logger/source**, and **Forge mod id**. Reduce noise while debugging modpacks or running a dedicated server.

## Features

- **Profiles:** `default`, `debug`, `production` — switch in-game, via TOML, or `/consolefilter profile`
- **Blacklist or whitelist** modes with optional case-insensitive matching
- **In-game editor** (Options → Mods → Config): paginated lists, regex validation, import/export
- **Commands** (OP 2): `reload`, `list`, `status`, `export`, `import`, `profile`
- **`filterLatestLog`** — apply filters to `latest.log` and other file appenders
- **`skipMessagesWithStackTrace`** — never hide lines with exceptions or stack traces
- **Hot reload** from file, commands, or **Save & Apply** in the config UI

## Requirements

- Minecraft **1.20.1**
- **Forge 47+**
- Client and dedicated server

## Links

- [Source & issues](https://github.com/alanjmrt94/ConsoleFilterNext)
- [Migration from ConsoleFilter](https://github.com/alanjmrt94/ConsoleFilterNext/blob/master/MIGRATION.md)

Originally based on [ConsoleFilter](https://github.com/MattCzyr/ConsoleFilter) by Matthew Czyr. Maintained by alanjmrt94.
