package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class NeoForgeConsoleFilterConfigTest {

	@TempDir
	Path tempDir;

	@Test
	void loadsDefaultsAndAppliesBasicFilter() throws Exception {
		Path configPath = tempDir.resolve("consolefilternext-common.toml");
		NeoForgeConsoleFilterConfig config = new NeoForgeConsoleFilterConfig();
		config.loadFrom(configPath);

		assertTrue(Files.exists(configPath));
		assertEquals(NeoForgeConsoleFilterConfig.PROFILE_DEFAULT, config.getEffectiveProfile());
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
}
