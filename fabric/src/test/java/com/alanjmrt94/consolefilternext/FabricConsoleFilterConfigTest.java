package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class FabricConsoleFilterConfigTest {

	@TempDir
	Path tempDir;

	@Test
	void loadsDefaultsAndAppliesBasicFilter() throws Exception {
		Path configPath = tempDir.resolve("consolefilternext-common.toml");
		FabricConsoleFilterConfig config = new FabricConsoleFilterConfig();
		config.loadFrom(configPath);

		assertTrue(Files.exists(configPath));
		assertEquals(FabricConsoleFilterConfig.PROFILE_DEFAULT, config.getEffectiveProfile());
		assertEquals(0, config.filterCount());

		Files.writeString(configPath, """
			[general]
			activeProfile = "default"
			ignoreCase = false
			whitelistMode = false
			filterLatestLog = true
			skipMessagesWithStackTrace = false
			basicFilters = ["noise"]
			regexFilters = []
			levelFilters = []
			threadFilters = []
			sourceFilters = []
			loggerFilters = []
			modIdFilters = []
			""");
		config.reloadFromDisk();

		assertEquals(1, config.filterCount());
		assertTrue(config.shouldFilterPlain("this is noise"));
		assertFalse(config.shouldFilterPlain("clean line"));
	}

	@Test
	void debugProfileUsesProfileLists() throws Exception {
		Path configPath = tempDir.resolve("consolefilternext-common.toml");
		Files.writeString(configPath, """
			[general]
			activeProfile = "debug"
			ignoreCase = false
			whitelistMode = false
			filterLatestLog = true
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
			levelFilters = ["DEBUG"]
			threadFilters = []
			sourceFilters = []
			loggerFilters = []
			modIdFilters = []
			""");

		FabricConsoleFilterConfig config = new FabricConsoleFilterConfig();
		config.loadFrom(configPath);
		assertEquals(FabricConsoleFilterConfig.PROFILE_DEBUG, config.getEffectiveProfile());
		assertEquals(1, config.filterCount());
		assertEquals(List.of("DEBUG"), config.getEngine().getLists().levelFilters());
	}
}
