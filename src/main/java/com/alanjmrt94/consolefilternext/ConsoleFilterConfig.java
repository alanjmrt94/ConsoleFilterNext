package com.alanjmrt94.consolefilternext;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

import net.minecraftforge.common.ForgeConfigSpec;

public class ConsoleFilterConfig {

	private ForgeConfigSpec.ConfigValue<List<? extends String>> basicFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> regexFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> levelFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> threadFilters;
	private ForgeConfigSpec.ConfigValue<List<? extends String>> sourceFilters;
	private ForgeConfigSpec spec;

	private List<FilterEntry> filterList = new ArrayList<>();

	public void init() {
		ForgeConfigSpec.Builder builder = new ForgeConfigSpec.Builder();

		builder.push("general");

		basicFilters = builder
				.comment("Any console messages containing any of these strings will be hidden.")
				.defineList("basicFilters", Collections.emptyList(), obj -> true);

		regexFilters = builder
				.comment("Any console messages that match any of these regular expressions will be hidden. Uses Java style regex. Backslashes must be escaped, for example use \\\\s instead of \\s to match whitespace.")
				.defineList("regexFilters", Collections.emptyList(), obj -> true);

		levelFilters = builder
				.comment("Filter messages by log level (INFO, ERROR, WARN, etc.)")
				.defineList("levelFilters", Collections.emptyList(), obj -> true);

		threadFilters = builder
				.comment("Filter messages by thread name (e.g., 'Server thread', 'Render thread', etc.)")
				.defineList("threadFilters", Collections.emptyList(), obj -> true);

		sourceFilters = builder
				.comment("Filter messages by source (e.g., 'net.minecraft.server.MinecraftServer')")
				.defineList("sourceFilters", Collections.emptyList(), obj -> true);

		builder.pop();

		spec = builder.build();
	}

	public void load() {
		filterList.clear();

		for (String entry : basicFilters.get()) {
			if (entry != null && !entry.isEmpty()) {
				filterList.add(FilterEntry.wildcard(entry));
			}
		}

		for (String entry : regexFilters.get()) {
			if (entry != null && !entry.isEmpty()) {
				filterList.add(FilterEntry.regex(entry));
			}
		}

		for (String level : levelFilters.get()) {
			if (level != null && !level.isEmpty()) {
				filterList.add(FilterEntry.level(level));
			}
		}

		for (String thread : threadFilters.get()) {
			if (thread != null && !thread.isEmpty()) {
				filterList.add(FilterEntry.thread(thread));
			}
		}

		for (String source : sourceFilters.get()) {
			if (source != null && !source.isEmpty()) {
				filterList.add(FilterEntry.source(source));
			}
		}
	}

	public boolean shouldFilter(LogMessage message) {
		for (FilterEntry entry : filterList) {
			if (entry.shouldFilter(message)) {
				return true;
			}
		}

		return false;
	}

	public boolean shouldFilterPlain(String text) {
		if (text == null || text.isEmpty()) {
			return false;
		}

		for (String entry : basicFilters.get()) {
			if (entry != null && !entry.isEmpty() && text.contains(entry)) {
				return true;
			}
		}

		for (String entry : regexFilters.get()) {
			if (entry == null || entry.isEmpty()) {
				continue;
			}
			try {
				if (Pattern.compile(entry).matcher(text).find()) {
					return true;
				}
			} catch (PatternSyntaxException ignored) {
				// Expresión inválida en config; se omite
			}
		}

		return false;
	}

	public int filterCount() {
		return filterList.size();
	}

	public ForgeConfigSpec getSpec() {
		return spec;
	}
}
