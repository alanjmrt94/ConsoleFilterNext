package com.alanjmrt94.consolefilternext;

import java.util.Arrays;
import java.util.List;

public enum ConfigPreset {

	DEBUG(
		"Debug",
		"[general]\nactiveProfile = \"debug\"\nignoreCase = false\nwhitelistMode = false\nfilterLatestLog = true\nskipMessagesWithStackTrace = true\nbasicFilters = []\nregexFilters = []\nlevelFilters = [\"DEBUG\"]\nthreadFilters = []\nsourceFilters = []\nloggerFilters = []\nmodIdFilters = []\n\n[profiles.debug]\nbasicFilters = []\nregexFilters = []\nlevelFilters = [\"DEBUG\"]\nthreadFilters = []\nsourceFilters = []\nloggerFilters = []\nmodIdFilters = []\n\n[profiles.production]\nbasicFilters = []\nregexFilters = []\nlevelFilters = [\"WARN\", \"ERROR\"]\nthreadFilters = []\nsourceFilters = []\nloggerFilters = []\nmodIdFilters = []"
	),

	SILENT_MODPACK(
		"Silent modpack",
		"[general]\nactiveProfile = \"production\"\nignoreCase = false\nwhitelistMode = false\nfilterLatestLog = true\nskipMessagesWithStackTrace = true\nbasicFilters = [\"Could not resolve\", \"Missing texture\", \"Unable to load\"]\nregexFilters = []\nlevelFilters = [\"INFO\", \"DEBUG\"]\nthreadFilters = [\"Render thread\"]\nsourceFilters = []\nloggerFilters = []\nmodIdFilters = []\n\n[profiles.debug]\nbasicFilters = []\nregexFilters = []\nlevelFilters = [\"DEBUG\"]\nthreadFilters = []\nsourceFilters = []\nloggerFilters = []\nmodIdFilters = []\n\n[profiles.production]\nbasicFilters = [\"Could not resolve\", \"Missing texture\", \"Unable to load\"]\nregexFilters = []\nlevelFilters = [\"INFO\", \"DEBUG\"]\nthreadFilters = [\"Render thread\"]\nsourceFilters = []\nloggerFilters = []\nmodIdFilters = []"
	),

	MINIMAL(
		"Minimal",
		"[general]\nactiveProfile = \"default\"\nignoreCase = false\nwhitelistMode = false\nfilterLatestLog = false\nskipMessagesWithStackTrace = false\nbasicFilters = []\nregexFilters = []\nlevelFilters = []\nthreadFilters = []\nsourceFilters = []\nloggerFilters = []\nmodIdFilters = []\n\n[profiles.debug]\nbasicFilters = []\nregexFilters = []\nlevelFilters = []\nthreadFilters = []\nsourceFilters = []\nloggerFilters = []\nmodIdFilters = []\n\n[profiles.production]\nbasicFilters = []\nregexFilters = []\nlevelFilters = []\nthreadFilters = []\nsourceFilters = []\nloggerFilters = []\nmodIdFilters = []"
	);

	private final String label;
	private final String toml;

	ConfigPreset(String label, String toml) {
		this.label = label;
		this.toml = toml;
	}

	public String getLabel() {
		return label;
	}

	public String getToml() {
		return toml;
	}

	public static List<ConfigPreset> all() {
		return Arrays.asList(values());
	}
}
