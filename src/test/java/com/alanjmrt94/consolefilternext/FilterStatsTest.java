package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class FilterStatsTest {

	@Test
	void tracksFilteredMessages() {
		FilterStats stats = new FilterStats();
		assertEquals(0, stats.getFilteredCount());

		stats.recordFiltered();
		stats.recordFiltered();

		assertEquals(2, stats.getFilteredCount());
	}

	@Test
	void resetClearsCounter() {
		FilterStats stats = new FilterStats();
		stats.recordFiltered();
		stats.reset();
		assertEquals(0, stats.getFilteredCount());
	}
}
