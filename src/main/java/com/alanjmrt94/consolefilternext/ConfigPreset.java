package com.alanjmrt94.consolefilternext;

import java.util.Arrays;
import java.util.List;

public enum ConfigPreset {

	DEBUG(
		"Debug",
		"""
		[general]
		activeProfile = "debug"
		ignoreCase = false
		whitelistMode = false
		filterLatestLog = true
		skipMessagesWithStackTrace = true
		basicFilters = []
		regexFilters = []
		levelFilters = ["DEBUG"]
		threadFilters = []
		sourceFilters = []
		loggerFilters = []
		modIdFilters = []

		[profiles.debug]
		basicFilters = []
		regexFilters = []
		levelFilters = ["DEBUG"]
		threadFilters = []
		sourceFilters = []
		loggerFilters = []
		modIdFilters = []

		[profiles.production]
		basicFilters = []
		regexFilters = []
		levelFilters = ["WARN", "ERROR"]
		threadFilters = []
		sourceFilters = []
		loggerFilters = []
		modIdFilters = []
		"""
	),

	SILENT_MODPACK(
		"Silent modpack",
		"""
		[general]
		activeProfile = "production"
		ignoreCase = false
		whitelistMode = false
		filterLatestLog = true
		skipMessagesWithStackTrace = true
		basicFilters = ["Could not resolve", "Missing texture", "Unable to load"]
		regexFilters = []
		levelFilters = ["INFO", "DEBUG"]
		threadFilters = ["Render thread"]
		sourceFilters = []
		loggerFilters = []
		modIdFilters = []

		[profiles.debug]
		basicFilters = []
		regexFilters = []
		levelFilters = ["DEBUG"]
		threadFilters = []
		sourceFilters = []
		loggerFilters = []
		modIdFilters = []

		[profiles.production]
		basicFilters = ["Could not resolve", "Missing texture", "Unable to load"]
		regexFilters = []
		levelFilters = ["INFO", "DEBUG"]
		threadFilters = ["Render thread"]
		sourceFilters = []
		loggerFilters = []
		modIdFilters = []
		"""
	),

	MINIMAL(
		"Minimal",
		"""
		[general]
		activeProfile = "default"
		ignoreCase = false
		whitelistMode = false
		filterLatestLog = false
		skipMessagesWithStackTrace = false
		basicFilters = []
		regexFilters = []
		levelFilters = []
		threadFilters = []
		sourceFilters = []
		loggerFilters = []
		modIdFilters = []

		[profiles.debug]
		basicFilters = []
		regexFilters = []
		levelFilters = []
		threadFilters = []
		sourceFilters = []
		loggerFilters = []
		modIdFilters = []

		[profiles.production]
		basicFilters = []
		regexFilters = []
		levelFilters = []
		threadFilters = []
		sourceFilters = []
		loggerFilters = []
		modIdFilters = []
		"""
	);

	private final String label;
	private final String toml;

	ConfigPreset(String label, String toml) {
		this.label = label;
		this.toml = toml;
	}

	public String getLabel() {
		return label;
	}

	public String getToml() {
		return toml;
	}

	public static List<ConfigPreset> all() {
		return Arrays.asList(values());
	}

	public void apply(java.nio.file.Path configPath) throws java.io.IOException {
		ConfigFileHelper.applyPresetToml(configPath, toml);
	}
}
