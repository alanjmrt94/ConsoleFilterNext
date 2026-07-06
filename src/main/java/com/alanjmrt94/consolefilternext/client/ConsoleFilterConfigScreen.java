package com.alanjmrt94.consolefilternext.client;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;

public class ConsoleFilterConfigScreen extends Screen {

	private final Screen parent;

	public ConsoleFilterConfigScreen(Screen parent) {
		super(Component.literal("Console Filter Next"));
		this.parent = parent;
	}

	@Override
	protected void init() {
		addRenderableWidget(Button.builder(Component.literal("Done"), button -> onClose())
			.bounds(width / 2 - 50, height - 28, 100, 20)
			.build());
	}

	@Override
	public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
		renderBackground(graphics);
		graphics.drawCenteredString(font, title, width / 2, 24, 0xFFFFFF);
		graphics.drawCenteredString(font, "Edit config/consolefilternext-common.toml", width / 2, 48, 0xCCCCCC);
		graphics.drawCenteredString(font, "Or: Options -> Mods -> Console Filter Next -> Config", width / 2, 64, 0xAAAAAA);
		graphics.drawCenteredString(font, "Server: /consolefilter reload | list | status", width / 2, 88, 0xAAAAAA);
		super.render(graphics, mouseX, mouseY, partialTick);
	}

	@Override
	public void onClose() {
		minecraft.setScreen(parent);
	}
}
