package com.alanjmrt94.consolefilternext;

import com.alanjmrt94.consolefilternext.client.ConsoleFilterConfigScreen;

import net.neoforged.fml.ModLoadingContext;
import net.neoforged.fml.loading.FMLPaths;
import net.neoforged.neoforge.client.ConfigScreenHandler;

/**
 * Registro del editor in-game en NeoForge 1.20.2–1.20.4 ({@code ConfigScreenHandler}).
 */
public final class ConsoleFilterNeoForgeClient {

	private ConsoleFilterNeoForgeClient() {
	}

	public static void register() {
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
