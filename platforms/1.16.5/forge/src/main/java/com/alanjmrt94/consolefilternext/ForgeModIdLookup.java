package com.alanjmrt94.consolefilternext;

import net.minecraftforge.fml.ModList;

final class ForgeModIdLookup implements ModIdLookup {

	@Override
	public boolean matchesNamespace(String source, String modId) {
		return ModList.get().getModContainerById(modId)
			.map(container -> {
				if (source.startsWith(container.getModId())) {
					return true;
				}
				Object modInstance = container.getMod();
				if (modInstance == null || modInstance.getClass().getPackage() == null) {
					return false;
				}
				String packageName = modInstance.getClass().getPackage().getName();
				return packageName != null && source.startsWith(packageName);
			})
			.orElse(false);
	}
}
