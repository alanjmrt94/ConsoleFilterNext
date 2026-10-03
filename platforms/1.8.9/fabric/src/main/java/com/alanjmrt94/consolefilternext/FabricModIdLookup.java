package com.alanjmrt94.consolefilternext;

import net.fabricmc.loader.api.FabricLoader;
import net.fabricmc.loader.api.ModContainer;

final class FabricModIdLookup implements ModIdLookup {

	@Override
	public boolean matchesNamespace(String source, String modId) {
		if (source == null || modId == null) {
			return false;
		}
		if (source.regionMatches(true, 0, modId, 0, modId.length())) {
			return true;
		}
		java.util.Optional<ModContainer> container = FabricLoader.getInstance().getModContainer(modId);
		if (!container.isPresent()) {
			return false;
		}
		return source.toLowerCase().contains('.' + modId.toLowerCase());
	}
}
