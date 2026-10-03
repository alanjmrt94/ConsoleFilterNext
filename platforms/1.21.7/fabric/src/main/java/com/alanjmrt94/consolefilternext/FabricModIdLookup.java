package com.alanjmrt94.consolefilternext;

import net.fabricmc.loader.api.FabricLoader;

final class FabricModIdLookup implements ModIdLookup {

	@Override
	public boolean matchesNamespace(String source, String modId) {
		if (!FabricLoader.getInstance().isModLoaded(modId)) {
			return false;
		}
		return source.regionMatches(true, 0, modId, 0, modId.length())
			|| source.toLowerCase().contains('.' + modId.toLowerCase());
	}
}
