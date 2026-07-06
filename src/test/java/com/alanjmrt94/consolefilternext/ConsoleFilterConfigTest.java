package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class ConsoleFilterConfigTest {

	@Test
	void blacklistModeHidesMatchingMessages() {
		assertTrue(ConsoleFilterConfig.applyFilterMode(true, false));
		assertFalse(ConsoleFilterConfig.applyFilterMode(false, false));
	}

	@Test
	void whitelistModeShowsOnlyMatchingMessages() {
		assertFalse(ConsoleFilterConfig.applyFilterMode(true, true));
		assertTrue(ConsoleFilterConfig.applyFilterMode(false, true));
	}
}
