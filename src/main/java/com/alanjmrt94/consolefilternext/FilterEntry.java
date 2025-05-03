package com.alanjmrt94.consolefilternext;

import java.util.regex.Pattern;

public interface FilterEntry {

	public static FilterEntry regex(String regex) {
		Pattern pattern = Pattern.compile(regex);
		return message -> pattern.matcher(message.getFullMessage()).matches();
	}

	public static FilterEntry wildcard(String wildcard) {
		return message -> message.getFullMessage().contains(wildcard);
	}

	public static FilterEntry level(String level) {
		return message -> message.getLevel().equals(level);
	}

	public static FilterEntry thread(String thread) {
		return message -> message.getThread().equals(thread);
	}

	public static FilterEntry source(String source) {
		return message -> message.getSource().equals(source);
	}

	boolean shouldFilter(LogMessage message);
}
