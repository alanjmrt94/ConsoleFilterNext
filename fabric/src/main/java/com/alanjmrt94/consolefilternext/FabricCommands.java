package com.alanjmrt94.consolefilternext;

import java.io.IOException;
import java.nio.file.Path;
import java.util.Map;
import java.util.Optional;

import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.StringArgumentType;
import com.mojang.brigadier.builder.LiteralArgumentBuilder;

import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.network.chat.Component;

final class FabricCommands {

	private FabricCommands() {
	}

	static void register(ConsoleFilterFabric mod) {
		CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) ->
			registerCommands(dispatcher, mod));
	}

	private static void registerCommands(CommandDispatcher<CommandSourceStack> dispatcher, ConsoleFilterFabric mod) {
		dispatcher.register(buildRoot(mod));
	}

	private static LiteralArgumentBuilder<CommandSourceStack> buildRoot(ConsoleFilterFabric mod) {
		return Commands.literal("consolefilter")
			.requires(source -> source.hasPermission(2))
			.then(Commands.literal("reload")
				.executes(ctx -> reload(ctx.getSource(), mod)))
			.then(Commands.literal("list")
				.executes(ctx -> list(ctx.getSource(), mod)))
			.then(Commands.literal("status")
				.executes(ctx -> status(ctx.getSource(), mod)))
			.then(Commands.literal("export")
				.then(Commands.argument("path", StringArgumentType.greedyString())
					.executes(ctx -> export(ctx.getSource(), mod, StringArgumentType.getString(ctx, "path")))))
			.then(Commands.literal("import")
				.then(Commands.argument("path", StringArgumentType.greedyString())
					.executes(ctx -> importConfig(ctx.getSource(), mod, StringArgumentType.getString(ctx, "path")))))
			.then(Commands.literal("profile")
				.then(Commands.literal("default")
					.executes(ctx -> setProfile(ctx.getSource(), mod, FabricConsoleFilterConfig.PROFILE_DEFAULT)))
				.then(Commands.literal("debug")
					.executes(ctx -> setProfile(ctx.getSource(), mod, FabricConsoleFilterConfig.PROFILE_DEBUG)))
				.then(Commands.literal("production")
					.executes(ctx -> setProfile(ctx.getSource(), mod, FabricConsoleFilterConfig.PROFILE_PRODUCTION))));
	}

	private static int reload(CommandSourceStack source, ConsoleFilterFabric mod) {
		if (!mod.reloadConfigFromDisk()) {
			source.sendFailure(Component.literal("Failed to reload config. Check server logs."));
			return 0;
		}
		FilterSummary summary = mod.getConfig().getSummary();
		source.sendSuccess(
			() -> Component.literal("Console Filter Next config reloaded: " + summary.total() + " active filter(s)."),
			true
		);
		return 1;
	}

	private static int list(CommandSourceStack source, ConsoleFilterFabric mod) {
		FilterSummary summary = mod.getConfig().getSummary();
		source.sendSuccess(() -> Component.literal(String.format(
			"Profile '%s' — basic: %d, regex: %d, level: %d, thread: %d, source/logger: %d, modId: %d (total: %d)",
			summary.activeProfile(),
			summary.basic(),
			summary.regex(),
			summary.level(),
			summary.thread(),
			summary.source(),
			summary.modId(),
			summary.total()
		)), false);
		return 1;
	}

	private static int status(CommandSourceStack source, ConsoleFilterFabric mod) {
		FilterSummary summary = mod.getConfig().getSummary();
		Map<FilterType, Long> byType = mod.getStats().snapshotByType();
		source.sendSuccess(() -> Component.literal(String.format(
			"Status — profile: %s, filters: %d, hidden: %d, ignoreCase: %s, whitelistMode: %s, filterLatestLog: %s, skipStackTrace: %s",
			summary.activeProfile(),
			summary.total(),
			mod.getStats().getFilteredCount(),
			summary.ignoreCase(),
			summary.whitelistMode(),
			summary.filterLatestLog(),
			summary.skipMessagesWithStackTrace()
		)), false);
		source.sendSuccess(() -> Component.literal(String.format(
			"Hits — basic: %d, regex: %d, level: %d, thread: %d, source: %d, logger: %d, modId: %d",
			byType.get(FilterType.BASIC),
			byType.get(FilterType.REGEX),
			byType.get(FilterType.LEVEL),
			byType.get(FilterType.THREAD),
			byType.get(FilterType.SOURCE),
			byType.get(FilterType.LOGGER),
			byType.get(FilterType.MOD_ID)
		)), false);
		return 1;
	}

	private static int export(CommandSourceStack source, ConsoleFilterFabric mod, String pathString) {
		Optional<Path> configPath = mod.getConfigPath();
		if (configPath.isEmpty()) {
			source.sendFailure(Component.literal("Config path is not available."));
			return 0;
		}
		Path target = Path.of(pathString);
		try {
			ConfigFileHelper.exportConfig(configPath.get(), target);
			source.sendSuccess(() -> Component.literal("Exported config to " + target), true);
			return 1;
		} catch (IOException exception) {
			source.sendFailure(Component.literal("Export failed: " + exception.getMessage()));
			return 0;
		}
	}

	private static int importConfig(CommandSourceStack source, ConsoleFilterFabric mod, String pathString) {
		if (mod.getConfigPath().isEmpty()) {
			source.sendFailure(Component.literal("Config path is not available."));
			return 0;
		}
		Path sourcePath = Path.of(pathString);
		try {
			ConfigFileHelper.importConfig(sourcePath, mod.getConfigPath().get());
			mod.reloadConfigFromDisk();
			FilterSummary summary = mod.getConfig().getSummary();
			source.sendSuccess(
				() -> Component.literal("Imported config from " + sourcePath + " (" + summary.total() + " filter(s))."),
				true
			);
			return 1;
		} catch (IOException exception) {
			source.sendFailure(Component.literal("Import failed: " + exception.getMessage()));
			return 0;
		}
	}

	private static int setProfile(CommandSourceStack source, ConsoleFilterFabric mod, String profile) {
		if (!mod.persistActiveProfile(profile)) {
			source.sendFailure(Component.literal("Failed to persist profile to config file."));
			return 0;
		}
		FilterSummary summary = mod.getConfig().getSummary();
		source.sendSuccess(
			() -> Component.literal("Active profile set to '" + summary.activeProfile() + "' (" + summary.total() + " filter(s), saved to TOML)."),
			true
		);
		return 1;
	}
}
