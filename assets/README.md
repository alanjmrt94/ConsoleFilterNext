# Assets de distribución

Archivos usados al publicar en Modrinth (y referencia para otras plataformas).

| Archivo | Uso |
|---------|-----|
| `icon.png` | Icono principal del mod (256 KiB máx. en Modrinth). Sustituir aquí para cambiar el icono en tiendas. |
| `modrinth.json` | Metadatos del proyecto Modrinth; lo aplica `publish-release.sh` vía API. |
| `modrinth-body.md` | Descripción larga (campo **body**) del proyecto Modrinth. |
| `modrinth-version-changelog.md` | Changelog de la versión para Modrinth (solo código; usado al publicar el JAR). |
| `modrinth-version-changelog.template.md` | Plantilla del changelog de versión; copiar/actualizar antes de cada release. |
| `modrinth.template.json` | Plantilla documentada; copiar a `modrinth.json` si empezás de cero. |
| `gallery/sample-1.png` | Captura para galería Modrinth (destacada) y CurseForge (panel web) |
| `curseforge.json` | Social links, project links, changelog de versión y galería CurseForge |
| `curseforge-body.md` | Descripción del proyecto CurseForge (pegar manual en Authors; API no lo sincroniza) |
| `curseforge.template.json` | Plantilla documentada; copiar a `curseforge.json` si empezás de cero. |
| `curseforge-version-changelog.md` | Changelog de la versión para CurseForge (solo código; usado al publicar el JAR). |
| `curseforge-version-changelog.template.md` | Plantilla del changelog de versión para CurseForge. |

## Modrinth — checklist del panel

El script `publish_modrinth_sync_metadata` completa por API:

- Descripción corta y larga (`description`, `body`)
- Licencia (`license_id`)
- Icono (`icon_file`)
- Imagen destacada de galería (`gallery` con `featured: true`)
- Enlaces externos (`issues_url`, `source_url`, `wiki_url`)
- Tags / categorías (`categories`)
- Entorno: `client_side` y `server_side` → `optional` (cliente y servidor opcionales)
- Versión: `version_environment` → `client_or_server` (al publicar el JAR)
- Java: `java_versions` → `["Java 17", "Java 21"]` (referencia; CurseForge los aplica en `gameVersions`)

**Submit for review:** con `"submit_for_review": true` en `modrinth.json`, el próximo sync envía el proyecto a moderación de Modrinth (ya activado en este repo). Para no reenviar en cada publish, dejalo en `false` una vez aprobado.

Tras la primera sincronización, podés dejar `"gallery": []` en `modrinth.json` para no reintentar imágenes ya subidas.

## CurseForge — descripción, social links y galería (manual)

La API de CurseForge **no permite** actualizar descripción, social links ni screenshots por REST. Tras `publish`, el script lista los valores de `assets/curseforge.json`.

1. **Descripción del proyecto:** copiá el contenido de [`curseforge-body.md`](curseforge-body.md) en Authors → Description (menciona Forge/Fabric/NeoForge + Discord).
2. **Social links:** editá `social_links` en `curseforge.json`. Las URLs con `{username}` se expanden (por defecto `alanjmrt94`):

| Campo | URL resultante |
|-------|----------------|
| Discord | `https://discord.gg/CcUNTJjPD` (permanente, usos ilimitados) |
| GitHub | `https://github.com/alanjmrt94` |
| X | `https://x.com/alanjmrt94` |
| Instagram | `https://instagram.com/alanjmrt94` |
| Facebook | `https://facebook.com/alanjmrt94` |

Panel: [Authors → proyecto → Links](https://authors.curseforge.com/#/projects/1257873/settings/links) → **Social Links** → Discord = `https://discord.gg/CcUNTJjPD`.

Galería: **Images** / **Gallery** → subir `assets/gallery/sample-1.png`.

**Loaders:** al subir, publicá **tres archivos** (Forge / Fabric / NeoForge) con el game version del loader correcto — no un solo JAR “NeoForge” para todos.

## Sincronizar solo metadatos

```bash
./scripts/release.sh publish --modrinth-sync-only
```

El icono del JAR sigue en `src/main/resources/icon.png`; mantené ambos en sync si cambiás el arte.
