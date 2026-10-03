package com.alanjmrt94.consolefilternext;

import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.ModContainer;

final class ForgeModIdLookup implements ModIdLookup {

	@Override
	public boolean matchesNamespace(String source, String modId) {
		ModContainer container = Loader.instance().getIndexedModList().get(modId);
		if (container == null) {
			return false;
		}
		if (source.regionMatches(true, 0, modId, 0, modId.length())) {
			return true;
		}
		Object mod = container.getMod();
		if (mod != null && mod.getClass().getPackage() != null) {
			String packageName = mod.getClass().getPackage().getName();
			if (packageName != null && source.startsWith(packageName)) {
				return true;
			}
		}
		return source.toLowerCase().contains('.' + modId.toLowerCase());
	}
}
