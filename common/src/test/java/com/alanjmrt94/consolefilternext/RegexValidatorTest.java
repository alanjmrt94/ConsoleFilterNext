package com.alanjmrt94.consolefilternext;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class RegexValidatorTest {

	@Test
	void acceptsValidPattern() {
		assertTrue(RegexValidator.isValid(".*ERROR.*", false));
	}

	@Test
	void rejectsInvalidPattern() {
		assertFalse(RegexValidator.isValid("[unclosed", false));
	}
}
