# Scripts del repo

## Qué necesita el CI de GitHub

| Script | `build.yml` | `release.yml` | `publish-distribution.yml` | ¿Commitear? |
|--------|:-----------:|:-------------:|:--------------------------:|:-----------:|
| `server-smoke.sh` | sí (smoke) | no | no | **sí** |
| `release.sh` | no | no | sí (`publish`) | **sí** |
| `publish-release.sh` | no | no | sí (incluido por `release.sh`) | **sí** |
| `discord-notify.sh` | no | no | sí (vía `publish`) | **sí** |
| `lint.sh` | **sí** (job `lint`) | no | no | **sí** |
| `matrix.sh` | no | no | no | **sí** (local/dev) |
| `.release.local.example` | no | no | no | **sí** (plantilla) |
| `.release.local` | no | no | no | **nunca** (secretos; ya está en `.gitignore`) |

`release.yml` no usa `scripts/`: construye con `gradlew` / `fabric/gradlew` / `neoforge/gradlew` y publica el GitHub Release con la Action. Los assets esperados son `*-forge.jar`, `*-fabric.jar` y `*-neoforge.jar`.

El job **`lint`** corre primero (`./scripts/lint.sh ci`) y debe pasar **sin warnings de Java ni errores** (Spotless + `-Xlint`/`-Werror`). No se usa `--warning-mode fail` porque ForgeGradle/Loom emiten deprecaciones de Gradle ajenas al proyecto. Los builds de Forge/Fabric/NeoForge dependen de ese job.

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
- **`matrix.sh`**: orquestación local de la matriz MC×loader.

## Comandos útiles

```bash
./scripts/lint.sh ci           # igual que CI (Spotless + -Werror)
./scripts/lint.sh fix          # quita imports no usados, trim, newlines
./scripts/lint.sh check
./scripts/matrix.sh test
./scripts/server-smoke.sh forge   # fabric | neoforge
./scripts/release.sh cut --dry-run
./scripts/release.sh publish --dry-run --skip-build
./scripts/discord-notify.sh --dry-run 1.20.1-4.2.0
```
