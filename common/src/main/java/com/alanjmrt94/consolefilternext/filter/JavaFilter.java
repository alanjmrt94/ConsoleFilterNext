package com.alanjmrt94.consolefilternext.filter;

import java.util.logging.Filter;
import java.util.logging.LogRecord;

import com.alanjmrt94.consolefilternext.FilterHost;
import com.alanjmrt94.consolefilternext.LogMessage;

public class JavaFilter implements Filter, CustomFilter {

	private final FilterHost host;

	public JavaFilter(FilterHost host) {
		this.host = host;
	}

	@Override
	public void applyFilter(FilterHost host) {
		java.util.logging.Logger.getLogger("").setFilter(this);
	}

	@Override
	public boolean shouldFilter(LogMessage message) {
		return host.getConfig().shouldFilter(message);
	}

	@Override
	public boolean isLoggable(LogRecord record) {
		LogMessage logMessage = new LogMessage(
			record.getMillis() + "",
			Long.toString(record.getLongThreadID()),
			record.getLevel().getName(),
			record.getLoggerName(),
			record.getMessage()
		);
		return !shouldFilter(logMessage);
	}
}
