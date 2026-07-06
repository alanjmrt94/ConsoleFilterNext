package com.alanjmrt94.consolefilternext;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
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
	private ForgeConfigSpec.ConfigValue<List<? extends String>> basicFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> regexFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> levelFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> threadFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> sourceFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> loggerFilters;

	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugBasicFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugRegexFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugLevelFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugThreadFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugSourceFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> debugLoggerFilters;

	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionBasicFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionRegexFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionLevelFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionThreadFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionSourceFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> productionLoggerFilters;

	private ForgeConfigSpec spec;

	private final List<FilterEntry> filterList = new ArrayList<>();
	private final List<Pattern> compiledRegexPatterns = new ArrayList<>();
	private String profileOverride;

	public void init() {
		ForgeConfigSpec.Builder builder = new ForgeConfigSpec.Builder();

		builder.push("general");

		activeProfile = builder
				.comment("Active filter profile: default (uses [general] lists), debug, or production (uses [profiles.*] sections).")
				.define("activeProfile", PROFILE_DEFAULT);

		ignoreCase = builder
				.comment("When true, basic, thread, source, logger, and regex filters ignore letter case.")
				.define("ignoreCase", false);

		whitelistMode = builder
				.comment("When false (default), matching messages are hidden. When true, only matching messages are shown.")
				.define("whitelistMode", false);

		filterLatestLog = builder
				.comment("When true, filters also apply to latest.log and other Log4j file appenders. When false, only console output is filtered.")
				.define("filterLatestLog", true);

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

		builder.pop();

		builder.push("profiles");

		builder.push(PROFILE_DEBUG);
		debugBasicFilters = defineFilterList(builder, "basicFilters", "Debug profile basic filters.");
		debugRegexFilters = defineFilterList(builder, "regexFilters", "Debug profile regex filters.");
		debugLevelFilters = defineFilterList(builder, "levelFilters", "Debug profile level filters.");
		debugThreadFilters = defineFilterList(builder, "threadFilters", "Debug profile thread filters.");
		debugSourceFilters = defineFilterList(builder, "sourceFilters", "Debug profile source filters.");
		debugLoggerFilters = defineFilterList(builder, "loggerFilters", "Debug profile logger filters.");
		builder.pop();

		builder.push(PROFILE_PRODUCTION);
		productionBasicFilters = defineFilterList(builder, "basicFilters", "Production profile basic filters.");
		productionRegexFilters = defineFilterList(builder, "regexFilters", "Production profile regex filters.");
		productionLevelFilters = defineFilterList(builder, "levelFilters", "Production profile level filters.");
		productionThreadFilters = defineFilterList(builder, "threadFilters", "Production profile thread filters.");
		productionSourceFilters = defineFilterList(builder, "sourceFilters", "Production profile source filters.");
		productionLoggerFilters = defineFilterList(builder, "loggerFilters", "Production profile logger filters.");
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

		boolean caseInsensitive = ignoreCase.get();
		FilterLists lists = resolveActiveLists();
		buildFilterList(lists, caseInsensitive);
	}

	private FilterLists resolveActiveLists() {
		String profile = getEffectiveProfile();
		return switch (profile) {
			case PROFILE_DEBUG -> listsFrom(
				debugBasicFilters, debugRegexFilters, debugLevelFilters,
				debugThreadFilters, debugSourceFilters, debugLoggerFilters);
			case PROFILE_PRODUCTION -> listsFrom(
				productionBasicFilters, productionRegexFilters, productionLevelFilters,
				productionThreadFilters, productionSourceFilters, productionLoggerFilters);
			default -> listsFrom(
				basicFilters, regexFilters, levelFilters,
				threadFilters, sourceFilters, loggerFilters);
		};
	}

	private FilterLists listsFrom(
			ForgeConfigSpec.ConfigValue<List<? extends String>> basic,
			ForgeConfigSpec.ConfigValue<List<? extends String>> regex,
			ForgeConfigSpec.ConfigValue<List<? extends String>> level,
			ForgeConfigSpec.ConfigValue<List<? extends String>> thread,
			ForgeConfigSpec.ConfigValue<List<? extends String>> source,
			ForgeConfigSpec.ConfigValue<List<? extends String>> logger) {
		return new FilterLists(
			copyList(basic.get()),
			copyList(regex.get()),
			copyList(level.get()),
			copyList(thread.get()),
			copyList(source.get()),
			copyList(logger.get())
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
				filterList.add(FilterEntry.wildcard(entry, caseInsensitive));
			}
		}

		for (String entry : lists.regexFilters()) {
			if (!entry.isEmpty()) {
				try {
					int flags = caseInsensitive ? Pattern.CASE_INSENSITIVE : 0;
					Pattern pattern = Pattern.compile(entry, flags);
					compiledRegexPatterns.add(pattern);
					filterList.add(FilterEntry.regex(pattern));
				} catch (PatternSyntaxException ignored) {
					// Expresión inválida en config; se omite
				}
			}
		}

		for (String level : lists.levelFilters()) {
			if (!level.isEmpty()) {
				filterList.add(FilterEntry.level(level));
			}
		}

		for (String thread : lists.threadFilters()) {
			if (!thread.isEmpty()) {
				filterList.add(FilterEntry.thread(thread, caseInsensitive));
			}
		}

		for (String source : lists.sourceFilters()) {
			if (!source.isEmpty()) {
				filterList.add(FilterEntry.source(source, caseInsensitive));
			}
		}

		for (String logger : lists.loggerFilters()) {
			if (!logger.isEmpty()) {
				filterList.add(FilterEntry.logger(logger, caseInsensitive));
			}
		}
	}

	public boolean shouldFilter(LogMessage message) {
		boolean matches = false;
		for (FilterEntry entry : filterList) {
			if (entry.shouldFilter(message)) {
				matches = true;
				break;
			}
		}
		return applyFilterMode(matches, whitelistMode.get());
	}

	public boolean shouldFilterPlain(String text) {
		if (text == null || text.isEmpty()) {
			return applyFilterMode(false, whitelistMode.get());
		}

		boolean caseInsensitive = ignoreCase.get();
		boolean matches = false;

		FilterLists lists = resolveActiveLists();
		for (String entry : lists.basicFilters()) {
			if (entry.isEmpty()) {
				continue;
			}
			if (caseInsensitive) {
				if (text.toLowerCase(Locale.ROOT).contains(entry.toLowerCase(Locale.ROOT))) {
					matches = true;
					break;
				}
			} else if (text.contains(entry)) {
				matches = true;
				break;
			}
		}

		if (!matches) {
			for (Pattern pattern : compiledRegexPatterns) {
				if (pattern.matcher(text).find()) {
					matches = true;
					break;
				}
			}
		}

		return applyFilterMode(matches, whitelistMode.get());
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
			filterCount(),
			getEffectiveProfile(),
			isIgnoreCase(),
			isWhitelistMode(),
			isFilterLatestLog()
		);
	}

	public ForgeConfigSpec getSpec() {
		return spec;
	}

	public record FilterSummary(
		int basic,
		int regex,
		int level,
		int thread,
		int source,
		int total,
		String activeProfile,
		boolean ignoreCase,
		boolean whitelistMode,
		boolean filterLatestLog
	) {
	}
}
