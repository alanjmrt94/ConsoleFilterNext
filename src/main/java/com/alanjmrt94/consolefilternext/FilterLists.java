package com.alanjmrt94.consolefilternext;

import java.util.Collections;
import java.util.List;

public record FilterLists(
	List<String> basicFilters,
	List<String> regexFilters,
	List<String> levelFilters,
	List<String> threadFilters,
	List<String> sourceFilters,
	List<String> loggerFilters
) {
	public static final FilterLists EMPTY = new FilterLists(
		Collections.emptyList(),
		Collections.emptyList(),
		Collections.emptyList(),
		Collections.emptyList(),
		Collections.emptyList(),
		Collections.emptyList()
	);
}
