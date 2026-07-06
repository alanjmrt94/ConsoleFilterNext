package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

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
	void tracksHitsByFilterType() {
		FilterStats stats = new FilterStats();
		stats.recordFiltered(FilterType.LEVEL);
		stats.recordFiltered(FilterType.LEVEL);
		stats.recordFiltered(FilterType.BASIC);

		assertEquals(3, stats.getFilteredCount());
		assertEquals(2, stats.getCount(FilterType.LEVEL));
		assertEquals(1, stats.getCount(FilterType.BASIC));
		assertEquals(0, stats.getCount(FilterType.REGEX));
	}

	@Test
	void resetClearsCounter() {
		FilterStats stats = new FilterStats();
		stats.recordFiltered(FilterType.THREAD);
		stats.reset();
		assertEquals(0, stats.getFilteredCount());
		assertEquals(0, stats.getCount(FilterType.THREAD));
	}
}
