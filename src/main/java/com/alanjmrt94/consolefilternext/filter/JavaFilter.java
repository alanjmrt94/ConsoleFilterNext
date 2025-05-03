package com.alanjmrt94.consolefilternext.filter;

import java.util.logging.Filter;
import java.util.logging.LogRecord;
import java.util.logging.Logger;

import com.alanjmrt94.consolefilternext.ConsoleFilter;
import com.alanjmrt94.consolefilternext.ConsoleFilterConfig;

public class JavaFilter implements CustomFilter, Filter {

	private final ConsoleFilterConfig config;

	public JavaFilter(ConsoleFilter mod) {
		config = mod.getConfig();
	}

	@Override
	public void applyFilter(ConsoleFilter mod) {
		Logger.getLogger("").setFilter(this);
	}

	@Override
	public boolean isLoggable(LogRecord record) {
		return !config.shouldFilter(record.getMessage());
	}
}