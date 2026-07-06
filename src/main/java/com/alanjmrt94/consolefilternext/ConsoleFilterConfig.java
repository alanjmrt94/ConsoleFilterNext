package com.alanjmrt94.consolefilternext;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

import net.minecraftforge.common.ForgeConfigSpec;

public class ConsoleFilterConfig {

	public static final String PROFILE_DEFAULT = "default";
	public static final String PROFILE_DEBUG = "debug";
	public static final String PROFILE_PRODUCTION = "production";

	private ForgeConfigSpec.ConfigValue<String> activeProfile;
	private ForgeConfigSpec.ConfigValue<Boolean> ignoreCase;
	private ForgeConfigSpec.ConfigValue<Boolean> whitelistMode;
	private ForgeConfigSpec.ConfigValue<Boolean> filterLatestLog;
	private ForgeConfigSpec.ConfigValue<Boolean> skipMessagesWithStackTrace;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> basicFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> regexFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> levelFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> threadFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> sourceFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> loggerFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> modIdFilters;

	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugBasicFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugRegexFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugLevelFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugThreadFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugSourceFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugLoggerFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugModIdFilters;

	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionBasicFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionRegexFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionLevelFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionThreadFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionSourceFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionLoggerFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionModIdFilters;

	private ForgeConfigSpec spec;

	private final List<ActiveFilter> filterList = new ArrayList<>();
	private final List<Pattern> compiledRegexPatterns = new ArrayList<>();
	private final List<FilterType> compiledRegexTypes = new ArrayList<>();
	private String profileOverride;

	public void init() {
		ForgeConfigSpec.Builder builder = new ForgeConfigSpec.Builder();

		builder.push("general");

		activeProfile = builder
			.comment("Active filter profile: default (uses [general] lists), debug, or production (uses [profiles.*] sections).")
			.define("activeProfile", PROFILE_DEFAULT);

		ignoreCase = builder
			.comment("When true, basic, thread, source, logger, mod id, and regex filters ignore letter case.")
			.define("ignoreCase", false);

		whitelistMode = builder
			.comment("When false (default), matching messages are hidden. When true, only matching messages are shown.")
			.define("whitelistMode", false);

		filterLatestLog = builder
			.comment("When true, filters also apply to latest.log and other Log4j file appenders. When false, only console output is filtered.")
			.define("filterLatestLog", true);

		skipMessagesWithStackTrace = builder
			.comment("When true, messages with an attached exception/stack trace are never filtered.")
			.define("skipMessagesWithStackTrace", false);

		basicFilters = defineFilterList(builder, "basicFilters",
			"Any console messages containing any of these strings will be hidden (unless whitelistMode is enabled).");
		regexFilters = defineFilterList(builder, "regexFilters",
			"Console messages matching these Java-style regular expressions will be hidden.");
		levelFilters = defineFilterList(builder, "levelFilters",
			"Filter messages by log level (INFO, ERROR, WARN, etc.). Always case-insensitive.");
		threadFilters = defineFilterList(builder, "threadFilters",
			"Filter by thread name (contains match).");
		sourceFilters = defineFilterList(builder, "sourceFilters",
			"Filter by source/logger name (contains match).");
		loggerFilters = defineFilterList(builder, "loggerFilters",
			"Legacy alias for source/logger filtering (contains match). Merged with sourceFilters.");
		modIdFilters = defineFilterList(builder, "modIdFilters",
			"Filter messages from Forge mods by mod id (e.g. create, jei).");

		builder.pop();

		builder.push("profiles");

		builder.push(PROFILE_DEBUG);
		debugBasicFilters = defineFilterList(builder, "basicFilters", "Debug profile basic filters.");
		debugRegexFilters = defineFilterList(builder, "regexFilters", "Debug profile regex filters.");
		debugLevelFilters = defineFilterList(builder, "levelFilters", "Debug profile level filters.");
		debugThreadFilters = defineFilterList(builder, "threadFilters", "Debug profile thread filters.");
		debugSourceFilters = defineFilterList(builder, "sourceFilters", "Debug profile source filters.");
		debugLoggerFilters = defineFilterList(builder, "loggerFilters", "Debug profile logger filters.");
		debugModIdFilters = defineFilterList(builder, "modIdFilters", "Debug profile mod id filters.");
		builder.pop();

		builder.push(PROFILE_PRODUCTION);
		productionBasicFilters = defineFilterList(builder, "basicFilters", "Production profile basic filters.");
		productionRegexFilters = defineFilterList(builder, "regexFilters", "Production profile regex filters.");
		productionLevelFilters = defineFilterList(builder, "levelFilters", "Production profile level filters.");
		productionThreadFilters = defineFilterList(builder, "threadFilters", "Production profile thread filters.");
		productionSourceFilters = defineFilterList(builder, "sourceFilters", "Production profile source filters.");
		productionLoggerFilters = defineFilterList(builder, "loggerFilters", "Production profile logger filters.");
		productionModIdFilters = defineFilterList(builder, "modIdFilters", "Production profile mod id filters.");
		builder.pop();

		builder.pop();

		spec = builder.build();
	}

