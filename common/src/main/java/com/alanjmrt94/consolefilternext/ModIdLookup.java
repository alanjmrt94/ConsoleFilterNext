package com.alanjmrt94.consolefilternext;

/**
 * Resolución de mod id específica del loader (Forge/Fabric/NeoForge).
 */
@FunctionalInterface
public interface ModIdLookup {

	boolean matchesNamespace(String source, String modId);
}
