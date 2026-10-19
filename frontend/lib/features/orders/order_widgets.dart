import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

String localTime(DateTime time) =>
    DateFormat('d MMM yyyy · HH:mm').format(time.toLocal());

class OrderCard extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;
  const OrderCard({super.key, required this.order, required this.onTap});
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              order.restaurantName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            StatusPill(order.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(order.id, style: const TextStyle(color: QB.muted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          localTime(order.createdAt),
          style: const TextStyle(color: QB.muted, fontSize: 12),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 30,
          runSpacing: 8,
          children: [
            Text(
              money(order.totalMinor, order.currency),
              style: const TextStyle(
                color: QB.gold,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text('View details →'),
          ],
        ),
      ],
    ),
  );
}

class OrderTimeline extends StatelessWidget {
  final OrderDetail order;
  const OrderTimeline({super.key, required this.order});
  @override
  Widget build(BuildContext context) {
    const stages = [
      ('PENDING', 'Order placed', Icons.receipt_long_outlined),
      ('PAID', 'Payment completed', Icons.payments_outlined),
      ('CONFIRMED', 'Restaurant confirmed', Icons.restaurant),
      ('DRIVER_ASSIGNED', 'Driver assignment', Icons.two_wheeler),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stage in stages)
          Builder(
            builder: (context) {
              final events = order.history.where((h) => h.status == stage.$1);
              final complete = events.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (complete ? QB.green : QB.muted).withValues(
                          alpha: .1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        complete ? Icons.check : stage.$3,
                        color: complete ? QB.green : QB.muted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: complete ? QB.text : QB.muted,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complete
                                ? localTime(events.first.at)
                                : order.terminal
                                ? 'Not reached'
                                : 'Waiting',
                            style: const TextStyle(
                              color: QB.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        if (order.status == 'PAYMENT_FAILED' || order.status == 'FAILED')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ErrorBanner(
              order.failureMessage ?? 'Order processing could not continue.',
            ),
          ),
      ],
    );
  }
}
