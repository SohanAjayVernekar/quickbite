import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui.dart';
import '../models/food_photos.dart';

/// The in-app switch and the platform preference both stop decorative motion.
class MotionPreferences extends ChangeNotifier {
  bool enabled = true;
  void toggle() {
    enabled = !enabled;
    notifyListeners();
  }
}

class Glitter extends StatefulWidget {
  const Glitter({super.key});
  @override
  State<Glitter> createState() => _GlitterState();
}

class _GlitterState extends State<Glitter> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 11),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GlitterPainter(controller),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

class _GlitterPainter extends CustomPainter {
  final Animation<double> animation;
  _GlitterPainter(this.animation) : super(repaint: animation);
  @override
  void paint(Canvas canvas, Size size) {
    // Warm ember glow, hand-drawn flame ribbons and slowly rising sparks.
    final glow = Paint()..shader = RadialGradient(
      colors: [QB.fire.withValues(alpha: .10), QB.gold.withValues(alpha: .04), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * .78, size.height * 1.03), radius: size.width * .55));
    canvas.drawRect(Offset.zero & size, glow);
    for (var i = 0; i < 7; i++) {
      final wave = math.sin(animation.value * math.pi * 2 + i * 1.4);
      final x = size.width * (.57 + i * .055);
      final base = size.height + 35;
      final height = 90.0 + i % 3 * 34 + wave * 14;
      final path = Path()..moveTo(x - 25, base)
        ..cubicTo(x - 46, base - height * .42, x + 22 + wave * 9, base - height * .63, x + wave * 12, base - height)
        ..cubicTo(x + 35, base - height * .65, x + 44, base - height * .25, x + 25, base)..close();
      final flame = Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
        colors: [QB.fire.withValues(alpha: .10), QB.gold.withValues(alpha: .075), Colors.transparent])
        .createShader(Rect.fromLTWH(x - 50, base - height, 100, height));
      canvas.drawPath(path, flame);
    }
    for (var i = 0; i < 31; i++) {
      final progress = (animation.value + i * .137) % 1;
      final x = size.width * ((i * 37 + 11) % 97) / 97 + math.sin(progress * math.pi * 2 + i) * 13;
      final y = size.height * (1 - progress);
      final alpha = math.sin(progress * math.pi) * (.28 + (i % 3) * .14);
      final point = Offset(x, y);
      final paint = Paint()..color = (i.isEven ? QB.fire : QB.ember).withValues(alpha: alpha);
      canvas.drawCircle(point, 1.2 + (i % 3) * .5, paint);
      if (i % 3 == 0) {
        paint..strokeWidth = .8..strokeCap = StrokeCap.round;
        canvas.drawLine(point, point + const Offset(-2, 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlitterPainter old) =>
      old.animation != animation;
}

class FoodHero extends StatelessWidget {
  final VoidCallback onExplore;
  final bool compact;
  const FoodHero({super.key, required this.onExplore, this.compact = false});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF0DF), Color(0xFFFFF8EC), Color(0xFFEFF5E7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: QB.gold.withValues(alpha: .2)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        children: [
          const Positioned.fill(child: Glitter()),
          Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 24 : 42,
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 680;
                final copy = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: QB.gold.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'FRESH FLAVOURS. HAPPY DAYS.',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w800,
                          color: QB.gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Good food.\nGreat mood.',
                      style: TextStyle(
                        fontSize: wide ? (compact ? 46 : 62) : 38,
                        height: 1.05,
                        letterSpacing: -2.1,
                        fontWeight: FontWeight.w900,
                        color: QB.text,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Fresh favourites, comforting classics and a little\nhappiness. Find your next delicious bite.',
                      style: TextStyle(
                        color: QB.muted,
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: onExplore,
                      label: const Text('Find my next bite'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      iconAlignment: IconAlignment.end,
                    ),
                    const SizedBox(height: 22),
                    const Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      children: [
                        _HeroNote(
                          Icons.restaurant_menu,
                          'Made for every craving',
                        ),
                        _HeroNote(
                          Icons.favorite_rounded,
                          'A little everyday joy',
                        ),
                      ],
                    ),
                  ],
                );
                final art = SizedBox(
                  height: wide ? (compact ? 325 : 365) : 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [QB.fire.withValues(alpha: .28), QB.fire.withValues(alpha: .04), Colors.transparent]),
                          border: Border.all(color: QB.gold.withValues(alpha: .12), width: 1),
                          boxShadow: [BoxShadow(color: QB.fire.withValues(alpha: .1), blurRadius: 80, spreadRadius: 20)],
                        ),
                      ),
                      const Positioned.fill(
                        child: FloatingFood(
                          child: FoodImage(
                            'dish-paneer-dum-biryani.jpg',
                            fit: BoxFit.contain,
                            showCredit: false,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 0,
                        child: Transform.rotate(
                          angle: .075,
                          child: const FloatingFood(
                            child: _FoodTag(
                              icon: Icons.local_fire_department,
                              title: 'Craving approved',
                              subtitle: 'Big on flavour',
                              color: QB.gold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 0,
                        child: Transform.rotate(
                          angle: -.065,
                          child: const FloatingFood(
                            child: _FoodTag(
                              icon: Icons.favorite,
                              title: 'Made with love',
                              subtitle: 'The good stuff, always',
                              color: QB.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                return wide
                    ? Row(
                        children: [
                          Expanded(flex: 11, child: copy),
                          const SizedBox(width: 12),
                          Expanded(flex: 10, child: art),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [copy, const SizedBox(height: 24), art],
                      );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeroNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroNote(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: QB.green),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12, color: QB.text)),
    ],
  );
}

class _FoodTag extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _FoodTag({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: QB.raised.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: QB.ink.withValues(alpha: .10),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: QB.muted),
            ),
          ],
        ),
      ],
    ),
  );
}

