package com.alanjmrt94.consolefilternext.client.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import com.alanjmrt94.consolefilternext.ConfigPreset;
import com.alanjmrt94.consolefilternext.ConsoleFilterConfig;

class ConfigEditorModelTest {

	@TempDir
	Path tempDir;

	@Test
	void roundTripTomlValues() throws Exception {
		Path configPath = tempDir.resolve("consolefilternext-common.toml");
		Files.writeString(configPath, """
			[general]
			activeProfile = "default"
			ignoreCase = true
			whitelistMode = false
			filterLatestLog = true
			skipMessagesWithStackTrace = true
			basicFilters = ["noise"]
			regexFilters = []
			levelFilters = ["INFO"]
			threadFilters = []
			sourceFilters = []
			loggerFilters = []
			modIdFilters = ["jei"]
			""");

		ConfigEditorModel model = ConfigEditorModel.load(configPath);
		assertTrue(model.isIgnoreCase());
		assertTrue(model.isSkipMessagesWithStackTrace());
		assertEquals(List.of("noise"), model.getFilterList("basicFilters"));
		assertEquals(List.of("jei"), model.getFilterList("modIdFilters"));

		model.setIgnoreCase(false);
		model.setFilterList("modIdFilters", List.of("create", "jei"));
		assertEquals(List.of("create", "jei"), model.getFilterList("modIdFilters"));
		model.save(configPath);

		ConfigEditorModel reloaded = ConfigEditorModel.load(configPath);
		assertFalse(reloaded.isIgnoreCase());
		assertEquals(List.of("create", "jei"), reloaded.getFilterList("modIdFilters"));
	}

	@Test
	void presetOverwritesConfigFile() throws Exception {
		Path configPath = tempDir.resolve("consolefilternext-common.toml");
		Files.writeString(configPath, "[general]\nactiveProfile = \"default\"\n");

		ConfigPreset.DEBUG.apply(configPath);
		ConfigEditorModel model = ConfigEditorModel.load(configPath);

		assertEquals(ConsoleFilterConfig.PROFILE_DEBUG, model.getActiveProfile());
		assertEquals(List.of("DEBUG"), model.getFilterList("levelFilters"));
	}

	@Test
	void profileListPathsResolveCorrectly() {
		assertEquals("general.basicFilters", ConfigEditorModel.resolveListPath("default", "basicFilters"));
		assertEquals("profiles.debug.basicFilters", ConfigEditorModel.resolveListPath("debug", "basicFilters"));
	}
}
