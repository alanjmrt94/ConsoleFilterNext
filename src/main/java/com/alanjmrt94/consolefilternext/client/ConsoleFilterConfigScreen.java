package com.alanjmrt94.consolefilternext.client;

import java.nio.file.Path;

import com.alanjmrt94.consolefilternext.ConsoleFilter;
import com.alanjmrt94.consolefilternext.client.config.ConfigEditorModel;
import com.mojang.logging.LogUtils;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import net.minecraftforge.fml.loading.FMLPaths;
import org.slf4j.Logger;

public class ConsoleFilterConfigScreen extends Screen {

	private static final Logger LOGGER = LogUtils.getLogger();

	private final Screen parent;
	private final Path configPath;
	private final ConfigEditorModel model;

	private Button ignoreCaseButton;
	private Button whitelistButton;
	private Button filterLogButton;
	private Button activeProfileButton;
	private Button editingProfileButton;

	public ConsoleFilterConfigScreen(Screen parent) {
		super(Component.literal("Console Filter Next"));
		this.parent = parent;
		this.configPath = resolveConfigPath();
		this.model = ConfigEditorModel.load(configPath);
	}

	private static Path resolveConfigPath() {
		ConsoleFilter mod = ConsoleFilter.getInstance();
		if (mod != null) {
			return mod.getConfigPath().orElseGet(() -> defaultConfigPath());
		}
		return defaultConfigPath();
	}

	private static Path defaultConfigPath() {
		return FMLPaths.CONFIGDIR.get().resolve("consolefilternext-common.toml");
	}

	@Override
	protected void init() {
		int left = 20;
		int buttonWidth = 220;
		int y = 36;

		activeProfileButton = addRenderableWidget(Button.builder(
			Component.literal("Active profile: " + model.getActiveProfile()),
			button -> cycleActiveProfile(button)
		).bounds(left, y, buttonWidth, 20).build());
		y += 28;

		editingProfileButton = addRenderableWidget(Button.builder(
			Component.literal("Editing profile: " + model.getEditingProfile()),
			button -> cycleEditingProfile(button)
		).bounds(left, y, buttonWidth, 20).build());
		y += 28;

		ignoreCaseButton = addRenderableWidget(Button.builder(
			toggleLabel("ignoreCase", model.isIgnoreCase()),
			button -> toggleIgnoreCase(button)
		).bounds(left, y, buttonWidth, 20).build());
		y += 24;

		whitelistButton = addRenderableWidget(Button.builder(
			toggleLabel("whitelistMode", model.isWhitelistMode()),
			button -> toggleWhitelist(button)
		).bounds(left, y, buttonWidth, 20).build());
		y += 24;

		filterLogButton = addRenderableWidget(Button.builder(
			toggleLabel("filterLatestLog", model.isFilterLatestLog()),
			button -> toggleFilterLog(button)
		).bounds(left, y, buttonWidth, 20).build());
		y += 32;

		for (String listKey : ConfigEditorModel.FILTER_LIST_KEYS) {
			final String key = listKey;
			int count = model.getFilterList(key).size();
			addRenderableWidget(Button.builder(
				Component.literal(ConfigEditorModel.displayNameForList(key) + " (" + count + ")"),
				button -> minecraft.setScreen(new FilterListEditScreen(this, model, key))
			).bounds(left, y, buttonWidth, 20).build());
			y += 24;
		}

		addRenderableWidget(Button.builder(Component.literal("Save & Apply"), button -> saveAndApply())
			.bounds(width / 2 - 155, height - 28, 100, 20).build());
		addRenderableWidget(Button.builder(Component.literal("Reload file"), button -> reloadFromDisk())
			.bounds(width / 2 - 45, height - 28, 100, 20).build());
		addRenderableWidget(Button.builder(Component.literal("Done"), button -> onClose())
			.bounds(width / 2 + 65, height - 28, 80, 20).build());
	}

	private void cycleActiveProfile(Button button) {
		model.cycleActiveProfile();
		button.setMessage(Component.literal("Active profile: " + model.getActiveProfile()));
	}

	private void cycleEditingProfile(Button button) {
		model.cycleEditingProfile();
		button.setMessage(Component.literal("Editing profile: " + model.getEditingProfile()));
		rebuildFilterButtons();
	}

	private void toggleIgnoreCase(Button button) {
		model.setIgnoreCase(!model.isIgnoreCase());
		button.setMessage(toggleLabel("ignoreCase", model.isIgnoreCase()));
	}

	private void toggleWhitelist(Button button) {
		model.setWhitelistMode(!model.isWhitelistMode());
		button.setMessage(toggleLabel("whitelistMode", model.isWhitelistMode()));
	}

	private void toggleFilterLog(Button button) {
		model.setFilterLatestLog(!model.isFilterLatestLog());
		button.setMessage(toggleLabel("filterLatestLog", model.isFilterLatestLog()));
	}

	private void rebuildFilterButtons() {
		init();
	}

	private void saveAndApply() {
		try {
			model.save(configPath);
			ConsoleFilter mod = ConsoleFilter.getInstance();
			if (mod != null) {
				mod.reloadConfigFromDisk();
			}
			if (minecraft.player != null) {
				minecraft.player.displayClientMessage(
					Component.literal("Console Filter Next config saved."),
					false
				);
			}
		} catch (Exception e) {
			LOGGER.error("Failed to save config from in-game editor", e);
			if (minecraft.player != null) {
				minecraft.player.displayClientMessage(
					Component.literal("Failed to save config. See log for details."),
					false
				);
			}
		}
	}

	private void reloadFromDisk() {
		ConsoleFilter mod = ConsoleFilter.getInstance();
		if (mod != null) {
			mod.reloadConfigFromDisk();
		}
		minecraft.setScreen(new ConsoleFilterConfigScreen(parent));
	}

	private static Component toggleLabel(String key, boolean enabled) {
		return Component.literal(key + ": " + (enabled ? "ON" : "OFF"));
	}

	@Override
	public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
		renderBackground(graphics);
		graphics.drawCenteredString(font, title, width / 2, 12, 0xFFFFFF);
		graphics.drawString(
			font,
			"File: " + configPath.getFileName(),
			20,
			height - 44,
			0x888888
		);
		super.render(graphics, mouseX, mouseY, partialTick);
	}

	@Override
	public void onClose() {
		minecraft.setScreen(parent);
	}
}
