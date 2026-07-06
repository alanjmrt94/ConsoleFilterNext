package com.alanjmrt94.consolefilternext;

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
				.executes(ctx -> status(ctx.getSource())));
	}

	private static int reload(CommandSourceStack source) {
		ConsoleFilter mod = ConsoleFilter.getInstance();
		if (mod == null) {
			source.sendFailure(Component.literal("Console Filter Next is not initialized."));
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
		ConsoleFilter mod = ConsoleFilter.getInstance();
		if (mod == null) {
			source.sendFailure(Component.literal("Console Filter Next is not initialized."));
			return 0;
		}

		ConsoleFilterConfig.FilterSummary summary = mod.getConfig().getSummary();
		source.sendSuccess(() -> Component.literal(String.format(
			"Filters — basic: %d, regex: %d, level: %d, thread: %d, source: %d (total: %d)",
			summary.basic(),
			summary.regex(),
			summary.level(),
			summary.thread(),
			summary.source(),
			summary.total()
		)), false);
		return 1;
	}

	private static int status(CommandSourceStack source) {
		ConsoleFilter mod = ConsoleFilter.getInstance();
		if (mod == null) {
			source.sendFailure(Component.literal("Console Filter Next is not initialized."));
			return 0;
		}

		ConsoleFilterConfig.FilterSummary summary = mod.getConfig().getSummary();
		source.sendSuccess(() -> Component.literal(String.format(
			"Status — filters: %d, hidden: %d, ignoreCase: %s, whitelistMode: %s",
			summary.total(),
			mod.getStats().getFilteredCount(),
			summary.ignoreCase(),
			summary.whitelistMode()
		)), false);
		return 1;
	}
}
