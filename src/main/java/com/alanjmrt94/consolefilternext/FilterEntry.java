package com.alanjmrt94.consolefilternext;

import java.util.regex.Pattern;

public interface FilterEntry {

	public static FilterEntry regex(Pattern pattern) {
		return message -> pattern.matcher(message.getFullMessage()).find();
	}

	public static FilterEntry regex(String regex) {
		return regex(Pattern.compile(regex));
	}

	public static FilterEntry wildcard(String wildcard) {
		return message -> message.getFullMessage().contains(wildcard);
	}

	public static FilterEntry level(String level) {
		return message -> message.getLevel().equalsIgnoreCase(level);
	}

	public static FilterEntry thread(String thread) {
		return message -> message.getThread().equals(thread);
	}

	public static FilterEntry source(String source) {
		return message -> message.getSource() != null && message.getSource().contains(source);
	}

	boolean shouldFilter(LogMessage message);
}
