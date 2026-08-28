# Console Filter Next

An improved ConsoleFilter mod for **Forge, Fabric, and NeoForge** that filters log messages by text, regex, log level, thread, source, and mod id. Reduce console noise and focus on what matters — ideal for debugging modpacks and dedicated servers.

Works on the **client and dedicated server** (optional on each side). Download the JAR for your loader (`*-forge`, `*-fabric`, or `*-neoforge`). Do not mix loaders.

## Links

- **Discord:** https://discord.gg/CcUNTJjPD
- **Issues / source:** https://github.com/alanjmrt94/ConsoleFilterNext
- **Modrinth:** https://modrinth.com/mod/consolefilternext

## Features

- Filter types: text, regex, level, thread, source, mod id
- Profiles: default, debug, production
- Blacklist or whitelist mode; in-game config editor
- Commands: reload, list, status, export, import, profile
- Optional filtering of `latest.log` / Log4j file appenders
- Never hide stack traces when `skipMessagesWithStackTrace` is enabled

## Compatibility

- Minecraft **1.20.1** — Forge · Fabric · NeoForge (Java 17)
- Minecraft **26.1** / **26.2** — Fabric · NeoForge (Java 25)
- Un solo proyecto; cada archivo/versión indica MC + loader. Mismo `mod_semver` en tags `{mc}-{semver}`.

## Credits

- **Console Filter Next:** alanjmrt94
- Originally based on ConsoleFilter by Matthew Czyr
- License: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
