package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class LogMessageTest {

	@Test
	void fullMessageUsesForgeLogFormat() {
		LogMessage message = new LogMessage(
			"12:00:00",
			"Server thread",
			"INFO",
			"net.minecraft.server.MinecraftServer",
			"Done"
		);

		assertEquals(
			"[12:00:00] [Server thread/INFO] [net.minecraft.server.MinecraftServer]: Done",
			message.getFullMessage()
		);
	}
}
