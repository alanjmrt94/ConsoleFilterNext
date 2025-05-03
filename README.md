# Console Filter Next

An enhanced version of ConsoleFilter (fork of ConsoleFilter by MattCzyr) that not only allows filtering log messages by text content, but also by their log level (e.g., info, error, and other specific types). This provides more precise control over what gets displayed in your console, helping you reduce noise and focus on the messages that matter most — for debugging and error management purposes.

[Downloads and more information on Curse](https://minecraft.curseforge.com/projects/console-filter-next)

---

## 🙌 Credits

- Original concept based on [ConsoleFilter](https://www.curseforge.com/minecraft/mc-mods/console-filter)
- Authors: **NgLoader**, **MarkKoz**, **ChaosTheDude**
- Extended and maintained by: **alanjmrt94**
- Licensed under: MIT License *(or specify your license)*

---

Crafted with ❤️ for modders who seek clarity in their debug, free from the chaos of unnecessary noise.

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
2. Open `consolefilter-common.toml`  
3. Edit the values according to your needs

For example, to filter all `INFO` messages from the `Server thread`, your `consolefilter-common.toml` should look like this:

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

## 💡 Tips

Here are some useful examples to help you get started with advanced filtering:

### ✅ Filter all DEBUG messages:
```toml
levelFilters = ["DEBUG"]
```

### ✅ Filter messages from a specific mod or package:
```toml
sourceFilters = ["com.example.mymod"]
```

### ✅ Filter log messages from a specific thread:
```toml
threadFilters = ["Render thread"]
```

### ✅ Filter messages that contain specific phrases:
```toml
basicFilters = ["Could not resolve", "Missing texture"]
```

### ✅ Use regular expressions to match patterns (advanced):
```toml
regexFilters = ["^\\[Render thread\\].*Missing.*$", ".*ERROR.*\\bBlockEntity\\b.*"]
```
> Note: Regex patterns must follow Java regular expression syntax.

---

You can combine multiple filters to fine-tune what gets shown in your console.  
If **any** of the conditions match, the message will be **filtered out**.

---

## 🧩 Compatibility

- **Minecraft Versions**: 1.20.1 
- **Mod Loaders**: Forge  
- **Platforms**: Client and Server compatible  


## License

This mod is available under the [Creative Commons Attribution-NonCommercial ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode).
