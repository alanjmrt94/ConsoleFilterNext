package com.alanjmrt94.consolefilternext;

import java.io.IOException;
import java.nio.file.Path;
import java.util.Map;
import java.util.Optional;

import com.mojang.brigadier.arguments.StringArgumentType;
import com.mojang.brigadier.builder.LiteralArgumentBuilder;

import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.network.chat.Component;
import net.minecraftforge.event.RegisterCommandsEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

@Mod.EventBusSubscriber(modid = ConsoleFilter.MODID)
public class ConsoleFilterCommands {

	private ConsoleFilterCommands() {
	}

	@SubscribeEvent
	public static void onRegisterCommands(RegisterCommandsEvent event) {
		event.getDispatcher().register(buildRoot());
	}

	private static LiteralArgumentBuilder<CommandSourceStack> buildRoot() {
		return Commands.literal("consolefilter")
			.requires(source -> source.hasPermission(2))
			.then(Commands.literal("reload")
				.executes(ctx -> reload(ctx.getSource())))
			.then(Commands.literal("list")
				.executes(ctx -> list(ctx.getSource())))
			.then(Commands.literal("status")
				.executes(ctx -> status(ctx.getSource())))
			.then(Commands.literal("export")
				.then(Commands.argument("path", StringArgumentType.greedyString())
					.executes(ctx -> export(ctx.getSource(), StringArgumentType.getString(ctx, "path")))))
			.then(Commands.literal("import")
				.then(Commands.argument("path", StringArgumentType.greedyString())
					.executes(ctx -> importConfig(ctx.getSource(), StringArgumentType.getString(ctx, "path")))))
			.then(Commands.literal("profile")
				.then(Commands.literal("default")
					.executes(ctx -> setProfile(ctx.getSource(), ConsoleFilterConfig.PROFILE_DEFAULT)))
				.then(Commands.literal("debug")
					.executes(ctx -> setProfile(ctx.getSource(), ConsoleFilterConfig.PROFILE_DEBUG)))
				.then(Commands.literal("production")
					.executes(ctx -> setProfile(ctx.getSource(), ConsoleFilterConfig.PROFILE_PRODUCTION))));
	}

	private static ConsoleFilter requireMod(CommandSourceStack source) {
		ConsoleFilter mod = ConsoleFilter.getInstance();
		if (mod == null) {
			source.sendFailure(Component.literal("Console Filter Next is not initialized."));
		}
		return mod;
	}

	private static int reload(CommandSourceStack source) {
		ConsoleFilter mod = requireMod(source);
		if (mod == null) {
			return 0;
		}

		if (!mod.reloadConfigFromDisk()) {
			source.sendFailure(Component.literal("Failed to reload config. Check server logs."));
			return 0;
		}

		ConsoleFilterConfig.FilterSummary summary = mod.getConfig().getSummary();
		source.sendSuccess(
			() -> Component.literal("Console Filter Next config reloaded: " + summary.total() + " active filter(s)."),
			true
		);
		return 1;
	}

	private static int list(CommandSourceStack source) {
		ConsoleFilter mod = requireMod(source);
		if (mod == null) {
			return 0;
		}

		ConsoleFilterConfig.FilterSummary summary = mod.getConfig().getSummary();
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

	private static int status(CommandSourceStack source) {
		ConsoleFilter mod = requireMod(source);
		if (mod == null) {
			return 0;
		}

		ConsoleFilterConfig.FilterSummary summary = mod.getConfig().getSummary();
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

	private static int export(CommandSourceStack source, String pathString) {
		ConsoleFilter mod = requireMod(source);
		if (mod == null) {
			return 0;
		}

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

	private static int importConfig(CommandSourceStack source, String pathString) {
		ConsoleFilter mod = requireMod(source);
		if (mod == null) {
			return 0;
		}

		if (mod.getConfigPath().isEmpty()) {
			source.sendFailure(Component.literal("Config path is not available."));
			return 0;
		}

		Path sourcePath = Path.of(pathString);
		try {
			ConfigFileHelper.importConfig(sourcePath, mod.getConfigPath().get());
			mod.reloadConfigFromDisk();
			ConsoleFilterConfig.FilterSummary summary = mod.getConfig().getSummary();
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

	private static int setProfile(CommandSourceStack source, String profile) {
		ConsoleFilter mod = requireMod(source);
		if (mod == null) {
			return 0;
		}

		if (!mod.persistActiveProfile(profile)) {
			source.sendFailure(Component.literal("Failed to persist profile to config file."));
			return 0;
		}

		ConsoleFilterConfig.FilterSummary summary = mod.getConfig().getSummary();
		source.sendSuccess(
			() -> Component.literal("Active profile set to '" + summary.activeProfile() + "' (" + summary.total() + " filter(s), saved to TOML)."),
			true
		);
		return 1;
	}
}
