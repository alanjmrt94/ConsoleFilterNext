package com.alanjmrt94.consolefilternext;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

import net.minecraftforge.common.ForgeConfigSpec;

public class ConsoleFilterConfig {

	private ForgeConfigSpec.ConfigValue<List<? extends String>> basicFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> regexFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> levelFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> threadFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> sourceFilters;
	private ForgeConfigSpec.ConfigValue<Boolean> ignoreCase;
	private ForgeConfigSpec.ConfigValue<Boolean> whitelistMode;
	private ForgeConfigSpec spec;

	private List<FilterEntry> filterList = new ArrayList<>();
	private List<Pattern> compiledRegexPatterns = new ArrayList<>();

	public void init() {
		ForgeConfigSpec.Builder builder = new ForgeConfigSpec.Builder();

		builder.push("general");

		ignoreCase = builder
				.comment("When true, basic, thread, source, and regex filters ignore letter case.")
				.define("ignoreCase", false);

		whitelistMode = builder
				.comment("When false (default), matching messages are hidden. When true, only matching messages are shown; everything else is hidden.")
				.define("whitelistMode", false);

		basicFilters = builder
				.comment("Any console messages containing any of these strings will be hidden (unless whitelistMode is enabled).")
				.defineList("basicFilters", Collections.emptyList(), obj -> true);

		regexFilters = builder
				.comment("Any console messages that match any of these regular expressions will be hidden. Uses Java style regex. Backslashes must be escaped, for example use \\\\s instead of \\s to match whitespace.")
				.defineList("regexFilters", Collections.emptyList(), obj -> true);

		levelFilters = builder
				.comment("Filter messages by log level (INFO, ERROR, WARN, etc.). Always case-insensitive.")
				.defineList("levelFilters", Collections.emptyList(), obj -> true);

		threadFilters = builder
				.comment("Filter messages by thread name (e.g., 'Server thread', 'Render thread', etc.)")
				.defineList("threadFilters", Collections.emptyList(), obj -> true);

		sourceFilters = builder
				.comment("Filter messages by source/logger name. Matches when the source contains any of these strings (e.g. 'net.minecraft.server' matches 'net.minecraft.server.MinecraftServer').")
				.defineList("sourceFilters", Collections.emptyList(), obj -> true);

		builder.pop();

		spec = builder.build();
	}

	public void load() {
		filterList.clear();
		compiledRegexPatterns.clear();

		boolean caseInsensitive = ignoreCase.get();

		for (String entry : basicFilters.get()) {
			if (entry != null && !entry.isEmpty()) {
				filterList.add(FilterEntry.wildcard(entry, caseInsensitive));
			}
		}

		for (String entry : regexFilters.get()) {
			if (entry != null && !entry.isEmpty()) {
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

		for (String level : levelFilters.get()) {
			if (level != null && !level.isEmpty()) {
				filterList.add(FilterEntry.level(level));
			}
		}

		for (String thread : threadFilters.get()) {
			if (thread != null && !thread.isEmpty()) {
				filterList.add(FilterEntry.thread(thread, caseInsensitive));
			}
		}

		for (String source : sourceFilters.get()) {
			if (source != null && !source.isEmpty()) {
				filterList.add(FilterEntry.source(source, caseInsensitive));
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
		return applyMode(matches);
	}

	public boolean shouldFilterPlain(String text) {
		if (text == null || text.isEmpty()) {
			return applyMode(false);
		}

		boolean caseInsensitive = ignoreCase.get();
		boolean matches = false;

		for (String entry : basicFilters.get()) {
			if (entry == null || entry.isEmpty()) {
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

		return applyMode(matches);
	}

	private boolean applyMode(boolean matches) {
		return whitelistMode.get() ? !matches : matches;
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
		return new FilterSummary(
			countNonEmpty(basicFilters.get()),
			countNonEmpty(regexFilters.get()),
			countNonEmpty(levelFilters.get()),
			countNonEmpty(threadFilters.get()),
			countNonEmpty(sourceFilters.get()),
			filterCount(),
			isIgnoreCase(),
			isWhitelistMode()
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
		boolean ignoreCase,
		boolean whitelistMode
	) {
	}
}
