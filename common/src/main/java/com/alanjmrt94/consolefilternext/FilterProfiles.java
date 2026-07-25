package com.alanjmrt94.consolefilternext;

import java.util.List;

/**
 * Nombres de perfil de configuración compartidos entre loaders y el editor in-game.
 */
public final class FilterProfiles {

	public static final String DEFAULT = "default";
	public static final String DEBUG = "debug";
	public static final String PRODUCTION = "production";

	public static final List<String> ALL = List.of(DEFAULT, DEBUG, PRODUCTION);

	public static final String CONFIG_FILE_NAME = "consolefilternext-common.toml";

	private FilterProfiles() {
	}
}
