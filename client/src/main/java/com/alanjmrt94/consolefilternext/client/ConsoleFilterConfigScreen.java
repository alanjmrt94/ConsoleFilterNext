package com.alanjmrt94.consolefilternext.client;

import java.nio.file.Path;
import java.util.function.Supplier;

import com.alanjmrt94.consolefilternext.ConfigFileHelper;
import com.alanjmrt94.consolefilternext.ConfigPreset;
import com.alanjmrt94.consolefilternext.ConfigScreenHost;
import com.alanjmrt94.consolefilternext.FilterProfiles;
import com.alanjmrt94.consolefilternext.client.config.ConfigEditorModel;
import com.mojang.logging.LogUtils;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import org.slf4j.Logger;

public class ConsoleFilterConfigScreen extends Screen {

	private static final Logger LOGGER = LogUtils.getLogger();

	private final Screen parent;
	private final ConfigScreenHost host;
	private final Supplier<Path> fallbackConfigPath;
	private final Path configPath;
	private ConfigEditorModel model;
	private int presetIndex;

	public ConsoleFilterConfigScreen(Screen parent, ConfigScreenHost host, Supplier<Path> fallbackConfigPath) {
		super(Component.literal("Console Filter Next"));
		this.parent = parent;
		this.host = host;
		this.fallbackConfigPath = fallbackConfigPath;
		this.configPath = resolveConfigPath();
		this.model = ConfigEditorModel.load(configPath);
	}

	private Path resolveConfigPath() {
		if (host != null) {
			return host.getConfigPath().orElseGet(fallbackConfigPath);
		}
		return fallbackConfigPath.get();
	}

	@Override
	protected void init() {
		clearWidgets();

		int left = 20;
		int right = width / 2 + 10;
		int buttonWidth = width / 2 - 40;
		int y = 28;

		addRenderableWidget(Button.builder(
			Component.literal("Active profile: " + model.getActiveProfile()),
			button -> {
				model.cycleActiveProfile();
				button.setMessage(Component.literal("Active profile: " + model.getActiveProfile()));
			}
		).bounds(left, y, buttonWidth, 20).build());

		addRenderableWidget(Button.builder(
			Component.literal("Editing profile: " + model.getEditingProfile()),
			button -> {
				model.cycleEditingProfile();
				init();
			}
		).bounds(right, y, buttonWidth, 20).build());
		y += 24;

		addToggle(left, y, buttonWidth, "ignoreCase", model::isIgnoreCase, model::setIgnoreCase);
		addToggle(right, y, buttonWidth, "whitelistMode", model::isWhitelistMode, model::setWhitelistMode);
		y += 24;

		addToggle(left, y, buttonWidth, "filterLatestLog", model::isFilterLatestLog, model::setFilterLatestLog);
		addToggle(right, y, buttonWidth, "skipStackTrace", model::isSkipMessagesWithStackTrace, model::setSkipMessagesWithStackTrace);
		y += 28;

		for (String listKey : ConfigEditorModel.FILTER_LIST_KEYS) {
			int count = model.getFilterList(listKey).size();
			addRenderableWidget(Button.builder(
				Component.literal(ConfigEditorModel.displayNameForList(listKey) + " (" + count + ")"),
				button -> minecraft.setScreen(new FilterListEditScreen(this, model, listKey))
			).bounds(left, y, width - 40, 20).build());
			y += 22;
		}

		ConfigPreset preset = ConfigPreset.all().get(presetIndex);
		addRenderableWidget(Button.builder(
			Component.literal("Preset: " + preset.getLabel()),
			button -> cyclePreset(button)
		).bounds(left, height - 76, 150, 20).build());

		addRenderableWidget(Button.builder(Component.literal("Apply preset"), button -> applyPreset())
			.bounds(left + 156, height - 76, 90, 20).build());
		addRenderableWidget(Button.builder(Component.literal("Import..."), button -> minecraft.setScreen(new ConfigPathScreen(this, model, configPath, true)))
			.bounds(left + 252, height - 76, 70, 20).build());
		addRenderableWidget(Button.builder(Component.literal("Export..."), button -> minecraft.setScreen(new ConfigPathScreen(this, model, configPath, false)))
			.bounds(left + 328, height - 76, 70, 20).build());

		addRenderableWidget(Button.builder(Component.literal("Save & Apply"), button -> saveAndApply())
			.bounds(width / 2 - 155, height - 28, 100, 20).build());
		addRenderableWidget(Button.builder(Component.literal("Reload file"), button -> reloadFromDisk())
			.bounds(width / 2 - 45, height - 28, 100, 20).build());
		addRenderableWidget(Button.builder(Component.literal("Done"), button -> onClose())
			.bounds(width / 2 + 65, height - 28, 80, 20).build());
	}

	private void addToggle(
			int x,
			int y,
			int width,
			String key,
			java.util.function.Supplier<Boolean> getter,
			java.util.function.Consumer<Boolean> setter) {
		boolean enabled = getter.get();
		addRenderableWidget(Button.builder(
			Component.literal(key + ": " + (enabled ? "ON" : "OFF")),
			button -> {
				setter.accept(!getter.get());
				init();
			}
		).bounds(x, y, width, 20).build());
	}

	private void cyclePreset(Button button) {
		presetIndex = (presetIndex + 1) % ConfigPreset.all().size();
		button.setMessage(Component.literal("Preset: " + ConfigPreset.all().get(presetIndex).getLabel()));
	}

	private void applyPreset() {
		try {
			ConfigPreset preset = ConfigPreset.all().get(presetIndex);
			ConfigFileHelper.applyPresetToml(configPath, preset.getToml());
			model = ConfigEditorModel.load(configPath);
			init();
			notifyPlayer("Preset applied: " + preset.getLabel());
		} catch (Exception exception) {
			LOGGER.error("Failed to apply preset", exception);
			notifyPlayer("Failed to apply preset.");
		}
	}

	private void saveAndApply() {
		try {
			model.save(configPath);
			if (host != null) {
				host.reloadConfigFromDisk();
			}
			notifyPlayer("Console Filter Next config saved.");
		} catch (Exception exception) {
			LOGGER.error("Failed to save config from in-game editor", exception);
			notifyPlayer("Failed to save config. See log for details.");
		}
	}

	private void reloadFromDisk() {
		if (host != null) {
			host.reloadConfigFromDisk();
		}
		minecraft.setScreen(new ConsoleFilterConfigScreen(parent, host, fallbackConfigPath));
	}

	private void notifyPlayer(String message) {
		if (minecraft.player != null) {
			minecraft.player.displayClientMessage(Component.literal(message), false);
		}
	}

	@Override
	public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
		renderBackground(graphics);
		graphics.drawCenteredString(font, title, width / 2, 12, 0xFFFFFF);
		graphics.drawString(font, "File: " + configPath.getFileName(), 20, height - 44, 0x888888);
		super.render(graphics, mouseX, mouseY, partialTick);
	}

	@Override
	public void onClose() {
		minecraft.setScreen(parent);
	}

	ConfigEditorModel getModel() {
		return model;
	}

	void setModel(ConfigEditorModel model) {
		this.model = model;
	}

	ConfigScreenHost getHost() {
		return host;
	}

	Path getConfigFilePath() {
		return configPath;
	}

	/** Nombre de archivo de config canónico (documentación / fallbacks). */
	public static String configFileName() {
		return FilterProfiles.CONFIG_FILE_NAME;
	}
}
