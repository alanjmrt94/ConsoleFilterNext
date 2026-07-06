package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class ModIdResolverTest {

	@Test
	void matchesModIdInLoggerName() {
		assertTrue(ModIdResolver.matchesHeuristic("com.simibubi.create.content.kinetics", "create"));
		assertTrue(ModIdResolver.matchesHeuristic("create", "create"));
		assertFalse(ModIdResolver.matchesHeuristic("net.minecraft.server", "create"));
	}
}
