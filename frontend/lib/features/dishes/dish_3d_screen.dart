import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

/// Picks a 3D model for a dish based on its name, so every dish gets a
/// consistent model without needing 8,867 separate files.
String modelForDish(String name) {
  final n = name.toLowerCase();
  String base;
  if (n.contains('sushi') || n.contains('maki') || n.contains('roll') ||
      n.contains('nigiri') || n.contains('prawn') || n.contains('fish') ||
      n.contains('salmon') || n.contains('tuna') || n.contains('crab') ||
      n.contains('shrimp') || n.contains('seafood') || n.contains('squid')) {
    base = 'BarramundiFish.glb';
  } else if (n.contains('avocado') || n.contains('guacamole') ||
      n.contains('salad') || n.contains('green') ||
      n.contains('vegetable') || n.contains('veg')) {
    base = 'Avocado.glb';
  } else if (n.contains('bottle') || n.contains('drink') || n.contains('juice') ||
      n.contains('tea') || n.contains('coffee') || n.contains('lassi') ||
      n.contains('soda') || n.contains('lemonade') || n.contains('water') ||
      n.contains('milkshake') || n.contains('smoothie') || n.contains('chai')) {
    base = 'WaterBottle.glb';
  } else if (n.contains('duck') || n.contains('poultry') ||
      n.contains('chicken') || n.contains('turkey')) {
    base = 'Duck.glb';
  } else if (n.contains('fox') || n.contains('meat') || n.contains('lamb') ||
      n.contains('mutton') || n.contains('beef') || n.contains('pork')) {
    base = 'Fox.glb';
  } else if (n.contains('burger') || n.contains('sandwich')) {
    base = 'BoomBox.glb';
  } else if (n.contains('lamp') || n.contains('lantern') ||
      n.contains('light')) {
    base = 'Lantern.glb';
  } else if (n.contains('rice') || n.contains('noodle') ||
      n.contains('pasta') || n.contains('spaghetti')) {
    base = 'ToyCar.glb';
  } else if (n.contains('brain') || n.contains('stem')) {
    base = 'BrainStem.glb';
  } else {
    base = 'IridescentDishWithOlives.glb';
  }
  // Web serves assets under assets/assets/; mobile loads via rootBundle using
  // the asset key, which is assets/models/.
  return kIsWeb ? 'assets/assets/models/$base' : 'assets/models/$base';
}

class Dish3DScreen extends StatelessWidget {
  final String id;
  final String name;
  const Dish3DScreen({super.key, required this.id, required this.name});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(name),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: ModelViewer(
            src: modelForDish(name),
            alt: '3D model of $name',
            ar: true,
            autoRotate: true,
            cameraControls: true,
            backgroundColor: QB.surface,
            loading: Loading.auto,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Drag to rotate · pinch to zoom · AR on supported devices',
            style: const TextStyle(color: QB.muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
