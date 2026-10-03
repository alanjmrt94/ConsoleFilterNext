package com.alanjmrt94.consolefilternext;

import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.alanjmrt94.consolefilternext.filter.CustomFilter;
import com.alanjmrt94.consolefilternext.filter.JavaFilter;
import com.alanjmrt94.consolefilternext.filter.Log4jFilter;
import com.alanjmrt94.consolefilternext.filter.SystemErrFilter;
import com.alanjmrt94.consolefilternext.filter.SystemOutFilter;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.loader.api.FabricLoader;
import net.legacyfabric.fabric.api.registry.CommandRegistry;

/**
 * Entrada Fabric legacy 1.12.2. Feature set reducido: filtro + TOML + comandos. Sin editor in-game.
 */
public final class ConsoleFilterFabric implements ModInitializer, FilterHost, ConfigScreenHost {

	public static final String MODID = "consolefilternext";
	private static final Pattern LOG_PATTERN = Pattern.compile("\\[(.*?)\\] \\[(.*?)/(.*?)\\] \\[(.*?)\\]: (.*)");
	private static final Logger LOGGER = LogManager.getLogger("ConsoleFilterNext");

	private static ConsoleFilterFabric instance;

	private final LegacyConsoleFilterConfig config = new LegacyConsoleFilterConfig();
	private final FilterStats stats = new FilterStats();
	private final List<CustomFilter> filterRegistry = new ArrayList<CustomFilter>();
	private Path configPath;

	@Override
	public void onInitialize() {
		instance = this;
		ModIdResolver.setLookup(new FabricModIdLookup());

		configPath = FabricLoader.getInstance().getConfigDir().resolve(LegacyConsoleFilterConfig.CONFIG_FILE_NAME);
		config.loadFrom(configPath);
		LOGGER.info("{} message(s) to be filtered.", Integer.valueOf(config.filterCount()));

		filterRegistry.add(new SystemOutFilter(this));
		filterRegistry.add(new SystemErrFilter(this));
		filterRegistry.add(new JavaFilter(this));
		filterRegistry.add(new Log4jFilter(this));
		for (CustomFilter filter : filterRegistry) {
			filter.applyFilter(this);
		}

		CommandRegistry.INSTANCE.register(new ConsoleFilterCommand(this));
	}

	public static ConsoleFilterFabric getInstance() {
		return instance;
	}

	public boolean reloadConfigFromDisk() {
		config.reloadFromDisk();
		LOGGER.info("Configuración recargada desde disco: {} filtro(s) activos.", Integer.valueOf(config.filterCount()));
		return true;
	}

	public boolean persistActiveProfile(String profile) {
		String normalized = profile == null || Strings.isBlank(profile)
			? LegacyConsoleFilterConfig.PROFILE_DEFAULT
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
	public LegacyConsoleFilterConfig getConfig() {
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
