QuickBite all-dishes image update

The update includes the full bundled image gallery, exact-name photo mappings, and one generated illustration for every current menu dish without an exact photo match. The generated artwork is included so dishes continue to show an image even when no photo file exists.

Apply the ZIP at the QuickBite project root and allow files to be replaced. Then refresh the backend demo menu paths:
  python -m app.database.resync_menus

For newly added dish names, generate any missing illustration files before building the Flutter app:
  python3 scripts/generate_dish_images.py

The image generator requires Pillow. No tests were run for this update.
