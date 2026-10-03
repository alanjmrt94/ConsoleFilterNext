package com.alanjmrt94.consolefilternext.filter;

import org.apache.logging.log4j.core.Appender;
import org.apache.logging.log4j.core.Logger;
import org.apache.logging.log4j.core.appender.ConsoleAppender;
import org.apache.logging.log4j.core.appender.FileAppender;
import org.apache.logging.log4j.core.filter.AbstractFilterable;

/**
 * Adjunta filtros a appenders en Log4j 2.0-beta9.
 */
public final class Log4jAppenderFilters {

	private Log4jAppenderFilters() {
	}

	public static void apply(Logger rootLogger, Log4jFilter filter, boolean filterLatestLog) {
		for (Appender appender : rootLogger.getAppenders().values()) {
			if (!shouldAttachFilter(appender, filterLatestLog)) {
				continue;
			}
			if (appender instanceof AbstractFilterable) {
				((AbstractFilterable) appender).addFilter(filter);
			}
		}
	}

	static boolean shouldAttachFilter(Appender appender, boolean filterLatestLog) {
		if (isConsoleAppender(appender)) {
			return true;
		}
		return filterLatestLog && isFileAppender(appender);
	}

	static boolean isConsoleAppender(Appender appender) {
		return appender instanceof ConsoleAppender
			|| appender.getClass().getSimpleName().toLowerCase().contains("console");
	}

	static boolean isFileAppender(Appender appender) {
		return appender instanceof FileAppender
			|| appender.getClass().getSimpleName().toLowerCase().contains("file");
	}
}
