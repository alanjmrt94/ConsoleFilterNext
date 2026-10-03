package com.alanjmrt94.consolefilternext;

import net.minecraftforge.fml.ModList;

final class ForgeModIdLookup implements ModIdLookup {

	@Override
	public boolean matchesNamespace(String source, String modId) {
		return ModList.getModContainerById(modId)
			.map(container -> source.startsWith(container.getNamespace()))
			.orElse(false);
	}
}
