package com.alanjmrt94.consolefilternext;

/**
 * Vista de configuración usada por los filtros en runtime (sin dependencias de loader).
 */
public interface FilterConfigView {

	boolean shouldFilter(LogMessage message);

	FilterEvaluation evaluate(LogMessage message);

	FilterEvaluation evaluatePlain(String text);

	boolean isFilterLatestLog();

	boolean isSkipMessagesWithStackTrace();
}
