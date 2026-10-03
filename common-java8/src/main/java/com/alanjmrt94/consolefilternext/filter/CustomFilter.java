package com.alanjmrt94.consolefilternext.filter;

import com.alanjmrt94.consolefilternext.FilterHost;
import com.alanjmrt94.consolefilternext.LogMessage;

public interface CustomFilter {

	void applyFilter(FilterHost host);

	boolean shouldFilter(LogMessage message);
}
