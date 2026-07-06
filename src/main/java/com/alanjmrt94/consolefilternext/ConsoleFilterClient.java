package com.alanjmrt94.consolefilternext;

import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.client.ConfigScreenHandler;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;

import com.alanjmrt94.consolefilternext.client.ConsoleFilterConfigScreen;

public final class ConsoleFilterClient {

	private ConsoleFilterClient() {
	}

	public static void register(FMLJavaModLoadingContext context) {
		context.registerExtensionPoint(
			ConfigScreenHandler.ConfigScreenFactory.class,
			() -> new ConfigScreenHandler.ConfigScreenFactory(
				(minecraft, parent) -> new ConsoleFilterConfigScreen(parent)
			)
		);
	}
}
