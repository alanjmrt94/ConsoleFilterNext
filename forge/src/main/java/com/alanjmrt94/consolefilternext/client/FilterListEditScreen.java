package com.alanjmrt94.consolefilternext.client;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import com.alanjmrt94.consolefilternext.RegexValidator;
import com.alanjmrt94.consolefilternext.client.config.ConfigEditorModel;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;

public class FilterListEditScreen extends Screen {

	private static final int ENTRIES_PER_PAGE = 8;
	private static final int ROW_HEIGHT = 24;

	private final Screen parent;
	private final ConfigEditorModel model;
	private final String listKey;
	private final List<String> entries = new ArrayList<>();
	private final List<EditBox> entryBoxes = new ArrayList<>();

	private EditBox addBox;
	private int pageIndex;
	private int contentTop = 48;
	private String validationMessage = "";

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
		validationMessage = "";

		int rowWidth = width - 80;
		int maxPage = Math.max(0, (entries.size() - 1) / ENTRIES_PER_PAGE);
		pageIndex = Math.min(pageIndex, maxPage);

		int start = pageIndex * ENTRIES_PER_PAGE;
		int end = Math.min(start + ENTRIES_PER_PAGE, entries.size());
		int y = contentTop;

		for (int i = start; i < end; i++) {
			final int index = i;
			EditBox box = new EditBox(font, 40, y, rowWidth - 70, 20, Component.empty());
			box.setValue(entries.get(i));
			box.setMaxLength(512);
			entryBoxes.add(box);
			addRenderableWidget(box);
			addRenderableWidget(Button.builder(Component.literal("X"), button -> removeEntry(index))
				.bounds(40 + rowWidth - 60, y, 20, 20)
				.build());
			y += ROW_HEIGHT;
		}

		if (entries.size() > ENTRIES_PER_PAGE) {
			addRenderableWidget(Button.builder(Component.literal("<"), button -> changePage(-1))
				.bounds(40, height - 108, 20, 20)
				.build());
			addRenderableWidget(Button.builder(Component.literal(">"), button -> changePage(1))
				.bounds(66, height - 108, 20, 20)
				.build());
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

	private void changePage(int delta) {
		rebuildEntriesFromBoxes();
		int maxPage = Math.max(0, (entries.size() - 1) / ENTRIES_PER_PAGE);
		pageIndex = Math.max(0, Math.min(pageIndex + delta, maxPage));
		init();
	}

	private void addEntry() {
		String value = addBox.getValue().trim();
		if (!value.isEmpty()) {
			if (ConfigEditorModel.isRegexList(listKey)) {
				Optional<String> error = RegexValidator.validate(value, model.isIgnoreCase());
				if (error.isPresent()) {
					validationMessage = error.get();
					return;
				}
			}
			entries.add(value);
			addBox.setValue("");
			validationMessage = "";
			rebuildEntriesFromBoxes();
			pageIndex = Math.max(0, (entries.size() - 1) / ENTRIES_PER_PAGE);
			init();
		}
	}

	private void removeEntry(int index) {
		rebuildEntriesFromBoxes();
		if (index >= 0 && index < entries.size()) {
			entries.remove(index);
			int maxPage = Math.max(0, (entries.size() - 1) / ENTRIES_PER_PAGE);
			pageIndex = Math.min(pageIndex, maxPage);
			init();
		}
	}

	private void rebuildEntriesFromBoxes() {
		int start = pageIndex * ENTRIES_PER_PAGE;
		for (int i = 0; i < entryBoxes.size(); i++) {
			int entryIndex = start + i;
			if (entryIndex < entries.size()) {
				entries.set(entryIndex, entryBoxes.get(i).getValue().trim());
			}
		}
	}

	private void applyAndClose() {
		rebuildEntriesFromBoxes();
		if (ConfigEditorModel.isRegexList(listKey)) {
			for (String entry : entries) {
				if (entry.isBlank()) {
					continue;
				}
				Optional<String> error = RegexValidator.validate(entry, model.isIgnoreCase());
				if (error.isPresent()) {
					validationMessage = "Invalid regex: " + error.get();
					return;
				}
			}
		}

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

		if (entries.size() > ENTRIES_PER_PAGE) {
			int maxPage = Math.max(0, (entries.size() - 1) / ENTRIES_PER_PAGE);
			graphics.drawString(
				font,
				"Page " + (pageIndex + 1) + "/" + (maxPage + 1) + " (" + entries.size() + " entries)",
				92,
				height - 102,
				0xAAAAAA
			);
		}

		if (ConfigEditorModel.isRegexList(listKey)) {
			int start = pageIndex * ENTRIES_PER_PAGE;
			for (int i = 0; i < entryBoxes.size(); i++) {
				String value = entryBoxes.get(i).getValue();
				if (!value.isBlank()) {
					Optional<String> error = RegexValidator.validate(value, model.isIgnoreCase());
					int color = error.isPresent() ? 0xFF5555 : 0x55FF55;
					graphics.drawString(font, error.isPresent() ? "!" : "OK", 24, contentTop + i * ROW_HEIGHT + 6, color);
				}
				int entryIndex = start + i;
				if (entryIndex < entries.size()) {
					entries.set(entryIndex, value.trim());
				}
			}
		}

		if (!validationMessage.isEmpty()) {
			graphics.drawCenteredString(font, validationMessage, width / 2, height - 56, 0xFF5555);
		}

		super.render(graphics, mouseX, mouseY, partialTick);
	}

	@Override
	public void onClose() {
		minecraft.setScreen(parent);
	}
}
