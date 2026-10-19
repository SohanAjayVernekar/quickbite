import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

final cartDockKey = GlobalKey(debugLabel: 'floating-cart-target');

/// Runs only when the real CartStore accepts an item. The overlay never handles taps.
class BurstAddButton extends StatefulWidget {
  final String? Function() onAdd;
  final bool enabled;
  final String itemName;
  const BurstAddButton({
    super.key,
    required this.onAdd,
    required this.itemName,
    this.enabled = true,
  });
  @override
  State<BurstAddButton> createState() => _BurstAddButtonState();
}

class _BurstAddButtonState extends State<BurstAddButton> {
  bool added = false;
  Timer? reset;
  OverlayEntry? effect;
  void removeEffect() {
    effect?.remove();
    effect?.dispose();
    effect = null;
  }

  @override
  void dispose() {
    reset?.cancel();
    removeEffect();
    super.dispose();
  }

  void add() {
    final error = widget.onAdd();
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => added = true);
    reset?.cancel();
    reset = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => added = false);
    });
    if (MediaQuery.disableAnimationsOf(context)) return;
    removeEffect();
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final box = context.findRenderObject() as RenderBox;
    final origin = overlayBox.globalToLocal(
      box.localToGlobal(box.size.center(Offset.zero)),
    );
    final targetBox =
        cartDockKey.currentContext?.findRenderObject() as RenderBox?;
    final target = targetBox == null
        ? Offset(overlayBox.size.width - 80, overlayBox.size.height - 125)
        : overlayBox.globalToLocal(
            targetBox.localToGlobal(targetBox.size.center(Offset.zero)),
          );
    effect = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: _CartBurst(
              key: const ValueKey('cart-add-burst'),
              origin: origin,
              target: target,
              onDone: removeEffect,
            ),
          ),
        ),
      ),
    );
    overlay.insert(effect!);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: added
        ? '${widget.itemName} added to cart'
        : 'Add ${widget.itemName} to cart',
    child: FilledButton.tonalIcon(
      onPressed: widget.enabled ? add : null,
      style: FilledButton.styleFrom(
        backgroundColor: added ? QB.green : QB.peach,
        foregroundColor: added ? Colors.white : QB.gold,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        minimumSize: const Size(92, 46),
      ),
      icon: Icon(added ? Icons.check_rounded : Icons.add_rounded, size: 18),
      label: Text(widget.enabled ? (added ? 'Added' : 'Add') : 'Sold out'),
    ),
  );
}

class _CartBurst extends StatefulWidget {
  final Offset origin, target;
  final VoidCallback onDone;
  const _CartBurst({
    super.key,
    required this.origin,
    required this.target,
    required this.onDone,
  });
  @override
  State<_CartBurst> createState() => _CartBurstState();
}

class _CartBurstState extends State<_CartBurst>
    with SingleTickerProviderStateMixin {
  late final controller =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        )
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        })
        ..forward();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _BurstPainter(controller, widget.origin, widget.target),
    ),
  );
}

class _BurstPainter extends CustomPainter {
  final Animation<double> animation;
  final Offset origin, target;
  _BurstPainter(this.animation, this.origin, this.target)
    : super(repaint: animation);
  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final paint = Paint();
    for (var i = 0; i < 22; i++) {
      final angle = 2 * math.pi * i / 22;
      final radius = (22 + (i % 5) * 10) * Curves.easeOut.transform(t);
      final point =
          origin +
          Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius + t * t * 28,
          );
      paint.color = [
        QB.gold,
        QB.green,
        QB.ember,
        QB.fire,
      ][i % 4].withValues(alpha: 1 - t);
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + t * 4);
      if (i.isEven) {
        canvas.drawCircle(Offset.zero, 3.2 * (1 - t) + 1, paint);
      } else {
        canvas.drawRect(const Rect.fromLTWH(-2, -4, 4, 8), paint);
      }
      canvas.restore();
    }
    final travel = Curves.easeInOutCubic.transform(t);
    final point =
        Offset.lerp(origin, target, travel)! -
        Offset(0, math.sin(math.pi * travel) * 130);
    paint.color = QB.gold.withValues(alpha: (1 - t * t).clamp(0.0, 1.0));
    canvas.drawCircle(point, 14 * (1 - t * .55), paint);
    paint
      ..color = Colors.white.withValues(alpha: 1 - t * t)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      point - const Offset(4, 0),
      point + const Offset(4, 0),
      paint,
    );
    canvas.drawLine(
      point - const Offset(0, 4),
      point + const Offset(0, 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.origin != origin || old.target != target;
}