	private static ForgeConfigSpec.ConfigValue<List<? extends String>> defineFilterList(
			ForgeConfigSpec.Builder builder, String name, String comment) {
		return builder.comment(comment).defineList(name, Collections.emptyList(), obj -> true);
	}

	public void load() {
		filterList.clear();
		compiledRegexPatterns.clear();
		compiledRegexTypes.clear();

		boolean caseInsensitive = ignoreCase.get();
		FilterLists lists = resolveActiveLists();
		buildFilterList(lists, caseInsensitive);
	}

	private FilterLists resolveActiveLists() {
		String profile = getEffectiveProfile();
		return switch (profile) {
			case PROFILE_DEBUG -> listsFrom(
				debugBasicFilters, debugRegexFilters, debugLevelFilters,
				debugThreadFilters, debugSourceFilters, debugLoggerFilters, debugModIdFilters);
			case PROFILE_PRODUCTION -> listsFrom(
				productionBasicFilters, productionRegexFilters, productionLevelFilters,
				productionThreadFilters, productionSourceFilters, productionLoggerFilters, productionModIdFilters);
			default -> listsFrom(
				basicFilters, regexFilters, levelFilters,
				threadFilters, sourceFilters, loggerFilters, modIdFilters);
		};
	}

	private FilterLists listsFrom(
			ForgeConfigSpec.ConfigValue<List<? extends String>> basic,
			ForgeConfigSpec.ConfigValue<List<? extends String>> regex,
			ForgeConfigSpec.ConfigValue<List<? extends String>> level,
			ForgeConfigSpec.ConfigValue<List<? extends String>> thread,
			ForgeConfigSpec.ConfigValue<List<? extends String>> source,
			ForgeConfigSpec.ConfigValue<List<? extends String>> logger,
			ForgeConfigSpec.ConfigValue<List<? extends String>> modId) {
		return new FilterLists(
			copyList(basic.get()),
			copyList(regex.get()),
			copyList(level.get()),
			copyList(thread.get()),
			copyList(source.get()),
			copyList(logger.get()),
			copyList(modId.get())
		);
	}

	private static List<String> copyList(List<? extends String> values) {
		List<String> copy = new ArrayList<>();
		for (String value : values) {
			if (value != null) {
				copy.add(value);
			}
		}
		return copy;
	}

