package com.alanjmrt94.consolefilternext;

final class Strings {

	private Strings() {
	}

	static boolean isBlank(String value) {
		return value == null || value.trim().isEmpty();
	}
}
