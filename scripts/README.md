# Scripts del repo

## Qué necesita el CI de GitHub

| Script | `build.yml` | `release.yml` | `publish-distribution.yml` | ¿Commitear? |
|--------|:-----------:|:-------------:|:--------------------------:|:-----------:|
| `server-smoke.sh` | sí (smoke) | no | no | **sí** |
| `release.sh` | no | no | sí (`publish`) | **sí** |
| `publish-release.sh` | no | no | sí (incluido por `release.sh`) | **sí** |
| `discord-notify.sh` | no | no | sí (vía `publish`) | **sí** |
| `lint.sh` | **sí** (`lint`) | no | no | **sí** |
| `ci-retry-gradle.sh` | sí (NeoForge, matrices 1.19/1.20/1.21, warm smoke) | sí (vía `cf_gradle` / celdas) | sí (vía `cf_gradle` / celdas) | **sí** |
| `check-client-drift.sh` | sí (vía `lint.sh ci`) | no | no | **sí** |
| `matrix.sh` | no | no | no | **sí** (local/dev; lanza cada wrapper con el JDK de launcher) |
| `.release.local.example` | no | no | no | **sí** (plantilla) |
| `.release.local` | no | no | no | **nunca** (secretos; ya está en `.gitignore`) |

`release.yml` y `publish-distribution.yml` construyen con `gradlew` / wrappers bajo `platforms/` y reintentan fallos transitorios con `ci-retry-gradle.sh`. Los assets esperados son `*-forge.jar`, `*-fabric.jar` y `*-neoforge.jar` según la línea MC.

El job **`lint`** corre primero (`./scripts/lint.sh ci`) y debe pasar **sin warnings de Java ni errores** (Spotless en todo `platforms/*`, drift de `client/`, `-Xlint`/`-Werror` en common+Forge 1.20.1). No se usa `--warning-mode fail` porque ForgeGradle/Loom emiten deprecaciones de Gradle ajenas al proyecto. Los `-Werror` del resto de loaders viven en cada job de build.

### `ci-retry-gradle.sh`

Reintenta `./gradlew` en una celda `platforms/{mc}/{loader}` (por defecto 3 intentos, sleep 20s; override con `CI_GRADLE_RETRIES` / `CI_GRADLE_RETRY_SLEEP`). Cubre HTTP 502 de Maven NeoForge y otros fallos transitorios de resolución. En smoke 1.21 también calienta userdev antes del `runServer` (timeout smoke 480s).

## Flujo de release + Discord

```bash
# 1) Push a master y esperá Build verde
# 2) Cortá el tag solo si CI pasó:
./scripts/release.sh cut
./scripts/release.sh cut --dry-run

# Actions (tag push):
#   release.yml              → GitHub Release + JARs
#   publish-distribution.yml → Modrinth + CurseForge + Discord webhook
```

### Republicar sin mover tags (`workflow_dispatch`)

Si un tag ya se publicó con un workflow viejo (paths Forge incorrectos, loader Fabric en vez de `legacy-fabric`, etc.), **no hace falta retaguear**:

1. Merge/push a `master` con el workflow y el código correctos; esperá **Build** verde.
2. Actions → **Release** → Run workflow → input `mc` (p. ej. `1.20.1`) — reconstruye JARs desde la rama actual y actualiza el GitHub Release del tag `{mc}-{semver}` (`allowUpdates` + `replacesArtifacts`).
3. Actions → **Publish distribution** → Run workflow → mismo `mc` — publica Modrinth/CurseForge/Discord desde la rama actual (lee `mod_version` de `versions/{mc}.properties` o `gradle.properties` para 1.20.1).

Líneas que suelen necesitar republicar tras el arreglo 4.2.0: `1.20.1`, `1.21.1`, `1.16.5`, `1.16.1`, `1.12.2`, `1.8.9`.

Secret **`DISCORD_WEBHOOK_URL`**: GitHub → Settings → Environments → **`publish`** → Environment secrets (no Variable). Local: `scripts/.release.local`.

Un Incoming Webhook = un canal = un mod. El webhook es la “llave”; no uses tu login de Discord en el script.

### Canales Discord (setup manual)

| Canal | Quién escribe | Uso |
|-------|---------------|-----|
| `#bienvenida` | Solo vos/staff | Bienvenida fijada; @everyone solo lectura |
| `#console-filter-next` | Vos + webhook CI | Releases del mod; @everyone solo lectura |
| `#general` | Todos | Chat |

Webhook: Edit channel del mod → Integrations → Webhooks → Copy URL → secret `DISCORD_WEBHOOK_URL`.

## Qué no quitar del repo

- **`release.sh` + `publish-release.sh`**: necesarios para publicar a Modrinth/CurseForge en CI y en local.
- **`discord-notify.sh`**: aviso al canal del mod tras publicar.
- **`server-smoke.sh`**: necesario para el job de smoke en `build.yml`.
- **`lint.sh`**: gate de CI + autofix local.
- **`ci-retry-gradle.sh`**: reintentos Gradle ante 502/Maven transitorio en Build, Release y Publish.
- **`matrix.sh`**: orquestación local de la matriz MC×loader.

## Comandos útiles

```bash
./scripts/lint.sh ci           # igual que CI (Spotless + drift client + -Werror 1.20.1)
./scripts/lint.sh fix          # quita imports no usados, trim, newlines
./scripts/lint.sh check
./scripts/matrix.sh test
./scripts/server-smoke.sh forge   # fabric | neoforge | forge-1.20.4 | neoforge-1.20.6 | forge-26.1 | …
./scripts/release.sh cut --dry-run
./scripts/release.sh publish --dry-run --skip-build
./scripts/discord-notify.sh --dry-run 1.20.1-4.2.0
```
