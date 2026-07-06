package com.alanjmrt94.consolefilternext.filter;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.core.Filter;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.Logger;
import org.apache.logging.log4j.core.filter.AbstractFilter;

import com.alanjmrt94.consolefilternext.ConsoleFilter;
import com.alanjmrt94.consolefilternext.ConsoleFilterConfig;
import com.alanjmrt94.consolefilternext.LogMessage;

public class Log4jFilter extends AbstractFilter implements CustomFilter {

	private final ConsoleFilter mod;
	private final ConsoleFilterConfig config;

	public Log4jFilter(ConsoleFilter mod) {
		super(Result.NEUTRAL, Result.NEUTRAL);
		this.mod = mod;
		this.config = mod.getConfig();
	}

	@Override
	public void applyFilter(ConsoleFilter mod) {
		Logger root = (Logger) LogManager.getRootLogger();
		Log4jAppenderFilters.apply(root, this, config);
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
