import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../orders/tracking_controller.dart';

/// Read-only view of a simulated payment.
///
/// No card, UPI or bank details are collected, stored or sent. This screen
/// exists to show the authoritative server-side amount and the simulated
/// outcome, not to take money.
class PaymentScreen extends StatefulWidget {
  final String id;
  const PaymentScreen({super.key, required this.id});

  @override
  State<PaymentScreen> createState() => _PaymentState();
}

class _PaymentState extends State<PaymentScreen> {
  late TrackingController controller;

  @override
  void initState() {
    super.initState();
    controller = TrackingController(context.read<Repository>(), widget.id);
  }

  @override
  void didUpdateWidget(covariant PaymentScreen old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      controller.dispose();
      controller = TrackingController(context.read<Repository>(), widget.id);
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
    builder: (context, _) => SingleChildScrollView(
      child: PageBody(
        child: Builder(
          builder: (context) {
            if (controller.loading) return const LoadingBlock();
            final o = controller.order;
            if (o == null)
              return StateMessage(
                title: 'Payment record unavailable',
                message: controller.error ?? 'Order not found.',
                retry: controller.refresh,
              );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.science_outlined,
                            color: QB.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SIMULATED PAYMENT',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w600,
                              color: QB.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        money(o.totalMinor, o.currency),
                        style: const TextStyle(
                          color: QB.gold,
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        o.restaurantName,
                        style: const TextStyle(color: QB.muted),
                      ),
                      const SizedBox(height: 18),
                      StatusPill(o.status),
                      const SizedBox(height: 16),
                      SelectableText(
                        o.id,
                        style: const TextStyle(fontSize: 13, color: QB.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SimulationNotice(status: o.status),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What happened',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ..._steps(o).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              s.reached ? Icons.check_circle : Icons.circle_outlined,
                              color: s.reached ? QB.green : QB.muted,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.label,
                                style: TextStyle(
                                  color: s.reached ? null : QB.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (o.failureMessage != null) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        ErrorBanner(o.failureMessage!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'About this amount',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'The server recalculates the total from current menu '
                        'prices when the order is committed. The figure above is '
                        'that authoritative snapshot, not a value sent by the '
                        'browser, and it does not include tax or delivery fees.',
                        style: TextStyle(color: QB.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () => context.go('/orders/${o.id}'),
                      child: const Text('Track Order →'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/orders'),
                      child: const Text('View My Orders'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _SimulationNotice extends StatelessWidget {
  final String status;
  const _SimulationNotice({required this.status});

  @override
  Widget build(BuildContext context) {
    final failed = status == 'PAYMENT_FAILED' || status == 'FAILED';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failed ? Icons.info_outline : Icons.lock_outline,
                color: failed ? QB.gold : QB.green,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  failed
                      ? 'This simulated payment did not succeed'
                      : 'No money changed hands',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            failed
                ? 'A background worker tried to settle this order and gave up '
                      'after its allowed retries. No charge was made and no '
                      'refund is needed, because no payment was ever taken.'
                : 'QuickBite has no payment gateway. Checkout collects no card, '
                      'UPI or bank details, and a background worker marks the '
                      'order paid after a short simulated delay. Never enter '
                      'real payment information here.',
            style: const TextStyle(color: QB.muted),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String label;
  final bool reached;
  const _Step(this.label, this.reached);
}

List<_Step> _steps(OrderDetail o) {
  final failed = o.status == 'PAYMENT_FAILED' || o.status == 'FAILED';
  final paid = o.status != 'PENDING' && !failed;
  final history = o.history.map((h) => h.status).toSet();
  final recorded = (String s) => history.contains(s) || o.status == s;
  return [
    _Step('Order accepted and committed', true),
    _Step(
      failed ? 'Payment attempt failed after retries' : 'Payment simulated as settled',
      failed || recorded('PAID') || paid,
    ),
    _Step('Restaurant confirmation', recorded('CONFIRMED')),
    _Step('Driver assigned', recorded('DRIVER_ASSIGNED')),
  ];
}
