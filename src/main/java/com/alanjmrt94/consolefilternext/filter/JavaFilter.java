package com.alanjmrt94.consolefilternext.filter;

import java.util.logging.Filter;
import java.util.logging.LogRecord;

import com.alanjmrt94.consolefilternext.ConsoleFilter;
import com.alanjmrt94.consolefilternext.LogMessage;

public class JavaFilter implements Filter, CustomFilter {
	private final ConsoleFilter mod;

	public JavaFilter(ConsoleFilter mod) {
		this.mod = mod;
	}

	@Override
	public void applyFilter(ConsoleFilter mod) {
		java.util.logging.Logger.getLogger("").setFilter(this);
	}

	@Override
	public boolean shouldFilter(LogMessage message) {
		return mod.getConfig().shouldFilter(message);
	}

	@Override
	public boolean isLoggable(LogRecord record) {
		LogMessage logMessage = new LogMessage(
			record.getMillis() + "",
			record.getThreadID() + "",
			record.getLevel().getName(),
			record.getLoggerName(),
			record.getMessage()
		);
		return !shouldFilter(logMessage);
	}
}