package com.alanjmrt94.consolefilternext;

public final class ModIdResolver {

	private static volatile ModIdLookup lookup = (source, modId) -> false;

	private ModIdResolver() {
	}

	public static void setLookup(ModIdLookup modIdLookup) {
		lookup = modIdLookup != null ? modIdLookup : (source, modId) -> false;
	}

	public static ModIdLookup getLookup() {
		return lookup;
	}

	public static boolean messageFromMod(String source, String modId) {
		if (source == null || modId == null || modId.isBlank()) {
			return false;
		}

		if (matchesHeuristic(source, modId)) {
			return true;
		}

		try {
			return lookup.matchesNamespace(source, modId);
		} catch (Exception ignored) {
			return false;
		}
	}

	static boolean matchesHeuristic(String source, String modId) {
		if (source.equalsIgnoreCase(modId)) {
			return true;
		}
		String lowerSource = source.toLowerCase();
		String lowerModId = modId.toLowerCase();
		return lowerSource.contains(lowerModId);
	}
}
