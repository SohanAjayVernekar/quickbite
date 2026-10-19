# QuickBite visual assets

The current interface uses warm ivory, white, terracotta orange and fresh green. The typography uses explicit dark colours on light surfaces; forest green panels have separate light text tokens. Inter remains the primary interface font. The original licensed font files are retained.

`frontend/assets/images/dish-*.jpg` contains curated images for 135 distinct recipe names. The `generated/` folder contains a deterministic, name-specific illustration for each additional menu item and portion variant listed in `generated/index.json`. The frontend resolver uses the exact product name first and preserves product-specific paths, so a cuisine cover cannot replace a dish image. If an unknown product has no specific image, the UI shows an unavailable-image placeholder instead of an unrelated dish. Images are bundled with Flutter; the app has no external image-service dependency.

The art direction is natural food photography with soft daylight, warm ivory tabletops, appropriate dishes or glasses and visible recipe ingredients. The images are AI-generated illustrations for a fictional menu. Regular/sharing portions and identical recipes in different kitchens share their recipe image. Different recipes have separate assets. Restaurant covers rotate among actual recipes from each kitchen's menu.

Original images and their attribution remain available for compatibility with old references. See `FOOD_IMAGE_CREDITS.md` for that provenance and `FOOD_IMAGE_PROMPTS.json` for the current generation prompts.

Floating elements and gentle decorative particles remain native Flutter effects and respect both the animation switch and the system's reduced-motion setting. Cart confirmation remains visible as text when animations are disabled.
