package com.alanjmrt94.consolefilternext;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

import com.electronwill.nightconfig.core.file.CommentedFileConfig;

public final class ConfigFileHelper {

	private ConfigFileHelper() {
	}

	public static void exportConfig(Path source, Path target) throws IOException {
		if (!Files.exists(source)) {
			throw new IOException("Config file not found: " + source);
		}
		Path parent = target.getParent();
		if (parent != null) {
			Files.createDirectories(parent);
		}
		Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
	}

	public static void importConfig(Path source, Path target) throws IOException {
		if (!Files.exists(source)) {
			throw new IOException("Import file not found: " + source);
		}
		Path parent = target.getParent();
		if (parent != null) {
			Files.createDirectories(parent);
		}
		Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
	}

	public static void setActiveProfile(Path configPath, String profile) throws IOException {
		CommentedFileConfig config = CommentedFileConfig.builder(configPath).build();
		config.load();
		config.set("general.activeProfile", profile);
		config.save();
	}

	public static void applyPresetToml(Path configPath, String presetToml) throws IOException {
		Path temp = Files.createTempFile("consolefilter-preset-", ".toml");
		try {
			Files.writeString(temp, presetToml);
			importConfig(temp, configPath);
		} finally {
			Files.deleteIfExists(temp);
		}
	}
}
