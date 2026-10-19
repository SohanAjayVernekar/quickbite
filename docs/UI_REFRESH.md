# QuickBite — brighter food app update

## What changed

- Warm ivory page backgrounds, white cards, terracotta orange actions and fresh green accents.
- Explicit dark text colours for headings, descriptions, fields, prices, filters and navigation. Dark forest banners use their own light text colours.
- More readable food-card text, larger food images, gentle shadows and a softer peach-and-sage hero.
- A separate, locally bundled image for each of the 135 distinct recipe names. A dal bowl, curry, pizza, drink or dessert is no longer assigned an unrelated cuisine photo.
- Restaurant covers are selected from their own menu recipes. The frontend respects each cover instead of replacing it with one image for the whole cuisine.
- Older saved cart entries resolve the new artwork by dish name. A missing asset shows a clearly labelled placeholder instead of an unrelated meal.
- Regular/sharing portions and the same named recipe at different fictional kitchens intentionally use the same recipe artwork.
- Existing motion controls, floating elements, navigation, authentication, cart and ordering behaviour remain in place.

## Apply to an existing project

Extract this ZIP into a separate directory, then run:

```bash
bash /path/to/extracted/quickbite-food-delivery/APPLY-UI-UPDATE.sh /path/to/your/quickbite-food-delivery
cd /path/to/your/quickbite-food-delivery
bash scripts/start.sh
```

The apply script copies only the files listed in `docs/UI_UPDATE_FILES.json` and backs up existing copies under `.ui-backups/`. It does not copy `.env`, Compose files, Dockerfiles, port configuration or existing startup scripts. Your database and broker volumes are retained. The normal startup command rebuilds the app and refreshes seeded image fields without deleting orders or accounts.

If this is a fresh installation, enter the extracted project folder and run `bash scripts/start.sh` directly.

## Ports and execution

All supplied port settings are unchanged: the existing defaults remain web 8080, API 8000 and RabbitMQ management 15672. Existing `.env` overrides stay in place. Open your usual app URL after startup. If an old web app remains cached, use a hard refresh (Ctrl+Shift+R).

At the user's request, no tests, builds, analyzers, app launches or browser checks were run for this update. The commands above are for the user to run locally. Existing test files and historical evidence remain in the project; they do not validate this update.

## Image provenance

The new recipe images were made with the built-in image generator and bundled as optimized JPEG assets. They are illustrations for fictional menus, not photographs of food supplied by actual restaurants. The prompt list is in `docs/FOOD_IMAGE_PROMPTS.json`. No external image request is needed when the application runs.
