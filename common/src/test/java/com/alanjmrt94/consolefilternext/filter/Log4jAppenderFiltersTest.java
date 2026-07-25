package com.alanjmrt94.consolefilternext.filter;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.Serializable;

import org.apache.logging.log4j.core.Filter;
import org.apache.logging.log4j.core.Layout;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.appender.AbstractAppender;
import org.apache.logging.log4j.core.appender.ConsoleAppender;
import org.apache.logging.log4j.core.config.Property;
import org.junit.jupiter.api.Test;

class Log4jAppenderFiltersTest {

	@Test
	void attachesToConsoleAlways() {
		ConsoleAppender appender = ConsoleAppender.newBuilder().setName("Console").build();
		assertTrue(Log4jAppenderFilters.shouldAttachFilter(appender, false));
		assertTrue(Log4jAppenderFilters.shouldAttachFilter(appender, true));
	}

	@Test
	void attachesToFileOnlyWhenEnabled() {
		FakeFileAppender appender = new FakeFileAppender();
		assertFalse(Log4jAppenderFilters.shouldAttachFilter(appender, false));
		assertTrue(Log4jAppenderFilters.shouldAttachFilter(appender, true));
	}

	private static final class FakeFileAppender extends AbstractAppender {
		private FakeFileAppender() {
			super("LatestFile", null, (Layout<? extends Serializable>) null, true, Property.EMPTY_ARRAY);
		}

		@Override
		public void append(LogEvent event) {
		}
	}
}
