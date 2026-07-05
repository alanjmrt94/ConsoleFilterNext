package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.regex.Pattern;

import org.junit.jupiter.api.Test;

class FilterEntryTest {

	private LogMessage sampleMessage() {
		return new LogMessage(
			"12:00:00",
			"Server thread",
			"INFO",
			"net.minecraft.server.MinecraftServer",
			"Player joined"
		);
	}

	@Test
	void wildcardMatchesSubstring() {
		FilterEntry entry = FilterEntry.wildcard("Player joined");
		assertTrue(entry.shouldFilter(sampleMessage()));
	}

	@Test
	void levelFilterIsCaseInsensitive() {
		FilterEntry entry = FilterEntry.level("info");
		assertTrue(entry.shouldFilter(sampleMessage()));
		assertFalse(FilterEntry.level("ERROR").shouldFilter(sampleMessage()));
	}

	@Test
	void sourceFilterUsesContains() {
		FilterEntry entry = FilterEntry.source("net.minecraft.server");
		assertTrue(entry.shouldFilter(sampleMessage()));
		assertFalse(FilterEntry.source("com.example").shouldFilter(sampleMessage()));
	}

	@Test
	void threadFilterRequiresExactMatch() {
		assertTrue(FilterEntry.thread("Server thread").shouldFilter(sampleMessage()));
		assertFalse(FilterEntry.thread("Server").shouldFilter(sampleMessage()));
	}

	@Test
	void regexFilterUsesFindNotFullMatch() {
		FilterEntry entry = FilterEntry.regex(Pattern.compile("Player"));
		assertTrue(entry.shouldFilter(sampleMessage()));
	}

	@Test
	void regexFilterMatchesFullFormattedMessage() {
		FilterEntry entry = FilterEntry.regex(Pattern.compile("^\\[12:00:00\\]"));
		assertTrue(entry.shouldFilter(sampleMessage()));
	}
}
