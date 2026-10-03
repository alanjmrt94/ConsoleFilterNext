package com.alanjmrt94.consolefilternext.filter;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.Logger;
import org.apache.logging.log4j.core.filter.AbstractFilter;

import com.alanjmrt94.consolefilternext.FilterConfigView;
import com.alanjmrt94.consolefilternext.FilterHost;
import com.alanjmrt94.consolefilternext.LogMessage;

public class Log4jFilter extends AbstractFilter implements CustomFilter {

	private final FilterHost host;
	private final FilterConfigView config;

	public Log4jFilter(FilterHost host) {
		super(Result.NEUTRAL, Result.NEUTRAL);
		this.host = host;
		this.config = host.getConfig();
	}

	@Override
	public void applyFilter(FilterHost host) {
		Logger root = (Logger) LogManager.getRootLogger();
		Log4jAppenderFilters.apply(root, this, config.isFilterLatestLog());
	}

	@Override
	public boolean shouldFilter(LogMessage message) {
		return config.shouldFilter(message);
	}

	@Override
	public Result filter(LogEvent event) {
		if (config.isSkipMessagesWithStackTrace() && event.getThrown() != null) {
			return Result.NEUTRAL;
		}

		LogMessage logMessage = new LogMessage(
			event.getTimeMillis() + "",
			event.getThreadName(),
			event.getLevel().name(),
			event.getLoggerName(),
			event.getMessage().getFormattedMessage()
		);
		return shouldFilter(logMessage) ? Result.DENY : Result.NEUTRAL;
	}

	@Override
	public State getState() {
		return State.INITIALIZED;
	}
}
