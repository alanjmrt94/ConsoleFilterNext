package com.alanjmrt94.consolefilternext;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

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
}
