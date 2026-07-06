package com.alanjmrt94.consolefilternext;

import net.minecraftforge.fml.ModList;

public final class ModIdResolver {

	private ModIdResolver() {
	}

	public static boolean messageFromMod(String source, String modId) {
		if (source == null || modId == null || modId.isBlank()) {
			return false;
		}

		if (matchesHeuristic(source, modId)) {
			return true;
		}

		try {
			return ModList.get().getModContainerById(modId)
			.map(container -> {
				String namespace = container.getNamespace();
				if (source.startsWith(namespace)) {
					return true;
				}
				Object modInstance = container.getMod();
				if (modInstance != null) {
					return source.startsWith(modInstance.getClass().getPackageName());
				}
				return false;
			})
			.orElse(false);
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
