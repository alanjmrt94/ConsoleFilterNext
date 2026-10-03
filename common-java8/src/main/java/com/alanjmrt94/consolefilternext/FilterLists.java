package com.alanjmrt94.consolefilternext;

import java.util.Collections;
import java.util.List;

public final class FilterLists {

	public static final FilterLists EMPTY = new FilterLists(
		Collections.<String>emptyList(),
		Collections.<String>emptyList(),
		Collections.<String>emptyList(),
		Collections.<String>emptyList(),
		Collections.<String>emptyList(),
		Collections.<String>emptyList(),
		Collections.<String>emptyList()
	);

	private final List<String> basicFilters;
	private final List<String> regexFilters;
	private final List<String> levelFilters;
	private final List<String> threadFilters;
	private final List<String> sourceFilters;
	private final List<String> loggerFilters;
	private final List<String> modIdFilters;

	public FilterLists(
		List<String> basicFilters,
		List<String> regexFilters,
		List<String> levelFilters,
		List<String> threadFilters,
		List<String> sourceFilters,
		List<String> loggerFilters,
		List<String> modIdFilters
	) {
		this.basicFilters = basicFilters;
		this.regexFilters = regexFilters;
		this.levelFilters = levelFilters;
		this.threadFilters = threadFilters;
		this.sourceFilters = sourceFilters;
		this.loggerFilters = loggerFilters;
		this.modIdFilters = modIdFilters;
	}

	public List<String> basicFilters() {
		return basicFilters;
	}

	public List<String> regexFilters() {
		return regexFilters;
	}

	public List<String> levelFilters() {
		return levelFilters;
	}

	public List<String> threadFilters() {
		return threadFilters;
	}

	public List<String> sourceFilters() {
		return sourceFilters;
	}

	public List<String> loggerFilters() {
		return loggerFilters;
	}

	public List<String> modIdFilters() {
		return modIdFilters;
	}
}
