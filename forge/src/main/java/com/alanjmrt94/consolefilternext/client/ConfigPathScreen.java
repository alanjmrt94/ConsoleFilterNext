package com.alanjmrt94.consolefilternext.client;

import java.nio.file.Path;

import com.alanjmrt94.consolefilternext.ConsoleFilter;
import com.alanjmrt94.consolefilternext.client.config.ConfigEditorModel;
import com.mojang.logging.LogUtils;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import org.slf4j.Logger;

public class ConfigPathScreen extends Screen {

	private static final Logger LOGGER = LogUtils.getLogger();

	private final ConsoleFilterConfigScreen parent;
	private final ConfigEditorModel model;
	private final Path configPath;
	private final boolean importMode;

	private EditBox pathBox;
	private String statusMessage = "";

	public ConfigPathScreen(ConsoleFilterConfigScreen parent, ConfigEditorModel model, Path configPath, boolean importMode) {
		super(Component.literal(importMode ? "Import config" : "Export config"));
		this.parent = parent;
		this.model = model;
		this.configPath = configPath;
		this.importMode = importMode;
	}

	@Override
	protected void init() {
		int fieldWidth = width - 80;
		pathBox = new EditBox(font, 40, height / 2 - 10, fieldWidth, 20, Component.literal("Path"));
		pathBox.setMaxLength(512);
		pathBox.setValue(importMode ? "backups/consolefilter.toml" : "backups/consolefilter-export.toml");
		addRenderableWidget(pathBox);

		addRenderableWidget(Button.builder(Component.literal(importMode ? "Import" : "Export"), button -> runAction())
			.bounds(width / 2 - 110, height / 2 + 24, 100, 20).build());
		addRenderableWidget(Button.builder(Component.literal("Back"), button -> onClose())
			.bounds(width / 2 + 10, height / 2 + 24, 100, 20).build());
	}

	private void runAction() {
		Path target = Path.of(pathBox.getValue().trim());
		try {
			if (importMode) {
				model.importFrom(target, configPath);
				parent.setModel(ConfigEditorModel.load(configPath));
				ConsoleFilter mod = ConsoleFilter.getInstance();
				if (mod != null) {
					mod.reloadConfigFromDisk();
				}
				statusMessage = "Imported from " + target;
			} else {
				model.exportTo(target, configPath);
				statusMessage = "Exported to " + target;
			}
			onClose();
		} catch (Exception exception) {
			LOGGER.error("Config file transfer failed", exception);
			statusMessage = "Failed: " + exception.getMessage();
		}
	}

	@Override
	public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
		renderBackground(graphics);
		graphics.drawCenteredString(font, title, width / 2, height / 2 - 36, 0xFFFFFF);
		graphics.drawCenteredString(font, "Relative to game directory", width / 2, height / 2 - 22, 0xAAAAAA);
		if (!statusMessage.isEmpty()) {
			graphics.drawCenteredString(font, statusMessage, width / 2, height / 2 + 56, 0xFF5555);
		}
		super.render(graphics, mouseX, mouseY, partialTick);
	}

	@Override
	public void onClose() {
		minecraft.setScreen(parent);
		parent.init();
	}
}
