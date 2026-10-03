package com.alanjmrt94.consolefilternext;

/**
 * Punto de entrada del mod hacia el motor de filtrado (adaptadores por loader).
 */
public interface FilterHost {

	boolean shouldFilterMessage(String message);

	FilterConfigView getConfig();

	FilterStats getStats();
}
