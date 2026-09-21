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

import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import net.neoforged.fml.loading.FMLPaths;

/**
 * Adaptador NeoForge moderno (Minecraft 26.2, paquetes {@code net.neoforged.*}).
 */
@Mod(ConsoleFilterNeoForge.MODID)
public final class ConsoleFilterNeoForge implements FilterHost, ConfigScreenHost {

	public static final String MODID = "consolefilternext";
	private static final Pattern LOG_PATTERN = Pattern.compile("\\[(.*?)\\] \\[(.*?)/(.*?)\\] \\[(.*?)\\]: (.*)");
	private static final Logger LOGGER = LogUtils.getLogger();

	private static ConsoleFilterNeoForge instance;

	private final NeoForgeConsoleFilterConfig config = new NeoForgeConsoleFilterConfig();
	private final FilterStats stats = new FilterStats();
	private final List<CustomFilter> filterRegistry = new ArrayList<>();
	private Path configPath;

	public ConsoleFilterNeoForge(IEventBus modEventBus) {
		instance = this;
		ModIdResolver.setLookup(new NeoForgeModIdLookup());

		configPath = FMLPaths.CONFIGDIR.get().resolve(NeoForgeConsoleFilterConfig.CONFIG_FILE_NAME);
		modEventBus.addListener(this::commonSetup);
	}

	public static ConsoleFilterNeoForge getInstance() {
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
			? NeoForgeConsoleFilterConfig.PROFILE_DEFAULT
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
	public NeoForgeConsoleFilterConfig getConfig() {
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
