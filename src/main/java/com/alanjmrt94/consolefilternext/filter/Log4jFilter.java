package com.alanjmrt94.consolefilternext.filter;

import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Marker;
import org.apache.logging.log4j.core.Filter;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.Logger;
import org.apache.logging.log4j.core.config.Node;
import org.apache.logging.log4j.core.config.plugins.Plugin;
import org.apache.logging.log4j.core.config.plugins.PluginFactory;
import org.apache.logging.log4j.message.Message;

import com.alanjmrt94.consolefilternext.ConsoleFilter;
import com.alanjmrt94.consolefilternext.ConsoleFilterConfig;
import com.alanjmrt94.consolefilternext.LogMessage;

@Plugin(name = "ConsoleFilter", category = Node.CATEGORY, elementType = Filter.ELEMENT_TYPE)
public class Log4jFilter implements Filter, CustomFilter {

	private final ConsoleFilter mod;
	private final ConsoleFilterConfig config;

	public Log4jFilter(ConsoleFilter mod) {
		this.mod = mod;
		config = mod.getConfig();
	}

	@Override
	public void applyFilter(ConsoleFilter mod) {
		((Logger) LogManager.getRootLogger()).addFilter(this);
	}

	@Override
	public boolean shouldFilter(LogMessage message) {
		return config.shouldFilter(message);
	}

	@Override
	public Result filter(LogEvent event) {
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
		return null;
	}

	@Override
	public void initialize() {
	}

	@Override
	public void start() {
	}

	@Override
	public void stop() {
	}

	@Override
	public boolean isStarted() {
		return false;
	}

	@Override
	public boolean isStopped() {
		return false;
	}

	@Override
	public Result getOnMismatch() {
		return null;
	}

	@Override
	public Result getOnMatch() {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String msg, Object... params) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0, Object p1) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0, Object p1, Object p2) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0, Object p1, Object p2,
			Object p3) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0, Object p1, Object p2,
			Object p3, Object p4) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0, Object p1, Object p2,
			Object p3, Object p4, Object p5) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0, Object p1, Object p2,
			Object p3, Object p4, Object p5, Object p6) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0, Object p1, Object p2,
			Object p3, Object p4, Object p5, Object p6, Object p7) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0, Object p1, Object p2,
			Object p3, Object p4, Object p5, Object p6, Object p7, Object p8) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, String message, Object p0, Object p1, Object p2,
			Object p3, Object p4, Object p5, Object p6, Object p7, Object p8, Object p9) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, Object msg, Throwable t) {
		return null;
	}

	@Override
	public Result filter(Logger logger, Level level, Marker marker, Message msg, Throwable t) {
		return null;
	}

	@PluginFactory
	public static Log4jFilter createFilter() {
		return new Log4jFilter(null);
	}
}