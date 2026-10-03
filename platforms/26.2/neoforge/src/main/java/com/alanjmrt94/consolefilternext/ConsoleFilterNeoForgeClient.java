package com.alanjmrt94.consolefilternext;

import com.alanjmrt94.consolefilternext.client.ConsoleFilterConfigScreen;

import net.neoforged.api.distmarker.Dist;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.loading.FMLPaths;
import net.neoforged.neoforge.client.gui.IConfigScreenFactory;

/**
 * Registro del editor in-game en NeoForge 26.2 (API moderna).
 */
@Mod(value = ConsoleFilterNeoForge.MODID, dist = Dist.CLIENT)
public final class ConsoleFilterNeoForgeClient {

	public ConsoleFilterNeoForgeClient(ModContainer container) {
		container.registerExtensionPoint(
			IConfigScreenFactory.class,
			(minecraft, parent) -> new ConsoleFilterConfigScreen(
				parent,
				ConsoleFilterNeoForge.getInstance(),
				() -> FMLPaths.CONFIGDIR.get().resolve(FilterProfiles.CONFIG_FILE_NAME)
			)
		);
	}
}
