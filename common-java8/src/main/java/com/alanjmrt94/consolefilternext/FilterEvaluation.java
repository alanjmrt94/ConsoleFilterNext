package com.alanjmrt94.consolefilternext;

public final class FilterEvaluation {

	private final boolean filtered;
	private final FilterType matchType;

	public FilterEvaluation(boolean filtered, FilterType matchType) {
		this.filtered = filtered;
		this.matchType = matchType;
	}

	public static FilterEvaluation passThrough() {
		return new FilterEvaluation(false, null);
	}

	public boolean filtered() {
		return filtered;
	}

	public FilterType matchType() {
		return matchType;
	}
}
