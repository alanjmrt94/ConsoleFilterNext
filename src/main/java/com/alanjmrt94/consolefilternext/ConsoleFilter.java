package com.alanjmrt94.consolefilternext;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.slf4j.Logger;

import com.alanjmrt94.consolefilternext.filter.CustomFilter;
import com.alanjmrt94.consolefilternext.filter.JavaFilter;
import com.alanjmrt94.consolefilternext.filter.Log4jFilter;
import com.alanjmrt94.consolefilternext.filter.SystemFilter;
import com.mojang.logging.LogUtils;

import net.minecraftforge.fml.ModLoadingContext;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.config.ModConfig;
import net.minecraftforge.fml.event.lifecycle.FMLCommonSetupEvent;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;

@Mod(ConsoleFilter.MODID)
public class ConsoleFilter {

	public static final String MODID = "consolefilter";
	private static final Pattern LOG_PATTERN = Pattern.compile("\\[(.*?)\\] \\[(.*?)/(.*?)\\] \\[(.*?)\\]: (.*)");

	private static final Logger LOGGER = LogUtils.getLogger();

	private final ConsoleFilterConfig config = new ConsoleFilterConfig();
	private final List<CustomFilter> filterRegistry = new ArrayList<>();

	public ConsoleFilter() {
		config.init();

		FMLJavaModLoadingContext.get().getModEventBus().addListener(this::commonSetup);
		ModLoadingContext.get().registerConfig(ModConfig.Type.COMMON, config.getSpec(), "consolefilter-common.toml");
	}

	private void commonSetup(final FMLCommonSetupEvent event) {
		config.load();

		LOGGER.info(config.filterCount() + " message(s) to be filtered.");

		filterRegistry.add(new SystemFilter(this));
		filterRegistry.add(new JavaFilter(this));
		filterRegistry.add(new Log4jFilter(this));

		for (CustomFilter filter : filterRegistry) {
			filter.applyFilter(this);
		}
	}

	public boolean shouldFilter(String message) {
		Matcher matcher = LOG_PATTERN.matcher(message);
		if (matcher.matches()) {
			LogMessage logMessage = new LogMessage(
				matcher.group(1), // timestamp
				matcher.group(2), // thread
				matcher.group(3), // level
				matcher.group(4), // source
				matcher.group(5)  // message
			);
			return config.shouldFilter(logMessage);
		}
		return false;
	}

	public ConsoleFilterConfig getConfig() {
		return config;
	}
}
