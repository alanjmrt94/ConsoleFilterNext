package com.alanjmrt94.consolefilternext;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

/**
 * Motor de evaluación de filtros independiente del loader.
 */
public final class FilterEngine implements FilterConfigView {

	private final List<ActiveFilter> filterList = new ArrayList<>();
	private final List<Pattern> compiledRegexPatterns = new ArrayList<>();
	private final List<FilterType> compiledRegexTypes = new ArrayList<>();

	private FilterLists lists = FilterLists.EMPTY;
	private boolean ignoreCase;
	private boolean whitelistMode;
	private boolean filterLatestLog = true;
	private boolean skipMessagesWithStackTrace;
	private String activeProfile = "default";

	public void reload(
			FilterLists lists,
			boolean ignoreCase,
			boolean whitelistMode,
			boolean filterLatestLog,
			boolean skipMessagesWithStackTrace,
			String activeProfile) {
		this.lists = lists != null ? lists : FilterLists.EMPTY;
		this.ignoreCase = ignoreCase;
		this.whitelistMode = whitelistMode;
		this.filterLatestLog = filterLatestLog;
		this.skipMessagesWithStackTrace = skipMessagesWithStackTrace;
		this.activeProfile = activeProfile == null || activeProfile.isBlank() ? "default" : activeProfile;
		rebuild();
	}

	private void rebuild() {
		filterList.clear();
		compiledRegexPatterns.clear();
		compiledRegexTypes.clear();

		for (String entry : lists.basicFilters()) {
			if (!entry.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.BASIC, FilterEntry.wildcard(entry, ignoreCase)));
			}
		}

		for (String entry : lists.regexFilters()) {
			if (!entry.isEmpty()) {
				try {
					int flags = ignoreCase ? Pattern.CASE_INSENSITIVE : 0;
					Pattern pattern = Pattern.compile(entry, flags);
					compiledRegexPatterns.add(pattern);
					compiledRegexTypes.add(FilterType.REGEX);
					filterList.add(new ActiveFilter(FilterType.REGEX, FilterEntry.regex(pattern)));
				} catch (PatternSyntaxException ignored) {
					// Expresión inválida en config; se omite
				}
			}
		}

		for (String level : lists.levelFilters()) {
			if (!level.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.LEVEL, FilterEntry.level(level)));
			}
		}

		for (String thread : lists.threadFilters()) {
			if (!thread.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.THREAD, FilterEntry.thread(thread, ignoreCase)));
			}
		}

		for (String source : lists.sourceFilters()) {
			if (!source.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.SOURCE, FilterEntry.source(source, ignoreCase)));
			}
		}

		for (String logger : lists.loggerFilters()) {
			if (!logger.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.LOGGER, FilterEntry.logger(logger, ignoreCase)));
			}
		}

		for (String modId : lists.modIdFilters()) {
			if (!modId.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.MOD_ID, FilterEntry.modId(modId)));
			}
		}
	}

	@Override
	public FilterEvaluation evaluate(LogMessage message) {
		if (skipMessagesWithStackTrace && message.hasStackTraceHint()) {
			return FilterEvaluation.passThrough();
		}

		Optional<FilterType> matchType = findMatchingFilter(message);
		boolean matches = matchType.isPresent();
		boolean filtered = applyFilterMode(matches, whitelistMode);
		return new FilterEvaluation(filtered, matchType.orElse(null));
	}

	@Override
	public boolean shouldFilter(LogMessage message) {
		return evaluate(message).filtered();
	}

	@Override
	public FilterEvaluation evaluatePlain(String text) {
		if (text == null || text.isEmpty()) {
			return new FilterEvaluation(applyFilterMode(false, whitelistMode), null);
		}

		if (skipMessagesWithStackTrace && StackTraceDetector.looksLikeStackTrace(text)) {
			return FilterEvaluation.passThrough();
		}

		boolean matches = false;
		FilterType matchType = null;

		for (String entry : lists.basicFilters()) {
			if (entry.isEmpty()) {
				continue;
			}
			if (ignoreCase) {
				if (text.toLowerCase(Locale.ROOT).contains(entry.toLowerCase(Locale.ROOT))) {
					matches = true;
					matchType = FilterType.BASIC;
					break;
				}
			} else if (text.contains(entry)) {
				matches = true;
				matchType = FilterType.BASIC;
				break;
			}
		}

		if (!matches) {
			for (int i = 0; i < compiledRegexPatterns.size(); i++) {
				if (compiledRegexPatterns.get(i).matcher(text).find()) {
					matches = true;
					matchType = compiledRegexTypes.get(i);
					break;
				}
			}
		}

		boolean filtered = applyFilterMode(matches, whitelistMode);
		return new FilterEvaluation(filtered, matchType);
	}

	public boolean shouldFilterPlain(String text) {
		return evaluatePlain(text).filtered();
	}

	private Optional<FilterType> findMatchingFilter(LogMessage message) {
		for (ActiveFilter activeFilter : filterList) {
			if (activeFilter.entry().shouldFilter(message)) {
				return Optional.of(activeFilter.type());
			}
		}
		return Optional.empty();
	}

	public static boolean applyFilterMode(boolean matches, boolean whitelistMode) {
		return whitelistMode ? !matches : matches;
	}

	public int filterCount() {
		return filterList.size();
	}

	@Override
	public boolean isFilterLatestLog() {
		return filterLatestLog;
	}

	@Override
	public boolean isSkipMessagesWithStackTrace() {
		return skipMessagesWithStackTrace;
	}

	public boolean isIgnoreCase() {
		return ignoreCase;
	}

	public boolean isWhitelistMode() {
		return whitelistMode;
	}

	public String getActiveProfile() {
		return activeProfile;
	}

	public FilterLists getLists() {
		return lists;
	}

	public FilterSummary getSummary() {
		int loggerCount = countNonEmpty(lists.loggerFilters());
		int sourceCount = countNonEmpty(lists.sourceFilters());
		return new FilterSummary(
			countNonEmpty(lists.basicFilters()),
			countNonEmpty(lists.regexFilters()),
			countNonEmpty(lists.levelFilters()),
			countNonEmpty(lists.threadFilters()),
			sourceCount + loggerCount,
			countNonEmpty(lists.modIdFilters()),
			filterCount(),
			activeProfile,
			ignoreCase,
			whitelistMode,
			filterLatestLog,
			skipMessagesWithStackTrace
		);
	}

	public static int countNonEmpty(List<? extends String> values) {
		int count = 0;
		for (String value : values) {
			if (value != null && !value.isEmpty()) {
				count++;
			}
		}
		return count;
	}

	private record ActiveFilter(FilterType type, FilterEntry entry) {
	}
}
