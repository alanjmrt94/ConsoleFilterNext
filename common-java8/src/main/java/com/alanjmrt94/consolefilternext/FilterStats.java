package com.alanjmrt94.consolefilternext;

import java.util.EnumMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

public final class FilterStats {

	private final AtomicLong filteredCount = new AtomicLong();
	private final EnumMap<FilterType, AtomicLong> countsByType = new EnumMap<>(FilterType.class);

	public FilterStats() {
		for (FilterType type : FilterType.values()) {
			countsByType.put(type, new AtomicLong());
		}
	}

	public void recordFiltered(FilterType type) {
		filteredCount.incrementAndGet();
		countsByType.get(type).incrementAndGet();
	}

	public void recordFiltered() {
		filteredCount.incrementAndGet();
	}

	public long getFilteredCount() {
		return filteredCount.get();
	}

	public long getCount(FilterType type) {
		return countsByType.get(type).get();
	}

	public Map<FilterType, Long> snapshotByType() {
		EnumMap<FilterType, Long> snapshot = new EnumMap<>(FilterType.class);
		for (FilterType type : FilterType.values()) {
			snapshot.put(type, countsByType.get(type).get());
		}
		return snapshot;
	}

	public void reset() {
		filteredCount.set(0);
		for (AtomicLong counter : countsByType.values()) {
			counter.set(0);
		}
	}
}
