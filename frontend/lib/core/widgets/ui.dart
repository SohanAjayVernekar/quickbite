import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../models/food_photos.dart';
import '../config/environment.dart';

class PageBody extends StatelessWidget {
  final Widget child;
  const PageBody({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1320),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 600 ? 18 : 32,
          28,
          MediaQuery.sizeOf(context).width < 600 ? 18 : 32,
          112,
        ),
        child: child,
      ),
    ),
  );
}

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
  });
  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool hovered = false;
  bool focused = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: Focus(
      onFocusChange: (v) {
        if (focused != v) setState(() => focused = v);
      },
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hovered ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: QB.surface,
          borderRadius: BorderRadius.circular(QB.radius),
          border: Border.all(
            color: focused
                ? QB.gold.withValues(alpha: .6)
                : QB.border,
          ),
          boxShadow: [
            BoxShadow(
              color: QB.ink.withValues(alpha: hovered ? .11 : .055),
              blurRadius: hovered ? 30 : 20,
              offset: Offset(0, hovered ? 13 : 7),
            ),
            BoxShadow(
              color: QB.fire.withValues(alpha: hovered ? .08 : .025),
              blurRadius: 24,
              spreadRadius: -12,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            focusColor: QB.gold.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(QB.radius),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    ),
  );
}

class Brand extends StatelessWidget {
  final double size;
  const Brand({super.key, this.size = 24});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: QB.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.restaurant_rounded, color: Colors.white, size: size * .75),
      ),
      const SizedBox(width: 10),
      Text(
        'QuickBite',
        style: TextStyle(
          color: QB.text,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
      ),
    ],
  );
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeading(this.title, {super.key, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: const TextStyle(color: QB.muted)),
        ],
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 10), child: action!),
      ],
    ),
  );
}

class StateMessage extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final VoidCallback? retry;
  final String retryLabel;
  const StateMessage({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.restaurant_menu_rounded,
    this.retry,
    this.retryLabel = 'Try again',
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: QB.gold),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: QB.muted),
            textAlign: TextAlign.center,
          ),
          if (retry != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: OutlinedButton(onPressed: retry, child: Text(retryLabel)),
            ),
        ],
      ),
    ),
  );
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: QB.red.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QB.red.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: QB.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: QB.red)),
          ),
        ],
      ),
    ),
  );
}

/// Sweeping highlight used to signal that content is still on its way.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});
  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller
        ..stop()
        ..value = 0;
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (_, child) => ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment(-2 + 4 * controller.value, 0),
        end: Alignment(-1 + 4 * controller.value, 0),
        colors: const [QB.skeleton, QB.skeletonSheen, QB.skeleton],
        stops: const [0, .45, 1],
      ).createShader(bounds),
      child: child,
    ),
  );
}

/// A single placeholder block. Pairs with [Shimmer].
class Skeleton extends StatelessWidget {
  final double height, radius;
  final double? width;
  const Skeleton({super.key, this.height = 14, this.width, this.radius = 8});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: QB.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

class _SkeletonTile extends StatelessWidget {
  final bool row;
  const _SkeletonTile({required this.row});
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: EdgeInsets.all(row ? 18 : 14),
    child: row
        ? const Row(
            children: [
              Skeleton(height: 46, width: 46, radius: 23),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(height: 15, width: 150),
                    SizedBox(height: 10),
                    Skeleton(height: 12, width: 96),
                  ],
                ),
              ),
            ],
          )
        : const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(height: 190, radius: 18),
              SizedBox(height: 22),
              Skeleton(height: 19, width: 165),
              SizedBox(height: 12),
              Skeleton(height: 13, width: 110),
              SizedBox(height: 22),
              Skeleton(height: 12, width: 84),
            ],
          ),
  );
}

/// Placeholder that mirrors the card grid so layout does not jump when data
/// arrives. Pass `list: true` on screens that render rows.
class LoadingBlock extends StatelessWidget {
  final int count;
  final bool list;
  const LoadingBlock({super.key, this.count = 6, this.list = false});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Loading QuickBite content',
    child: list
        ? Column(
            children: [
              for (var i = 0; i < count; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _SkeletonTile(row: true),
                ),
            ],
          )
        : ResponsiveCards(
            children: [
              for (var i = 0; i < count; i++) _SkeletonTile(row: false),
            ],
          ),
  );
}

class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final failed = status.contains('FAIL');
    final color = failed
        ? QB.red
        : status == 'DRIVER_ASSIGNED'
        ? QB.green
        : QB.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        friendlyStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Bundled food photography. Older saved carts resolve by dish name as well.
class FoodImage extends StatelessWidget {
  final String name;
  final String? dishName, cuisine;
  final double? height;
  final BoxFit fit;
  final bool showCredit;
  const FoodImage(this.name, {super.key, this.height, this.fit = BoxFit.cover,
    this.dishName, this.cuisine, this.showCredit = true});

