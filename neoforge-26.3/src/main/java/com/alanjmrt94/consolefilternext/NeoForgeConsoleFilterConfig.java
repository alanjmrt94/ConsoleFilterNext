package com.alanjmrt94.consolefilternext;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import com.electronwill.nightconfig.core.CommentedConfig;
import com.electronwill.nightconfig.core.file.CommentedFileConfig;

/**
 * Adaptador NightConfig/TOML → {@link FilterEngine} (mismo esquema que Forge/Fabric).
 */
public final class NeoForgeConsoleFilterConfig implements FilterConfigView {

	public static final String PROFILE_DEFAULT = FilterProfiles.DEFAULT;
	public static final String PROFILE_DEBUG = FilterProfiles.DEBUG;
	public static final String PROFILE_PRODUCTION = FilterProfiles.PRODUCTION;
	public static final String CONFIG_FILE_NAME = FilterProfiles.CONFIG_FILE_NAME;

	private final FilterEngine engine = new FilterEngine();
	private CommentedFileConfig fileConfig;
	private String profileOverride;

	public void loadFrom(java.nio.file.Path configPath) {
		fileConfig = CommentedFileConfig.builder(configPath)
			.sync()
			.autosave()
			.writingMode(com.electronwill.nightconfig.core.io.WritingMode.REPLACE)
			.build();
		fileConfig.load();
		ensureDefaults(fileConfig);
		fileConfig.save();
		reloadEngine();
	}

	public void reloadFromDisk() {
		if (fileConfig != null) {
			fileConfig.load();
		}
		profileOverride = null;
		reloadEngine();
	}

	private void reloadEngine() {
		FilterLists lists = resolveActiveLists();
		engine.reload(
			lists,
			getBoolean("general.ignoreCase", false),
			getBoolean("general.whitelistMode", false),
			getBoolean("general.filterLatestLog", true),
			getBoolean("general.skipMessagesWithStackTrace", false),
			getEffectiveProfile()
		);
	}

	private static void ensureDefaults(CommentedConfig config) {
		config.set("general.activeProfile", config.getOrElse("general.activeProfile", PROFILE_DEFAULT));
		config.set("general.ignoreCase", config.getOrElse("general.ignoreCase", false));
		config.set("general.whitelistMode", config.getOrElse("general.whitelistMode", false));
		config.set("general.filterLatestLog", config.getOrElse("general.filterLatestLog", true));
		config.set("general.skipMessagesWithStackTrace", config.getOrElse("general.skipMessagesWithStackTrace", false));
		ensureList(config, "general.basicFilters");
		ensureList(config, "general.regexFilters");
		ensureList(config, "general.levelFilters");
		ensureList(config, "general.threadFilters");
		ensureList(config, "general.sourceFilters");
		ensureList(config, "general.loggerFilters");
		ensureList(config, "general.modIdFilters");
		for (String profile : List.of(PROFILE_DEBUG, PROFILE_PRODUCTION)) {
			ensureList(config, "profiles." + profile + ".basicFilters");
			ensureList(config, "profiles." + profile + ".regexFilters");
			ensureList(config, "profiles." + profile + ".levelFilters");
			ensureList(config, "profiles." + profile + ".threadFilters");
			ensureList(config, "profiles." + profile + ".sourceFilters");
			ensureList(config, "profiles." + profile + ".loggerFilters");
			ensureList(config, "profiles." + profile + ".modIdFilters");
		}
	}

	private static void ensureList(CommentedConfig config, String path) {
		if (!config.contains(path)) {
			config.set(path, new ArrayList<String>());
		}
	}

	private FilterLists resolveActiveLists() {
		String profile = getEffectiveProfile();
		String prefix = switch (profile) {
			case FilterProfiles.DEBUG -> "profiles.debug.";
			case FilterProfiles.PRODUCTION -> "profiles.production.";
			default -> "general.";
		};
		return new FilterLists(
			copyList(getStringList(prefix + "basicFilters")),
			copyList(getStringList(prefix + "regexFilters")),
			copyList(getStringList(prefix + "levelFilters")),
			copyList(getStringList(prefix + "threadFilters")),
			copyList(getStringList(prefix + "sourceFilters")),
			copyList(getStringList(prefix + "loggerFilters")),
			copyList(getStringList(prefix + "modIdFilters"))
		);
	}

	@SuppressWarnings("unchecked")
	private List<String> getStringList(String path) {
		Object value = fileConfig.get(path);
		if (value instanceof List<?> list) {
			List<String> result = new ArrayList<>();
			for (Object entry : list) {
				if (entry != null) {
					result.add(String.valueOf(entry));
				}
			}
			return result;
		}
		return Collections.emptyList();
	}

	private static List<String> copyList(List<String> values) {
		return new ArrayList<>(values);
	}

	private boolean getBoolean(String path, boolean fallback) {
		Boolean value = fileConfig.get(path);
		return value != null ? value : fallback;
	}

	@Override
	public FilterEvaluation evaluate(LogMessage message) {
		return engine.evaluate(message);
	}

	@Override
	public boolean shouldFilter(LogMessage message) {
		return engine.shouldFilter(message);
	}

	@Override
	public FilterEvaluation evaluatePlain(String text) {
		return engine.evaluatePlain(text);
	}

	@Override
	public boolean isFilterLatestLog() {
		return engine.isFilterLatestLog();
	}

	@Override
	public boolean isSkipMessagesWithStackTrace() {
		return engine.isSkipMessagesWithStackTrace();
	}

	public boolean shouldFilterPlain(String text) {
		return engine.shouldFilterPlain(text);
	}

	public void setProfileOverride(String profile) {
		if (profile == null || profile.isBlank() || PROFILE_DEFAULT.equals(profile)) {
			profileOverride = null;
		} else {
			profileOverride = profile;
		}
		reloadEngine();
	}

	public void clearProfileOverride() {
		profileOverride = null;
	}

	public String getEffectiveProfile() {
		if (profileOverride != null) {
			return profileOverride;
		}
		String configured = fileConfig.get("general.activeProfile");
		return configured == null || configured.isBlank() ? PROFILE_DEFAULT : configured;
	}

	public int filterCount() {
		return engine.filterCount();
	}

	public FilterSummary getSummary() {
		return engine.getSummary();
	}

	public FilterEngine getEngine() {
		return engine;
	}

	public CommentedFileConfig getFileConfig() {
		return fileConfig;
	}
}