const cuisineEmoji = <String, String>{
  'Indian': '🍛',
  'Italian': '🍕',
  'Burgers': '🍔',
  'Asian': '🍜',
  'South Indian': '🥞',
  'Mexican': '🌮',
  'Japanese': '🍣',
  'Thai': '🍜',
  'Korean': '🍲',
  'Mediterranean': '🥙',
  'Lebanese': '🧆',
  'Healthy': '🥗',
  'Desserts': '🍰',
  'Bakery': '🥐',
  'Breakfast': '🧇',
  'Street Food': '🥟',
  'Seafood': '🍤',
  'BBQ': '🍢',
  'Beverages': '🧋',
  'Bengali': '🍛',
};

class CuisineStrip extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final List<String> cuisines;
  const CuisineStrip({
    super.key,
    this.selected = '',
    required this.onSelected,
    this.cuisines = const [],
  });

  @override
  State<CuisineStrip> createState() => _CuisineStripState();
}

class _CuisineStripState extends State<CuisineStrip> {
  final ScrollController _scroll = ScrollController();
  bool _canGoLeft = false;
  bool _canGoRight = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void didUpdateWidget(covariant CuisineStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  void _updateArrows() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    final left = position.pixels > 2;
    final right = position.pixels < position.maxScrollExtent - 2;
    if (left != _canGoLeft || right != _canGoRight) {
      setState(() {
        _canGoLeft = left;
        _canGoRight = right;
      });
    }
  }

  void _move(double direction) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target = (position.pixels + direction * 360)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _arrow({required bool left, required bool enabled}) => Material(
    color: QB.surface,
    shape: const CircleBorder(),
    elevation: 3,
    child: IconButton(
      tooltip: left ? 'Scroll cuisines left' : 'Scroll cuisines right',
      onPressed: enabled ? () => _move(left ? -1 : 1) : null,
      icon: Icon(left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
      color: QB.text,
      disabledColor: QB.muted.withValues(alpha: .45),
    ),
  );

  @override
  void dispose() {
    _scroll.removeListener(_updateArrows);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 144,
    child: Stack(
      alignment: Alignment.center,
      children: [
        ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 46),
          scrollDirection: Axis.horizontal,
          itemCount: widget.cuisines.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final name = i == 0 ? '' : widget.cuisines[i - 1];
            final active = widget.selected == name;
            return Semantics(
              selected: active,
              button: true,
              label: name.isEmpty ? 'All cuisines' : name,
              child: InkWell(
                onTap: () => widget.onSelected(name),
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  width: 120,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: active ? QB.peach : QB.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: active ? QB.gold : QB.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 66,
                        width: 90,
                        child: FoodImage(
                          FoodPhotos.byCuisine[name] ??
                              'dish-paneer-dum-biryani.jpg',
                          height: 66,
                          showCredit: false,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        name.isEmpty ? 'Everything' : name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? QB.gold : QB.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(left: 2, child: _arrow(left: true, enabled: _canGoLeft)),
        Positioned(right: 2, child: _arrow(left: false, enabled: _canGoRight)),
      ],
    ),
  );
}
