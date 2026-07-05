package com.alanjmrt94.consolefilternext;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.slf4j.Logger;

import com.alanjmrt94.consolefilternext.filter.CustomFilter;
import com.alanjmrt94.consolefilternext.filter.JavaFilter;
import com.alanjmrt94.consolefilternext.filter.Log4jFilter;
import com.alanjmrt94.consolefilternext.filter.SystemErrFilter;
import com.alanjmrt94.consolefilternext.filter.SystemOutFilter;
import com.mojang.logging.LogUtils;

import net.minecraftforge.fml.ModLoadingContext;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.config.ModConfig;
import net.minecraftforge.fml.event.config.ModConfigEvent;
import net.minecraftforge.fml.event.lifecycle.FMLCommonSetupEvent;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;

@Mod(ConsoleFilter.MODID)
public class ConsoleFilter {

	public static final String MODID = "consolefilternext";
	private static final Pattern LOG_PATTERN = Pattern.compile("\\[(.*?)\\] \\[(.*?)/(.*?)\\] \\[(.*?)\\]: (.*)");

	private static final Logger LOGGER = LogUtils.getLogger();

	private final ConsoleFilterConfig config = new ConsoleFilterConfig();
	private final List<CustomFilter> filterRegistry = new ArrayList<>();

	public ConsoleFilter() {
		config.init();

		var modEventBus = FMLJavaModLoadingContext.get().getModEventBus();
		modEventBus.addListener(this::commonSetup);
		modEventBus.addListener(this::onConfigEvent);

		ModLoadingContext.get().registerConfig(ModConfig.Type.COMMON, config.getSpec(), "consolefilternext-common.toml");
	}

	private void commonSetup(final FMLCommonSetupEvent event) {
		config.load();
		LOGGER.info(config.filterCount() + " message(s) to be filtered.");

		filterRegistry.add(new SystemOutFilter(this));
		filterRegistry.add(new SystemErrFilter(this));
		filterRegistry.add(new JavaFilter(this));
		filterRegistry.add(new Log4jFilter(this));

		for (CustomFilter filter : filterRegistry) {
			filter.applyFilter(this);
		}
	}

	private void onConfigEvent(ModConfigEvent event) {
		if (!MODID.equals(event.getConfig().getModId())) {
			return;
		}
		if (event.getConfig().getType() != ModConfig.Type.COMMON) {
			return;
		}
		if (event instanceof ModConfigEvent.Loading || event instanceof ModConfigEvent.Reloading) {
			config.load();
			if (event instanceof ModConfigEvent.Reloading) {
				LOGGER.info("Configuración recargada: {} filtro(s) activos.", config.filterCount());
			}
		}
	}

	public boolean shouldFilterMessage(String message) {
		if (message == null) {
			return false;
		}

		Matcher matcher = LOG_PATTERN.matcher(message);
		if (matcher.matches()) {
			LogMessage logMessage = new LogMessage(
				matcher.group(1),
				matcher.group(2),
				matcher.group(3),
				matcher.group(4),
				matcher.group(5)
			);
			return config.shouldFilter(logMessage);
		}

		return config.shouldFilterPlain(message);
	}

	public ConsoleFilterConfig getConfig() {
		return config;
	}
}
