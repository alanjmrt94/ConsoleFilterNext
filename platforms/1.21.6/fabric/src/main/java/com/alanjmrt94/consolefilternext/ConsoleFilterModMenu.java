package com.alanjmrt94.consolefilternext;

import com.alanjmrt94.consolefilternext.client.ConsoleFilterConfigScreen;
import com.terraformersmc.modmenu.api.ConfigScreenFactory;
import com.terraformersmc.modmenu.api.ModMenuApi;

import net.fabricmc.loader.api.FabricLoader;

public final class ConsoleFilterModMenu implements ModMenuApi {

	@Override
	public ConfigScreenFactory<?> getModConfigScreenFactory() {
		return parent -> new ConsoleFilterConfigScreen(
			parent,
			ConsoleFilterFabric.getInstance(),
			() -> FabricLoader.getInstance().getConfigDir().resolve(FilterProfiles.CONFIG_FILE_NAME)
		);
	}
}
