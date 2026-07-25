package com.alanjmrt94.consolefilternext;

import net.minecraftforge.fml.ModList;

final class ForgeModIdLookup implements ModIdLookup {

	@Override
	public boolean matchesNamespace(String source, String modId) {
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
	}
}
