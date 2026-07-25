package com.alanjmrt94.consolefilternext;

import net.minecraftforge.client.ConfigScreenHandler;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;
import net.minecraftforge.fml.loading.FMLPaths;

import com.alanjmrt94.consolefilternext.client.ConsoleFilterConfigScreen;

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
