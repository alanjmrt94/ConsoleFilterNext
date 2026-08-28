package com.alanjmrt94.consolefilternext;

import net.neoforged.fml.ModList;

final class NeoForgeModIdLookup implements ModIdLookup {

	@Override
	public boolean matchesNamespace(String source, String modId) {
		return ModList.get().getModContainerById(modId)
			.map(container -> source.startsWith(container.getNamespace()))
			.orElse(false);
	}
}
