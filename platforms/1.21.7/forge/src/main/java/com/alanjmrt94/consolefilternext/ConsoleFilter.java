package com.alanjmrt94.consolefilternext;

import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.slf4j.Logger;

import com.alanjmrt94.consolefilternext.filter.CustomFilter;
import com.alanjmrt94.consolefilternext.filter.JavaFilter;
import com.alanjmrt94.consolefilternext.filter.Log4jFilter;
import com.alanjmrt94.consolefilternext.filter.SystemErrFilter;
import com.alanjmrt94.consolefilternext.filter.SystemOutFilter;
import com.mojang.logging.LogUtils;

import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.eventbus.api.bus.BusGroup;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.event.lifecycle.FMLCommonSetupEvent;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;
import net.minecraftforge.fml.loading.FMLEnvironment;
import net.minecraftforge.fml.loading.FMLPaths;

/**
 * Adaptador Forge (Minecraft 1.21.7, EventBus 7).
 */
@Mod(ConsoleFilter.MODID)
public final class ConsoleFilter implements FilterHost, ConfigScreenHost {

	public static final String MODID = "consolefilternext";
	private static final Pattern LOG_PATTERN = Pattern.compile("\\[(.*?)\\] \\[(.*?)/(.*?)\\] \\[(.*?)\\]: (.*)");
	private static final Logger LOGGER = LogUtils.getLogger();

	private static ConsoleFilter instance;

	private final ConsoleFilterConfig config = new ConsoleFilterConfig();
	private final FilterStats stats = new FilterStats();
	private final List<CustomFilter> filterRegistry = new ArrayList<>();
	private Path configPath;

	public ConsoleFilter(FMLJavaModLoadingContext context) {
		instance = this;
		ModIdResolver.setLookup(new ForgeModIdLookup());

		configPath = FMLPaths.CONFIGDIR.get().resolve(ConsoleFilterConfig.CONFIG_FILE_NAME);

		BusGroup modBusGroup = context.getModBusGroup();
		FMLCommonSetupEvent.getBus(modBusGroup).addListener(this::commonSetup);
		ConsoleFilterCommands.register();

		if (FMLEnvironment.dist == Dist.CLIENT) {
			ConsoleFilterClient.register(context);
		}
	}

	public static ConsoleFilter getInstance() {
		return instance;
	}

	private void commonSetup(final FMLCommonSetupEvent event) {
		config.loadFrom(configPath);
		LOGGER.info("{} message(s) to be filtered.", config.filterCount());

		filterRegistry.add(new SystemOutFilter(this));
		filterRegistry.add(new SystemErrFilter(this));
		filterRegistry.add(new JavaFilter(this));
		filterRegistry.add(new Log4jFilter(this));
		for (CustomFilter filter : filterRegistry) {
			filter.applyFilter(this);
		}
	}

	public boolean reloadConfigFromDisk() {
		config.reloadFromDisk();
		LOGGER.info("Configuración recargada desde disco: {} filtro(s) activos.", config.filterCount());
		return true;
	}

	public boolean persistActiveProfile(String profile) {
		String normalized = profile == null || profile.isBlank()
			? ConsoleFilterConfig.PROFILE_DEFAULT
			: profile;
		try {
			ConfigFileHelper.setActiveProfile(configPath, normalized);
			return reloadConfigFromDisk();
		} catch (IOException exception) {
			LOGGER.error("No se pudo persistir activeProfile en TOML", exception);
			return false;
		}
	}

	@Override
	public boolean shouldFilterMessage(String message) {
		if (message == null) {
			return false;
		}

		FilterEvaluation evaluation;
		Matcher matcher = LOG_PATTERN.matcher(message);
		if (matcher.matches()) {
			LogMessage logMessage = new LogMessage(
				matcher.group(1),
				matcher.group(2),
				matcher.group(3),
				matcher.group(4),
				matcher.group(5)
			);
			evaluation = config.evaluate(logMessage);
		} else {
			evaluation = config.evaluatePlain(message);
		}

		if (evaluation.filtered()) {
			if (evaluation.matchType() != null) {
				stats.recordFiltered(evaluation.matchType());
			} else {
				stats.recordFiltered();
			}
		}

		return evaluation.filtered();
	}

	@Override
	public ConsoleFilterConfig getConfig() {
		return config;
	}

	@Override
	public FilterStats getStats() {
		return stats;
	}

	public Optional<Path> getConfigPath() {
		return Optional.ofNullable(configPath);
	}
}
