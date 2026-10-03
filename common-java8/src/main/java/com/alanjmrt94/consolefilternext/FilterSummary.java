package com.alanjmrt94.consolefilternext;

public final class FilterSummary {

	private final int basic;
	private final int regex;
	private final int level;
	private final int thread;
	private final int source;
	private final int modId;
	private final int total;
	private final String activeProfile;
	private final boolean ignoreCase;
	private final boolean whitelistMode;
	private final boolean filterLatestLog;
	private final boolean skipMessagesWithStackTrace;

	public FilterSummary(
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
		this.basic = basic;
		this.regex = regex;
		this.level = level;
		this.thread = thread;
		this.source = source;
		this.modId = modId;
		this.total = total;
		this.activeProfile = activeProfile;
		this.ignoreCase = ignoreCase;
		this.whitelistMode = whitelistMode;
		this.filterLatestLog = filterLatestLog;
		this.skipMessagesWithStackTrace = skipMessagesWithStackTrace;
	}

	public int basic() {
		return basic;
	}

	public int regex() {
		return regex;
	}

	public int level() {
		return level;
	}

	public int thread() {
		return thread;
	}

	public int source() {
		return source;
	}

	public int modId() {
		return modId;
	}

	public int total() {
		return total;
	}

	public String activeProfile() {
		return activeProfile;
	}

	public boolean ignoreCase() {
		return ignoreCase;
	}

	public boolean whitelistMode() {
		return whitelistMode;
	}

	public boolean filterLatestLog() {
		return filterLatestLog;
	}

	public boolean skipMessagesWithStackTrace() {
		return skipMessagesWithStackTrace;
	}
}