  @override
  Widget build(BuildContext context) {
    final file = FoodPhotos.resolve(name, dishName: dishName, cuisine: cuisine);
    if (file.startsWith('generated:auto/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: _GeneratedDishPainter(dishName ?? 'QuickBite dish'),
          child: const SizedBox.expand(),
        ),
      );
    }
    final credit = FoodPhotos.creditFor(file);
    final remote = file.startsWith('/api/v1/')
        ? '${Environment.apiBase}$file'
        : (file.startsWith('https://') || file.startsWith('http://') ? file : null);
    Widget unavailable(BuildContext _, Object __, StackTrace? ___) => Container(
        height: height ?? 180,
        width: double.infinity,
        color: QB.peach,
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.restaurant_menu_rounded, color: QB.gold, size: 36),
          const SizedBox(height: 10),
          Text(dishName ?? cuisine ?? 'QuickBite', textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: QB.text, fontWeight: FontWeight.w700)),
          const Text('Photo unavailable', style: TextStyle(color: QB.muted, fontSize: 12)),
        ]),
      );
    final semanticLabel = dishName == null
        ? 'QuickBite food image'
        : 'Illustrative image of $dishName';
    final photo = remote == null
        ? Image.asset(
            'assets/images/$file',
            height: height,
            width: double.infinity,
            fit: fit,
            semanticLabel: semanticLabel,
            filterQuality: FilterQuality.medium,
            errorBuilder: unavailable,
          )
        : Image.network(
            remote,
            height: height,
            width: double.infinity,
            fit: fit,
            semanticLabel: semanticLabel,
            filterQuality: FilterQuality.medium,
            errorBuilder: unavailable,
          );
    return ClipRRect(borderRadius: BorderRadius.circular(18), child: Stack(children: [
      photo,
      if (showCredit && credit != null) Positioned(right: 5, top: 5,
        child: IconButton(tooltip: 'About this food image',
          style: IconButton.styleFrom(backgroundColor: QB.ink.withValues(alpha: .75),
            foregroundColor: QB.onDark, minimumSize: const Size(40, 40)),
          icon: const Icon(Icons.info_outline_rounded, size: 16),
          onPressed: () => showDialog<void>(context: context, builder: (context) => AlertDialog(
            title: const Text('About this dish image'),
            content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(credit['title'] ?? 'Food photography'), const SizedBox(height: 12),
                const Text('Illustrative menu artwork. Actual portions and presentation may differ.'),
                const SizedBox(height: 12), Text(credit['license'] ?? ''),
                if ((credit['source'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8), SelectableText(credit['source']!, style: const TextStyle(fontSize: 11, color: QB.muted)),
                ],
                if ((credit['licenseUrl'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8), SelectableText(credit['licenseUrl']!, style: const TextStyle(fontSize: 11, color: QB.muted)),
                ],
              ])),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done'))],
          )),
        )),
    ]));
  }
}

class _GeneratedDishPainter extends CustomPainter {
  final String name;
  const _GeneratedDishPainter(this.name);

  @override
  void paint(Canvas canvas, Size size) {
    const width = 640.0, height = 480.0;
    canvas.save();
    canvas.scale(size.width / width, size.height / height);
    var seed = 17;
    for (final unit in name.codeUnits) {
      seed = (seed * 31 + unit) % 360;
    }
    final hue = seed.toDouble();
    final food = HSLColor.fromAHSL(1, hue / 360, .62, .46).toColor();
    final garnish = HSLColor.fromAHSL(1, ((hue + 95) % 360) / 360, .68, .42).toColor();
    final dark = Paint()..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xff222822), HSLColor.fromAHSL(1, hue / 360, .22, .16).toColor()],
    ).createShader(const Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), dark);
    canvas.drawCircle(const Offset(320, 228), 190, Paint()..color = Colors.black.withValues(alpha: .25));
    canvas.drawCircle(const Offset(320, 216), 184, Paint()..shader = const RadialGradient(
      colors: [Color(0xffffffff), Color(0xffe4dccd)],
    ).createShader(Rect.fromCircle(center: Offset(320, 216), radius: 184)));
    canvas.drawCircle(const Offset(320, 216), 151, Paint()..color = const Color(0xfff6f0e5));

    final lower = name.toLowerCase();
    final isDosa = lower.contains('dosa') || lower.contains('pancake') || lower.contains('crepe');
    final isBurger = lower.contains('burger') || lower.contains('sandwich') || lower.contains('toast');
    final isPizza = lower.contains('pizza') || lower.contains('tart') || lower.contains('pie');
    final isNoodle = lower.contains('noodle') || lower.contains('pasta') || lower.contains('ramen');
    final plate = Paint()..color = food;
    if (isDosa) {
      canvas.drawOval(Rect.fromCenter(center: Offset(320, 224), width: 250, height: 138), plate);
      canvas.drawOval(Rect.fromCenter(center: Offset(320, 220), width: 205, height: 98), Paint()..color = const Color(0xffffd987));
    } else if (isBurger) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(218, 154, 204, 80), const Radius.circular(50)), Paint()..color = const Color(0xffd99b51));
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(228, 220, 184, 37), const Radius.circular(8)), Paint()..color = const Color(0xff584034));
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(223, 250, 194, 20), const Radius.circular(8)), Paint()..color = garnish);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(218, 266, 204, 48), const Radius.circular(22)), Paint()..color = const Color(0xffd99b51));
    } else if (isPizza) {
      canvas.drawCircle(const Offset(320, 226), 120, plate);
      canvas.drawCircle(const Offset(320, 226), 101, Paint()..color = const Color(0xffffd987));
    } else if (isNoodle) {
      canvas.drawOval(Rect.fromCenter(center: Offset(320, 239), width: 250, height: 150), plate);
      for (var i = 0; i < 4; i++) {
        final y = 202.0 + i * 22;
        final path = Path()..moveTo(220, y)..cubicTo(270, y - 28, 350, y + 28, 420, y - 2);
        canvas.drawPath(path, Paint()..color = const Color(0xffffd987)..style = PaintingStyle.stroke..strokeWidth = 9..strokeCap = StrokeCap.round);
      }
    } else {
      canvas.drawOval(Rect.fromCenter(center: Offset(320, 242), width: 245, height: 142), plate);
      canvas.drawOval(Rect.fromCenter(center: Offset(320, 242), width: 200, height: 102), Paint()..color = HSLColor.fromAHSL(1, hue / 360, .7, .58).toColor());
    }

    final random = math.Random(seed);
    for (var i = 0; i < 17; i++) {
      final x = 235.0 + random.nextDouble() * 170;
      final y = 176.0 + random.nextDouble() * 120;
      canvas.drawCircle(Offset(x, y), 3.5 + random.nextDouble() * 4, Paint()..color = i.isEven ? garnish : const Color(0xfff6d580));
    }
    canvas.drawRect(const Rect.fromLTWH(0, 390, width, 90), Paint()..color = Colors.black.withValues(alpha: .78));
    final caption = TextPainter(
      text: TextSpan(text: name, style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
      textAlign: TextAlign.center,
    )..layout(maxWidth: 570);
    caption.paint(canvas, Offset((width - caption.width) / 2, 409));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GeneratedDishPainter oldDelegate) => oldDelegate.name != name;
}