	private void buildFilterList(FilterLists lists, boolean caseInsensitive) {
		for (String entry : lists.basicFilters()) {
			if (!entry.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.BASIC, FilterEntry.wildcard(entry, caseInsensitive)));
			}
		}

		for (String entry : lists.regexFilters()) {
			if (!entry.isEmpty()) {
				try {
					int flags = caseInsensitive ? Pattern.CASE_INSENSITIVE : 0;
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
				filterList.add(new ActiveFilter(FilterType.THREAD, FilterEntry.thread(thread, caseInsensitive)));
			}
		}

		for (String source : lists.sourceFilters()) {
			if (!source.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.SOURCE, FilterEntry.source(source, caseInsensitive)));
			}
		}

		for (String logger : lists.loggerFilters()) {
			if (!logger.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.LOGGER, FilterEntry.logger(logger, caseInsensitive)));
			}
		}

		for (String modId : lists.modIdFilters()) {
			if (!modId.isEmpty()) {
				filterList.add(new ActiveFilter(FilterType.MOD_ID, FilterEntry.modId(modId)));
			}
		}
	}

	public FilterEvaluation evaluate(LogMessage message) {
		if (skipMessagesWithStackTrace.get() && message.hasStackTraceHint()) {
			return FilterEvaluation.passThrough();
		}

		Optional<FilterType> matchType = findMatchingFilter(message);
		boolean matches = matchType.isPresent();
		boolean filtered = applyFilterMode(matches, whitelistMode.get());
		return new FilterEvaluation(filtered, matchType.orElse(null));
	}

	public boolean shouldFilter(LogMessage message) {
		return evaluate(message).filtered();
	}

	public FilterEvaluation evaluatePlain(String text) {
		if (text == null || text.isEmpty()) {
			return new FilterEvaluation(applyFilterMode(false, whitelistMode.get()), null);
		}

		if (skipMessagesWithStackTrace.get() && StackTraceDetector.looksLikeStackTrace(text)) {
			return FilterEvaluation.passThrough();
		}

		boolean caseInsensitive = ignoreCase.get();
		boolean matches = false;
		FilterType matchType = null;

		FilterLists lists = resolveActiveLists();
		for (String entry : lists.basicFilters()) {
			if (entry.isEmpty()) {
				continue;
			}
			if (caseInsensitive) {
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

		boolean filtered = applyFilterMode(matches, whitelistMode.get());
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

	static boolean applyFilterMode(boolean matches, boolean whitelistMode) {
		return whitelistMode ? !matches : matches;
	}

	public void setProfileOverride(String profile) {
		if (profile == null || profile.isBlank() || PROFILE_DEFAULT.equals(profile)) {
			profileOverride = null;
		} else {
			profileOverride = profile;
		}
		load();
	}

	public void clearProfileOverride() {
		profileOverride = null;
	}

	public String getEffectiveProfile() {
		if (profileOverride != null) {
			return profileOverride;
		}
		String configured = activeProfile.get();
		return configured == null || configured.isBlank() ? PROFILE_DEFAULT : configured;
	}

	public int filterCount() {
		return filterList.size();
	}

	public boolean isIgnoreCase() {
		return ignoreCase.get();
	}

	public boolean isWhitelistMode() {
		return whitelistMode.get();
	}

	public boolean isFilterLatestLog() {
		return filterLatestLog.get();
	}

	public boolean isSkipMessagesWithStackTrace() {
		return skipMessagesWithStackTrace.get();
	}

	public int countNonEmpty(List<? extends String> values) {
		int count = 0;
		for (String value : values) {
			if (value != null && !value.isEmpty()) {
				count++;
			}
		}
		return count;
	}

	public FilterSummary getSummary() {
		FilterLists lists = resolveActiveLists();
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
			getEffectiveProfile(),
			isIgnoreCase(),
			isWhitelistMode(),
			isFilterLatestLog(),
			isSkipMessagesWithStackTrace()
		);
	}

	public ForgeConfigSpec getSpec() {
		return spec;
	}

	public record FilterEvaluation(boolean filtered, FilterType matchType) {
		public static FilterEvaluation passThrough() {
			return new FilterEvaluation(false, null);
		}
	}

	private record ActiveFilter(FilterType type, FilterEntry entry) {
	}

	public record FilterSummary(
		int basic,
		int regex,
		int level,
		int thread,
		int source,
		int modId,
		int total,
		String activeProfile,
		boolean ignoreCase,
		boolean whitelistMode,
		boolean filterLatestLog,
		boolean skipMessagesWithStackTrace
	) {
	}
}
