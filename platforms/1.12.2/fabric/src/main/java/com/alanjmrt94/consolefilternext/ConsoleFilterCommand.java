package com.alanjmrt94.consolefilternext;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

import net.minecraft.command.AbstractCommand;
import net.minecraft.command.CommandException;
import net.minecraft.command.CommandSource;
import net.minecraft.server.MinecraftServer;
import net.minecraft.text.LiteralText;
import net.minecraft.util.math.BlockPos;

/**
 * Comandos Fabric legacy 1.12.2 (Yarn): reload, list, status, profile, export, import.
 */
final class ConsoleFilterCommand extends AbstractCommand {

	private final ConsoleFilterFabric mod;

	ConsoleFilterCommand(ConsoleFilterFabric mod) {
		this.mod = mod;
	}

	@Override
	public String getCommandName() {
		return "consolefilter";
	}

	@Override
	public String getUsageTranslationKey(CommandSource source) {
		return "/consolefilter <reload|list|status|profile|export|import>";
	}

	@Override
	public int getPermissionLevel() {
		return 2;
	}

	@Override
	public void method_3279(MinecraftServer server, CommandSource source, String[] args) throws CommandException {
		if (args.length == 0) {
			throw new CommandException(getUsageTranslationKey(source));
		}

		String action = args[0].toLowerCase(Locale.ROOT);
		if ("reload".equals(action)) {
			if (!mod.reloadConfigFromDisk()) {
				throw new CommandException("Failed to reload config.");
			}
			source.sendMessage(new LiteralText(
				"Console Filter Next config reloaded: " + mod.getConfig().filterCount() + " active filter(s)."));
			return;
		}
		if ("list".equals(action)) {
			FilterSummary summary = mod.getConfig().getSummary();
			source.sendMessage(new LiteralText(String.format(
				"Profile '%s' — basic: %d, regex: %d, level: %d, thread: %d, source/logger: %d, modId: %d (total: %d)",
				summary.activeProfile(),
				Integer.valueOf(summary.basic()),
				Integer.valueOf(summary.regex()),
				Integer.valueOf(summary.level()),
				Integer.valueOf(summary.thread()),
				Integer.valueOf(summary.source()),
				Integer.valueOf(summary.modId()),
				Integer.valueOf(summary.total())
			)));
			return;
		}
		if ("status".equals(action)) {
			FilterSummary summary = mod.getConfig().getSummary();
			Map<FilterType, Long> byType = mod.getStats().snapshotByType();
			source.sendMessage(new LiteralText(String.format(
				"Status — profile: %s, filters: %d, hidden: %d",
				summary.activeProfile(),
				Integer.valueOf(summary.total()),
				Long.valueOf(mod.getStats().getFilteredCount())
			)));
			source.sendMessage(new LiteralText(String.format(
				"Hits — basic: %d, regex: %d, level: %d, thread: %d, source: %d, logger: %d, modId: %d",
				byType.get(FilterType.BASIC),
				byType.get(FilterType.REGEX),
				byType.get(FilterType.LEVEL),
				byType.get(FilterType.THREAD),
				byType.get(FilterType.SOURCE),
				byType.get(FilterType.LOGGER),
				byType.get(FilterType.MOD_ID)
			)));
			return;
		}
		if ("profile".equals(action)) {
			if (args.length < 2) {
				throw new CommandException("/consolefilter profile <default|debug|production>");
			}
			String profile = args[1].toLowerCase(Locale.ROOT);
			if (!mod.persistActiveProfile(profile)) {
				throw new CommandException("Failed to persist profile.");
			}
			FilterSummary summary = mod.getConfig().getSummary();
			source.sendMessage(new LiteralText(
				"Active profile set to '" + summary.activeProfile() + "' (" + summary.total() + " filter(s))."));
			return;
		}
		if ("export".equals(action)) {
			if (args.length < 2) {
				throw new CommandException("/consolefilter export <path>");
			}
			Optional<Path> configPath = mod.getConfigPath();
			if (!configPath.isPresent()) {
				throw new CommandException("Config path is not available.");
			}
			Path target = Paths.get(joinArgs(args, 1));
			try {
				ConfigFileHelper.exportConfig(configPath.get(), target);
				source.sendMessage(new LiteralText("Exported config to " + target));
			} catch (IOException exception) {
				throw new CommandException("Export failed: " + exception.getMessage());
			}
			return;
		}
		if ("import".equals(action)) {
			if (args.length < 2) {
				throw new CommandException("/consolefilter import <path>");
			}
			Optional<Path> configPath = mod.getConfigPath();
			if (!configPath.isPresent()) {
				throw new CommandException("Config path is not available.");
			}
			Path importSource = Paths.get(joinArgs(args, 1));
			try {
				ConfigFileHelper.importConfig(importSource, configPath.get());
				mod.reloadConfigFromDisk();
				source.sendMessage(new LiteralText(
					"Imported config from " + importSource + " (" + mod.getConfig().filterCount() + " filter(s))."));
			} catch (IOException exception) {
				throw new CommandException("Import failed: " + exception.getMessage());
			}
			return;
		}
		throw new CommandException(getUsageTranslationKey(source));
	}

	@Override
	public List<String> method_10738(MinecraftServer server, CommandSource source, String[] args, BlockPos pos) {
		if (args.length == 1) {
			return method_2894(args, "reload", "list", "status", "profile", "export", "import");
		}
		if (args.length == 2 && "profile".equalsIgnoreCase(args[0])) {
			return method_2894(args, "default", "debug", "production");
		}
		return Collections.emptyList();
	}

	private static String joinArgs(String[] args, int start) {
		StringBuilder builder = new StringBuilder();
		for (int i = start; i < args.length; i++) {
			if (i > start) {
				builder.append(' ');
			}
			builder.append(args[i]);
		}
		return builder.toString();
	}
}
