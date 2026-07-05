# Console Filter Next

An improved ConsoleFilter mod that filters log messages not only by text, but also by log level (info, error, etc.). Gain better control over your console output to reduce noise and focus on what's important — ideal for debugging and error tracking. Fork of ConsoleFilter by [Matthew Czyr](https://github.com/MattCzyr).

[Downloads on CurseForge](https://minecraft.curseforge.com/projects/console-filter-next)

> **Developers:** run `./scripts/dev-env.sh` for environment setup, toolchain checks, and build configuration.

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

# Filters messages that contain specific text
basicFilters = ["Killed all storms"]

# Filters messages by their log level (e.g., INFO, WARN, ERROR, DEBUG)
levelFilters = ["INFO"]

# Filters messages coming from specific threads
threadFilters = ["Server thread"]

# Filters messages based on their source (usually class names or packages)
sourceFilters = ["net.minecraft.server.MinecraftServer"]

# Filters messages using regular expressions (advanced)
regexFilters = []
````

## 💡 Tips

Here are some useful examples to help you get started with advanced filtering:

### ✅ Filter all DEBUG messages

```toml
levelFilters = ["DEBUG"]
```

### ✅ Filter messages from a specific mod or package

```toml
sourceFilters = ["com.example.mymod"]
```

> **Note:** In v3.0.0, `sourceFilters` and `threadFilters` require an **exact** match. Substring/package-prefix matching is planned for v3.1.0.

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
| **Side** | Client and server (optional on both) |

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
./scripts/dev-env.sh verify   # check your setup
./gradlew build
```

The JAR is produced in `build/libs/`. Use `./scripts/dev-env.sh verify` if the build fails due to Java/Gradle mismatch.

**Tip:** use the interactive setup script:

```bash
./scripts/dev-env.sh
```

## ⚠️ Known limitations (v3.1.0)

- Config hot-reload reloads filter rules but requires filters to already be registered (restart if filters fail to apply on first launch).
- `sourceFilters` and `threadFilters` use exact string matching (not substring).

## License

[Creative Commons Attribution-NonCommercial ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode) — see [LICENSE.md](LICENSE.md).
