package com.alanjmrt94.consolefilternext;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

import net.minecraft.command.CommandBase;
import net.minecraft.command.CommandException;
import net.minecraft.command.ICommandSender;
import net.minecraft.util.BlockPos;
import net.minecraft.util.ChatComponentText;

/**
 * Comandos legacy 1.8.9 (API CommandBase antigua).
 */
final class ConsoleFilterCommand extends CommandBase {

	private final ConsoleFilter mod;

	ConsoleFilterCommand(ConsoleFilter mod) {
		this.mod = mod;
	}

	@Override
	public String getCommandName() {
		return "consolefilter";
	}

	@Override
	public String getCommandUsage(ICommandSender sender) {
		return "/consolefilter <reload|list|status|profile|export|import>";
	}

	@Override
	public int getRequiredPermissionLevel() {
		return 2;
	}

	@Override
	public void processCommand(ICommandSender sender, String[] args) throws CommandException {
		if (args.length == 0) {
			throw new CommandException(getCommandUsage(sender));
		}

		String action = args[0].toLowerCase(Locale.ROOT);
		if ("reload".equals(action)) {
			if (!mod.reloadConfigFromDisk()) {
				throw new CommandException("Failed to reload config.");
			}
			sender.addChatMessage(new ChatComponentText(
				"Console Filter Next config reloaded: " + mod.getConfig().filterCount() + " active filter(s)."));
			return;
		}
		if ("list".equals(action)) {
			FilterSummary summary = mod.getConfig().getSummary();
			sender.addChatMessage(new ChatComponentText(String.format(
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
			sender.addChatMessage(new ChatComponentText(String.format(
				"Status — profile: %s, filters: %d, hidden: %d",
				summary.activeProfile(),
				Integer.valueOf(summary.total()),
				Long.valueOf(mod.getStats().getFilteredCount())
			)));
			sender.addChatMessage(new ChatComponentText(String.format(
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
			sender.addChatMessage(new ChatComponentText(
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
				sender.addChatMessage(new ChatComponentText("Exported config to " + target));
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
			Path source = Paths.get(joinArgs(args, 1));
			try {
				ConfigFileHelper.importConfig(source, configPath.get());
				mod.reloadConfigFromDisk();
				sender.addChatMessage(new ChatComponentText(
					"Imported config from " + source + " (" + mod.getConfig().filterCount() + " filter(s))."));
			} catch (IOException exception) {
				throw new CommandException("Import failed: " + exception.getMessage());
			}
			return;
		}
		throw new CommandException(getCommandUsage(sender));
	}

	@Override
	public List<String> addTabCompletionOptions(ICommandSender sender, String[] args, BlockPos pos) {
		if (args.length == 1) {
			return getListOfStringsMatchingLastWord(args, "reload", "list", "status", "profile", "export", "import");
		}
		if (args.length == 2 && "profile".equalsIgnoreCase(args[0])) {
			return getListOfStringsMatchingLastWord(args, "default", "debug", "production");
		}
		return null;
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
