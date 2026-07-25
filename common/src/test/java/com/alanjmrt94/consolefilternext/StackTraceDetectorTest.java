package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class StackTraceDetectorTest {

	@Test
	void detectsStackTraceLines() {
		assertTrue(StackTraceDetector.looksLikeStackTrace("\tat net.minecraft.server.MinecraftServer.run"));
		assertTrue(StackTraceDetector.looksLikeStackTrace("Caused by: java.lang.RuntimeException"));
		assertFalse(StackTraceDetector.looksLikeStackTrace("[Server thread/INFO]: Done"));
	}
}
