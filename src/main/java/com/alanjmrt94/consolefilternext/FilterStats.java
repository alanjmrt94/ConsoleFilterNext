package com.alanjmrt94.consolefilternext;

import java.util.concurrent.atomic.AtomicLong;

public final class FilterStats {

	private final AtomicLong filteredCount = new AtomicLong();

	public void recordFiltered() {
		filteredCount.incrementAndGet();
	}

	public long getFilteredCount() {
		return filteredCount.get();
	}

	public void reset() {
		filteredCount.set(0);
	}
}
