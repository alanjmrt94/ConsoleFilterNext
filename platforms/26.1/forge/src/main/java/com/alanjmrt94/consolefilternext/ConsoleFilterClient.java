package com.alanjmrt94.consolefilternext;

import com.alanjmrt94.consolefilternext.client.ConsoleFilterConfigScreen;

import net.minecraftforge.client.ConfigScreenHandler;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;
import net.minecraftforge.fml.loading.FMLPaths;

/**
 * Registro del editor in-game en Forge 26.1.
 */
public final class ConsoleFilterClient {

	private ConsoleFilterClient() {
	}

	public static void register(FMLJavaModLoadingContext context) {
		context.registerExtensionPoint(
			ConfigScreenHandler.ConfigScreenFactory.class,
			() -> new ConfigScreenHandler.ConfigScreenFactory(
				(minecraft, parent) -> new ConsoleFilterConfigScreen(
					parent,
					ConsoleFilter.getInstance(),
					() -> FMLPaths.CONFIGDIR.get().resolve(FilterProfiles.CONFIG_FILE_NAME)
				)
			)
		);
	}
}
