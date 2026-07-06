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
		FilterEntry entry = FilterEntry.wildcard("Player joined", false);
		assertTrue(entry.shouldFilter(sampleMessage()));
	}

	@Test
	void wildcardIgnoresCaseWhenEnabled() {
		FilterEntry entry = FilterEntry.wildcard("player joined", true);
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
		FilterEntry entry = FilterEntry.source("net.minecraft.server", false);
		assertTrue(entry.shouldFilter(sampleMessage()));
		assertFalse(FilterEntry.source("com.example", false).shouldFilter(sampleMessage()));
	}

	@Test
	void sourceFilterIgnoresCaseWhenEnabled() {
		FilterEntry entry = FilterEntry.source("NET.MINECRAFT.SERVER", true);
		assertTrue(entry.shouldFilter(sampleMessage()));
	}

	@Test
	void threadFilterUsesContains() {
		assertTrue(FilterEntry.thread("Server", false).shouldFilter(sampleMessage()));
		assertFalse(FilterEntry.thread("Render", false).shouldFilter(sampleMessage()));
	}

	@Test
	void threadFilterIgnoresCaseWhenEnabled() {
		assertTrue(FilterEntry.thread("server", true).shouldFilter(sampleMessage()));
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

	@Test
	void regexFilterCompilesWithIgnoreCaseFlag() {
		FilterEntry entry = FilterEntry.regex("player", true);
		assertTrue(entry.shouldFilter(sampleMessage()));
	}
}
