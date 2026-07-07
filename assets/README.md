# Assets de distribución

Archivos usados al publicar en Modrinth (y referencia para otras plataformas).

| Archivo | Uso |
|---------|-----|
| `icon.png` | Icono principal del mod (256 KiB máx. en Modrinth). Sustituir aquí para cambiar el icono en tiendas. |
| `modrinth.json` | Metadatos del proyecto Modrinth; lo aplica `publish-release.sh` vía API. |
| `modrinth-body.md` | Descripción larga (campo **body**) del proyecto Modrinth. |
| `modrinth.template.json` | Plantilla documentada; copiar a `modrinth.json` si empezás de cero. |
| `gallery/sample-1.png` | Captura para galería Modrinth (destacada) y CurseForge (panel web) |
| `curseforge.json` | Social links, project links y galería CurseForge (checklist manual tras `publish`) |
| `curseforge.template.json` | Plantilla documentada; copiar a `curseforge.json` si empezás de cero. |

## Modrinth — checklist del panel

El script `publish_modrinth_sync_metadata` completa por API:

- Descripción corta y larga (`description`, `body`)
- Licencia (`license_id`)
- Icono (`icon_file`)
- Imagen destacada de galería (`gallery` con `featured: true`)
- Enlaces externos (`issues_url`, `source_url`, `wiki_url`)
- Tags / categorías (`categories`)

**Submit for review:** con `"submit_for_review": true` en `modrinth.json`, el próximo sync envía el proyecto a moderación de Modrinth (ya activado en este repo). Para no reenviar en cada publish, dejalo en `false` una vez aprobado.

Tras la primera sincronización, podés dejar `"gallery": []` en `modrinth.json` para no reintentar imágenes ya subidas.

## CurseForge — social links y galería (manual)

La API de CurseForge **no permite** actualizar social links ni screenshots por REST. Tras `publish`, el script lista los valores de `assets/curseforge.json`.

Editá `social_username` y `social_links` en `curseforge.json`. Las URLs con `{username}` se expanden con tu usuario (por defecto `alanjmrt94`):

| Campo | URL resultante |
|-------|----------------|
| Discord | `https://discord.gg/qqF5UnHH4` (fija) |
| GitHub | `https://github.com/alanjmrt94` |
| X | `https://x.com/alanjmrt94` |
| Instagram | `https://instagram.com/alanjmrt94` |
| Facebook | `https://facebook.com/alanjmrt94` |

En el panel: [Authors → proyecto → Links](https://authors.curseforge.com/#/projects/1257873/settings/links) → **Social Links**.

Galería: **Images** / **Gallery** → subir `assets/gallery/sample-1.png`.

## Sincronizar solo metadatos

```bash
./scripts/release.sh publish --modrinth-sync-only
```

El icono del JAR sigue en `src/main/resources/icon.png`; mantené ambos en sync si cambiás el arte.
