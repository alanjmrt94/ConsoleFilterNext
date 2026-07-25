package com.alanjmrt94.consolefilternext;

public record FilterEvaluation(boolean filtered, FilterType matchType) {

	public static FilterEvaluation passThrough() {
		return new FilterEvaluation(false, null);
	}
}