class ResponsiveCards extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  const ResponsiveCards({
    super.key,
    required this.children,
    this.minWidth = 260,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final count = math.max(1, ((c.maxWidth + 20) / (minWidth + 20)).floor());
      final width = (c.maxWidth - (count - 1) * 20) / count;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: children
            .map((x) => SizedBox(width: width, child: x))
            .toList(),
      );
    },
  );
}

class Pagination extends StatelessWidget {
  final int page, total, pageSize;
  final int? loadedCount;
  final ValueChanged<int> onPage;
  const Pagination({
    super.key,
    required this.page,
    required this.total,
    required this.pageSize,
    required this.onPage,
    this.loadedCount,
  });
  @override
  Widget build(BuildContext context) {
    if (total <= 0 || pageSize <= 0) return const SizedBox.shrink();
    final pages = (total + pageSize - 1) ~/ pageSize;
    final current = page.clamp(1, pages).toInt();
    final start = (current - 2).clamp(1, pages).toInt();
    final end = (current + 2).clamp(1, pages).toInt();
    final visible = <int?>[];
    if (start > 1) {
      visible.add(1);
      if (start > 2) visible.add(null);
    }
    visible.addAll(List<int>.generate(end - start + 1, (i) => start + i));
    if (end < pages) {
      if (end < pages - 1) visible.add(null);
      visible.add(pages);
    }
    final from = (current - 1) * pageSize + 1;
    final to = (current * pageSize).clamp(0, total).toInt();
    final progress = loadedCount == null
        ? 'Showing $from–$to of $total'
        : 'Loaded 1–${loadedCount!.clamp(0, total)} of $total · Page $current of $pages';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            progress,
            style: const TextStyle(color: QB.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'First page',
                onPressed: current > 1 ? () => onPage(1) : null,
                icon: const Icon(Icons.first_page_rounded),
              ),
              IconButton(
                tooltip: 'Previous page',
                onPressed: current > 1 ? () => onPage(current - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              for (final number in visible)
                if (number == null)
                  const SizedBox(width: 28, child: Text('…', textAlign: TextAlign.center))
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: number == current
                        ? FilledButton.tonal(
                            onPressed: null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(42, 42),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text('$number'),
                          )
                        : TextButton(
                            onPressed: () => onPage(number),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(42, 42),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text('$number'),
                          ),
                  ),
              IconButton(
                tooltip: 'Next page',
                onPressed: current < pages ? () => onPage(current + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              IconButton(
                tooltip: 'Last page',
                onPressed: current < pages ? () => onPage(pages) : null,
                icon: const Icon(Icons.last_page_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FloatingFood extends StatefulWidget {
  final Widget child;
  const FloatingFood({super.key, required this.child});
  @override
  State<FloatingFood> createState() => _FloatingFoodState();
}

class _FloatingFoodState extends State<FloatingFood>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, math.sin(controller.value * math.pi * 2) * 6),
      child: child,
    ),
    child: widget.child,
  );
}
