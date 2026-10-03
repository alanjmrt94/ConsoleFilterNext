package com.alanjmrt94.consolefilternext.filter;

import java.io.PrintStream;

import com.alanjmrt94.consolefilternext.FilterHost;
import com.alanjmrt94.consolefilternext.LogMessage;

public class SystemErrFilter extends PrintStream implements CustomFilter {

	private final FilterHost host;

	public SystemErrFilter(FilterHost host) {
		super(System.err, true);
		this.host = host;
	}

	@Override
	public void applyFilter(FilterHost host) {
		System.setErr(this);
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
