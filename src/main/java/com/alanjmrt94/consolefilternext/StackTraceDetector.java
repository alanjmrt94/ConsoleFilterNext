package com.alanjmrt94.consolefilternext;

public final class StackTraceDetector {

	private StackTraceDetector() {
	}

	public static boolean looksLikeStackTrace(String text) {
		if (text == null || text.isEmpty()) {
			return false;
		}
		return text.contains("\tat ")
			|| text.contains("Caused by:")
			|| text.contains("Exception in thread")
			|| text.contains("Suppressed:");
	}
}
