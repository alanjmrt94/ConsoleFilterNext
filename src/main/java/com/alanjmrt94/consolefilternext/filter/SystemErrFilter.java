package com.alanjmrt94.consolefilternext.filter;

import java.io.PrintStream;

import com.alanjmrt94.consolefilternext.ConsoleFilter;
import com.alanjmrt94.consolefilternext.LogMessage;

public class SystemErrFilter extends PrintStream implements CustomFilter {

	private final ConsoleFilter mod;

	public SystemErrFilter(ConsoleFilter mod) {
		super(System.err, true);
		this.mod = mod;
	}

	@Override
	public void applyFilter(ConsoleFilter mod) {
		System.setErr(this);
	}

	@Override
	public boolean shouldFilter(LogMessage message) {
		return mod.getConfig().shouldFilter(message);
	}

	@Override
	public void println(String line) {
		if (!mod.shouldFilterMessage(line)) {
			super.println(line);
		}
	}
}
