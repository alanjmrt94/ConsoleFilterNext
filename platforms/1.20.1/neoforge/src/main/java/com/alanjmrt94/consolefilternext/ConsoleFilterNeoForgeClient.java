package com.alanjmrt94.consolefilternext;

import com.alanjmrt94.consolefilternext.client.ConsoleFilterConfigScreen;

import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.client.ConfigScreenHandler;
import net.minecraftforge.fml.ModLoadingContext;
import net.minecraftforge.fml.loading.FMLEnvironment;
import net.minecraftforge.fml.loading.FMLPaths;

/**
 * Registro del editor in-game en NeoForge 1.20.1 (FML 47.1.x).
 */
public final class ConsoleFilterNeoForgeClient {

	private ConsoleFilterNeoForgeClient() {
	}

	public static void register() {
		if (FMLEnvironment.dist != Dist.CLIENT) {
			return;
		}
		ModLoadingContext.get().registerExtensionPoint(
			ConfigScreenHandler.ConfigScreenFactory.class,
			() -> new ConfigScreenHandler.ConfigScreenFactory(
				(minecraft, parent) -> new ConsoleFilterConfigScreen(
					parent,
					ConsoleFilterNeoForge.getInstance(),
					() -> FMLPaths.CONFIGDIR.get().resolve(FilterProfiles.CONFIG_FILE_NAME)
				)
			)
		);
	}
}
