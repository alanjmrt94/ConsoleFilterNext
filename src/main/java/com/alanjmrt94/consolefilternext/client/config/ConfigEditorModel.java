package com.alanjmrt94.consolefilternext.client.config;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import com.alanjmrt94.consolefilternext.ConsoleFilterConfig;
import com.electronwill.nightconfig.core.file.CommentedFileConfig;

public class ConfigEditorModel {

	public static final List<String> PROFILE_OPTIONS = List.of(
		ConsoleFilterConfig.PROFILE_DEFAULT,
		ConsoleFilterConfig.PROFILE_DEBUG,
		ConsoleFilterConfig.PROFILE_PRODUCTION
	);

	public static final List<String> FILTER_LIST_KEYS = List.of(
		"basicFilters",
		"regexFilters",
		"levelFilters",
		"threadFilters",
		"sourceFilters",
		"loggerFilters"
	);

	private final CommentedFileConfig fileConfig;
	private String editingProfile = ConsoleFilterConfig.PROFILE_DEFAULT;

	public ConfigEditorModel(CommentedFileConfig fileConfig) {
		this.fileConfig = fileConfig;
		this.editingProfile = getString("general.activeProfile", ConsoleFilterConfig.PROFILE_DEFAULT);
	}

	public static ConfigEditorModel load(Path configPath) {
		CommentedFileConfig config = CommentedFileConfig.builder(configPath).build();
		config.load();
		return new ConfigEditorModel(config);
	}

	public void save(Path configPath) {
		fileConfig.save();
	}

	public String getEditingProfile() {
		return editingProfile;
	}

	public void setEditingProfile(String profile) {
		editingProfile = profile;
	}

	public void cycleEditingProfile() {
		int index = PROFILE_OPTIONS.indexOf(editingProfile);
		int next = index < 0 ? 0 : (index + 1) % PROFILE_OPTIONS.size();
		editingProfile = PROFILE_OPTIONS.get(next);
	}

	public void cycleActiveProfile() {
		String current = getActiveProfile();
		int index = PROFILE_OPTIONS.indexOf(current);
		int next = index < 0 ? 0 : (index + 1) % PROFILE_OPTIONS.size();
		setActiveProfile(PROFILE_OPTIONS.get(next));
	}

	public boolean isIgnoreCase() {
		return getBoolean("general.ignoreCase", false);
	}

	public void setIgnoreCase(boolean value) {
		fileConfig.set("general.ignoreCase", value);
	}

	public boolean isWhitelistMode() {
		return getBoolean("general.whitelistMode", false);
	}

	public void setWhitelistMode(boolean value) {
		fileConfig.set("general.whitelistMode", value);
	}

	public boolean isFilterLatestLog() {
		return getBoolean("general.filterLatestLog", true);
	}

	public void setFilterLatestLog(boolean value) {
		fileConfig.set("general.filterLatestLog", value);
	}

	public String getActiveProfile() {
		return getString("general.activeProfile", ConsoleFilterConfig.PROFILE_DEFAULT);
	}

	public void setActiveProfile(String profile) {
		fileConfig.set("general.activeProfile", profile);
	}

	public List<String> getFilterList(String listKey) {
		return new ArrayList<>(readStringList(resolveListPath(editingProfile, listKey)));
	}

	public void setFilterList(String listKey, List<String> values) {
		fileConfig.set(resolveListPath(editingProfile, listKey), values);
	}

	public int countNonEmptyFilters(String profile) {
		int count = 0;
		for (String listKey : FILTER_LIST_KEYS) {
			for (String value : readStringList(resolveListPath(profile, listKey))) {
				if (!value.isEmpty()) {
					count++;
				}
			}
		}
		return count;
	}

	public static String resolveListPath(String profile, String listKey) {
		if (ConsoleFilterConfig.PROFILE_DEFAULT.equals(profile)) {
			return "general." + listKey;
		}
		return "profiles." + profile + "." + listKey;
	}

	public static String displayNameForList(String listKey) {
		return switch (listKey) {
			case "basicFilters" -> "Basic filters";
			case "regexFilters" -> "Regex filters";
			case "levelFilters" -> "Level filters";
			case "threadFilters" -> "Thread filters";
			case "sourceFilters" -> "Source filters";
			case "loggerFilters" -> "Logger filters";
			default -> listKey;
		};
	}

	private boolean getBoolean(String path, boolean defaultValue) {
		Object value = fileConfig.get(path);
		return value instanceof Boolean bool ? bool : defaultValue;
	}

	private String getString(String path, String defaultValue) {
		Object value = fileConfig.get(path);
		return value instanceof String str && !str.isBlank() ? str : defaultValue;
	}

	@SuppressWarnings("unchecked")
	private List<String> readStringList(String path) {
		Object value = fileConfig.get(path);
		if (!(value instanceof List<?> list)) {
			return List.of();
		}
		List<String> result = new ArrayList<>();
		for (Object item : list) {
			if (item != null) {
				result.add(item.toString());
			}
		}
		return result;
	}
}
