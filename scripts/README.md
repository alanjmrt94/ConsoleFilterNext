# Scripts del repo

## Qué necesita el CI de GitHub

| Script | `build.yml` | `release.yml` | `publish-distribution.yml` | ¿Commitear? |
|--------|:-----------:|:-------------:|:--------------------------:|:-----------:|
| `server-smoke.sh` | sí (smoke) | no | no | **sí** |
| `release.sh` | no | no | sí (`publish`) | **sí** |
| `publish-release.sh` | no | no | sí (incluido por `release.sh`) | **sí** |
| `lint.sh` | **sí** (job `lint`) | no | no | **sí** |
| `matrix.sh` | no | no | no | **sí** (local/dev) |
| `.release.local.example` | no | no | no | **sí** (plantilla) |
| `.release.local` | no | no | no | **nunca** (secretos; ya está en `.gitignore`) |

`release.yml` no usa `scripts/`: construye con `gradlew` / `fabric/gradlew` / `neoforge/gradlew` y publica el GitHub Release con la Action. Los assets esperados son `*-forge.jar`, `*-fabric.jar` y `*-neoforge.jar`.

El job **`lint`** corre primero (`./scripts/lint.sh ci`) y debe pasar **sin warnings ni errores** (Spotless + `-Xlint`/`-Werror` + `--warning-mode fail`). Los builds de Forge/Fabric/NeoForge dependen de ese job.

## Qué no quitar del repo

- **`release.sh` + `publish-release.sh`**: necesarios para publicar a Modrinth/CurseForge en CI y en local.
- **`server-smoke.sh`**: necesario para el job de smoke en `build.yml`.
- **`lint.sh`**: gate de CI + autofix local.
- **`matrix.sh`**: orquestación local de la matriz MC×loader.

## Comandos útiles

```bash
./scripts/lint.sh ci           # igual que CI (falla con warnings)
./scripts/lint.sh fix          # quita imports no usados, trim, newlines
./scripts/lint.sh check
./scripts/matrix.sh test
./scripts/server-smoke.sh forge   # fabric | neoforge
./scripts/release.sh publish --dry-run --skip-build
```
