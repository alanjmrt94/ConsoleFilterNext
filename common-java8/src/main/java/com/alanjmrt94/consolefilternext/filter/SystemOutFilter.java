package com.alanjmrt94.consolefilternext.filter;

import java.io.PrintStream;

import com.alanjmrt94.consolefilternext.FilterHost;
import com.alanjmrt94.consolefilternext.LogMessage;

public class SystemOutFilter extends PrintStream implements CustomFilter {

	private final FilterHost host;

	public SystemOutFilter(FilterHost host) {
		super(System.out, true);
		this.host = host;
	}

	@Override
	public void applyFilter(FilterHost host) {
		System.setOut(this);
	}

	@Override
	public boolean shouldFilter(LogMessage message) {
		return host.getConfig().shouldFilter(message);
	}

	@Override
	public void println(String line) {
		if (!host.shouldFilterMessage(line)) {
			super.println(line);
		}
	}
}
