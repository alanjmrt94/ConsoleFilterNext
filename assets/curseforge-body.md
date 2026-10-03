# Console Filter Next

An improved ConsoleFilter mod for **Forge, Fabric, and NeoForge** that filters log messages by text, regex, log level, thread, source, and mod id. Reduce console noise and focus on what matters — ideal for debugging modpacks and dedicated servers.

Works on the **client and dedicated server** (optional on each side). Download the JAR for your loader (`*-forge`, `*-fabric`, or `*-neoforge`). Do not mix loaders. Each file is Minecraft + loader; tags are `{mc}-4.2.0`.

## Links

- **Discord:** https://discord.gg/CcUNTJjPD
- **Issues / source:** https://github.com/alanjmrt94/ConsoleFilterNext
- **Releases:** https://github.com/alanjmrt94/ConsoleFilterNext/releases
- **Modrinth:** https://modrinth.com/mod/consolefilternext

## Features

- Filter types: text, regex, level, thread, source, mod id
- Profiles: default, debug, production
- Blacklist or whitelist mode; in-game config editor (modern lines)
- Commands: reload, list, status, export, import, profile
- Optional filtering of `latest.log` / Log4j file appenders
- Never hide stack traces when `skipMessagesWithStackTrace` is enabled

## Compatibility

Not every loader exists on every Minecraft version. Pick the file that matches your game + loader.

- **1.8.9 / 1.12.2** — Forge · Fabric (Java 8; no in-game editor)
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
- One CurseForge project. Same `mod_semver` (`4.2.0`) on every `{mc}-{semver}` tag.

## Credits

- **Console Filter Next:** alanjmrt94
- Originally based on ConsoleFilter by Matthew Czyr
- License: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
