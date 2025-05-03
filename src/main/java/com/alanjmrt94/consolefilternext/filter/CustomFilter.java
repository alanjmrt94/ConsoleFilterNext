package com.alanjmrt94.consolefilternext.filter;

import com.alanjmrt94.consolefilternext.ConsoleFilter;
import com.alanjmrt94.consolefilternext.LogMessage;

public interface CustomFilter {

	public void applyFilter(ConsoleFilter mod);

	boolean shouldFilter(LogMessage message);
}