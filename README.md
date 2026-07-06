# Console Filter Next

An improved ConsoleFilter mod that filters log messages not only by text, but also by log level (info, error, etc.). Gain better control over your console output to reduce noise and focus on what's important — ideal for debugging and error tracking. Fork of ConsoleFilter by [Matthew Czyr](https://github.com/MattCzyr).

[Downloads on CurseForge](https://minecraft.curseforge.com/projects/console-filter-next)

> **Developers:** run `./scripts/release.sh` for environment setup, toolchain checks, and build configuration.

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

1. Go to `Options -> Mod Options`
2. Find **ConsoleFilterNext**
3. Click on **Config**
4. From there, you can edit all filter options

### 🛠️ Editing the Configuration File

1. Go to the `config` folder in your Minecraft installation  
2. Open `consolefilternext-common.toml`  
3. Edit the values according to your needs

For example, to filter all `INFO` messages from the `Server thread`, your `consolefilternext-common.toml` should look like this:

````toml
[general]

ignoreCase = false
whitelistMode = false

# Filters messages that contain specific text
basicFilters = ["Killed all storms"]

# Filters messages by their log level (e.g., INFO, WARN, ERROR, DEBUG)
levelFilters = ["INFO"]

# Filters messages coming from specific threads
threadFilters = ["Server thread"]

# Filters messages based on their source (logger or class name). Matches when the source **contains** the string (package prefixes work).
sourceFilters = ["net.minecraft.server"]

# Filters messages using regular expressions (advanced)
regexFilters = []
````

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
threadFilters = ["Render thread"]
```

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

Applies to `basicFilters`, `threadFilters`, `sourceFilters`, and `regexFilters`. `levelFilters` are always case-insensitive.

### ✅ Reload filters without restarting

On a server with OP level 2+:

```
/consolefilter reload
/consolefilter list
/consolefilter status
```

`reload` re-reads `consolefilternext-common.toml` from disk. `status` shows active filter count and how many messages have been hidden.

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

## ⚠️ Known limitations (v3.3.0)

- Config hot-reload via `/consolefilter reload` re-parses filter rules; filters must already be registered at startup.
- `threadFilters` still require an exact thread name match unless `ignoreCase = true` (still exact string, not substring).

## License

[Creative Commons Attribution-NonCommercial ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode) — see [LICENSE.md](LICENSE.md).
