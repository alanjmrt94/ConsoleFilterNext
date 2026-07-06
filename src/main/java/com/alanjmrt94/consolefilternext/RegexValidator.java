package com.alanjmrt94.consolefilternext;

import java.util.Locale;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

public final class RegexValidator {

	private RegexValidator() {
	}

	public static Optional<String> validate(String pattern, boolean ignoreCase) {
		if (pattern == null || pattern.isBlank()) {
			return Optional.empty();
		}
		try {
			int flags = ignoreCase ? Pattern.CASE_INSENSITIVE : 0;
			Pattern.compile(pattern, flags);
			return Optional.empty();
		} catch (PatternSyntaxException exception) {
			return Optional.of(exception.getDescription());
		}
	}

	public static boolean isValid(String pattern, boolean ignoreCase) {
		return validate(pattern, ignoreCase).isEmpty();
	}

	public static String describeError(String pattern, boolean ignoreCase) {
		return validate(pattern, ignoreCase).orElse("");
	}
}
