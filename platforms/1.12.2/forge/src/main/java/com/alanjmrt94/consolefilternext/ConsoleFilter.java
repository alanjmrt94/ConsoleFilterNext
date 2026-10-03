package com.alanjmrt94.consolefilternext;

import java.io.File;
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

import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import net.minecraftforge.fml.common.event.FMLServerStartingEvent;

/**
 * Entrada Forge 1.12.2. Feature set reducido: filtro + TOML + comandos. Sin editor in-game.
 */
@Mod(
	modid = ConsoleFilter.MODID,
	name = "Console Filter Next",
	version = ConsoleFilter.VERSION,
	acceptableRemoteVersions = "*",
	updateJSON = ""
)
public class ConsoleFilter implements FilterHost, ConfigScreenHost {

	public static final String MODID = "consolefilternext";
	public static final String VERSION = "1.12.2-4.2.0";
	private static final Pattern LOG_PATTERN = Pattern.compile("\\[(.*?)\\] \\[(.*?)/(.*?)\\] \\[(.*?)\\]: (.*)");
	private static final Logger LOGGER = LogManager.getLogger("ConsoleFilterNext");

	@Mod.Instance(MODID)
	public static ConsoleFilter instance;

	private final LegacyConsoleFilterConfig config = new LegacyConsoleFilterConfig();
	private final FilterStats stats = new FilterStats();
	private final List<CustomFilter> filterRegistry = new ArrayList<CustomFilter>();
	private Path configPath;

	@Mod.EventHandler
	public void preInit(FMLPreInitializationEvent event) {
		ModIdResolver.setLookup(new ForgeModIdLookup());
		File configDir = event.getModConfigurationDirectory();
		configPath = configDir.toPath().resolve(LegacyConsoleFilterConfig.CONFIG_FILE_NAME);
		config.loadFrom(configPath);
	}

	@Mod.EventHandler
	public void init(FMLInitializationEvent event) {
		LOGGER.info("{} message(s) to be filtered.", Integer.valueOf(config.filterCount()));

		filterRegistry.add(new SystemOutFilter(this));
		filterRegistry.add(new SystemErrFilter(this));
		filterRegistry.add(new JavaFilter(this));
		filterRegistry.add(new Log4jFilter(this));
		for (CustomFilter filter : filterRegistry) {
			filter.applyFilter(this);
		}
	}

	@Mod.EventHandler
	public void serverStarting(FMLServerStartingEvent event) {
		event.registerServerCommand(new ConsoleFilterCommand(this));
	}

	public static ConsoleFilter getInstance() {
		return instance;
	}

	@Override
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

	@Override
	public Optional<Path> getConfigPath() {
		return Optional.ofNullable(configPath);
	}
}
