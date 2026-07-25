package com.alanjmrt94.consolefilternext;

import java.nio.file.Path;
import java.util.Optional;

/**
 * Contrato mínimo del host para el editor in-game (sin APIs de loader).
 */
public interface ConfigScreenHost {

	Optional<Path> getConfigPath();

	boolean reloadConfigFromDisk();
}
