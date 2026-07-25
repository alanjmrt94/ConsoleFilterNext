package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class FilterEngineTest {

	@Test
	void blacklistModeHidesMatchingMessages() {
		assertTrue(FilterEngine.applyFilterMode(true, false));
		assertFalse(FilterEngine.applyFilterMode(false, false));
	}

	@Test
	void whitelistModeShowsOnlyMatchingMessages() {
		assertFalse(FilterEngine.applyFilterMode(true, true));
		assertTrue(FilterEngine.applyFilterMode(false, true));
	}
}
