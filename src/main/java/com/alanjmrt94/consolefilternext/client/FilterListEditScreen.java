package com.alanjmrt94.consolefilternext.client;

import java.util.ArrayList;
import java.util.List;

import com.alanjmrt94.consolefilternext.client.config.ConfigEditorModel;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;

public class FilterListEditScreen extends Screen {

	private final Screen parent;
	private final ConfigEditorModel model;
	private final String listKey;
	private final List<String> entries = new ArrayList<>();
	private final List<EditBox> entryBoxes = new ArrayList<>();

	private EditBox addBox;
	private int contentTop = 48;

	public FilterListEditScreen(Screen parent, ConfigEditorModel model, String listKey) {
		super(Component.literal(ConfigEditorModel.displayNameForList(listKey)));
		this.parent = parent;
		this.model = model;
		this.listKey = listKey;
		this.entries.addAll(model.getFilterList(listKey));
	}

	@Override
	protected void init() {
		entryBoxes.clear();
		clearWidgets();

		int rowWidth = width - 80;
		int y = contentTop;
		for (int i = 0; i < entries.size(); i++) {
			final int index = i;
			EditBox box = new EditBox(font, 40, y, rowWidth - 70, 20, Component.empty());
			box.setValue(entries.get(i));
			box.setMaxLength(512);
			entryBoxes.add(box);
			addRenderableWidget(box);
			addRenderableWidget(Button.builder(Component.literal("X"), button -> removeEntry(index))
				.bounds(40 + rowWidth - 60, y, 20, 20)
				.build());
			y += 24;
		}

		addBox = new EditBox(font, 40, height - 84, rowWidth - 110, 20, Component.literal("New entry"));
		addBox.setMaxLength(512);
		addRenderableWidget(addBox);

		addRenderableWidget(Button.builder(Component.literal("Add"), button -> addEntry())
			.bounds(40 + rowWidth - 100, height - 84, 60, 20)
			.build());
		addRenderableWidget(Button.builder(Component.literal("Apply"), button -> applyAndClose())
			.bounds(width / 2 - 110, height - 28, 100, 20)
			.build());
		addRenderableWidget(Button.builder(Component.literal("Back"), button -> onClose())
			.bounds(width / 2 + 10, height - 28, 100, 20)
			.build());
	}

	private void addEntry() {
		String value = addBox.getValue().trim();
		if (!value.isEmpty()) {
			entries.add(value);
			addBox.setValue("");
			rebuildEntriesFromBoxes();
			init();
		}
	}

	private void removeEntry(int index) {
		rebuildEntriesFromBoxes();
		if (index >= 0 && index < entries.size()) {
			entries.remove(index);
			init();
		}
	}

	private void rebuildEntriesFromBoxes() {
		for (int i = 0; i < entryBoxes.size() && i < entries.size(); i++) {
			entries.set(i, entryBoxes.get(i).getValue().trim());
		}
	}

	private void applyAndClose() {
		rebuildEntriesFromBoxes();
		List<String> cleaned = entries.stream().map(String::trim).filter(s -> !s.isEmpty()).toList();
		model.setFilterList(listKey, cleaned);
		onClose();
	}

	@Override
	public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
		renderBackground(graphics);
		graphics.drawCenteredString(font, title, width / 2, 16, 0xFFFFFF);
		graphics.drawCenteredString(
			font,
			"Profile: " + model.getEditingProfile(),
			width / 2,
			30,
			0xAAAAAA
		);
		super.render(graphics, mouseX, mouseY, partialTick);
	}

	@Override
	public void onClose() {
		minecraft.setScreen(parent);
	}
}
