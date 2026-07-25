package com.alanjmrt94.consolefilternext;

public record FilterSummary(
	int basic,
	int regex,
	int level,
	int thread,
	int source,
	int modId,
	int total,
	String activeProfile,
	boolean ignoreCase,
	boolean whitelistMode,
	boolean filterLatestLog,
	boolean skipMessagesWithStackTrace
) {
}
