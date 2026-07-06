package com.alanjmrt94.consolefilternext;

import java.util.Locale;
import java.util.regex.Pattern;

public interface FilterEntry {

	public static FilterEntry regex(Pattern pattern) {
		return message -> pattern.matcher(message.getFullMessage()).find();
	}

	public static FilterEntry regex(String regex, boolean ignoreCase) {
		int flags = ignoreCase ? Pattern.CASE_INSENSITIVE : 0;
		return regex(Pattern.compile(regex, flags));
	}

	public static FilterEntry wildcard(String wildcard, boolean ignoreCase) {
		if (ignoreCase) {
			String needle = wildcard.toLowerCase(Locale.ROOT);
			return message -> message.getFullMessage().toLowerCase(Locale.ROOT).contains(needle);
		}
		return message -> message.getFullMessage().contains(wildcard);
	}

	public static FilterEntry level(String level) {
		return message -> message.getLevel().equalsIgnoreCase(level);
	}

	public static FilterEntry thread(String thread, boolean ignoreCase) {
		if (ignoreCase) {
			return message -> message.getThread().equalsIgnoreCase(thread);
		}
		return message -> message.getThread().equals(thread);
	}

	public static FilterEntry source(String source, boolean ignoreCase) {
		if (ignoreCase) {
			String needle = source.toLowerCase(Locale.ROOT);
			return message -> message.getSource() != null
				&& message.getSource().toLowerCase(Locale.ROOT).contains(needle);
		}
		return message -> message.getSource() != null && message.getSource().contains(source);
	}

	boolean shouldFilter(LogMessage message);
}
