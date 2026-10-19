import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

/// Analytics derived entirely from existing order and payment rows.
///
/// No metric here is independently stored; each is computed at read time by
/// the API so the figures cannot drift from the underlying orders.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<AnalyticsScreen> {
  late Future<Json> data;
  int days = 30;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => data = context.read<Repository>().adminAnalytics(days: days);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            'Analytics.',
            subtitle: 'Derived from committed orders · last $days days',
            action: IconButton(
              tooltip: 'Refresh analytics',
              onPressed: () => setState(load),
              icon: const Icon(Icons.refresh),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [7, 30, 90].map((d) {
              final active = d == days;
              return ChoiceChip(
                label: Text('$d days'),
                selected: active,
                onSelected: (_) => setState(() {
                  days = d;
                  load();
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FutureBuilder<Json>(
            future: data,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const LoadingBlock();
              if (s.hasError)
                return StateMessage(
                  title: 'Analytics unavailable',
                  message: s.error.toString(),
                  retry: () => setState(load),
                );
              final d = s.data!;
              final total = d['total_orders'] as int;
              final daily = (d['daily'] as List).cast<Json>();
              final peak = daily.fold<int>(
                0,
                (m, e) => (e['orders'] as int) > m ? e['orders'] as int : m,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveCards(
                    minWidth: 180,
                    children: [
                      _tile('Orders', '$total'),
                      _tile(
                        'Gross value',
                        money(d['gross_minor'] as int),
                      ),
                      _tile(
                        'Settled',
                        money(d['settled_minor'] as int),
                        color: QB.green,
                      ),
                      _tile(
                        'Average order',
                        money(d['average_order_minor'] as int),
                      ),
                      _tile(
                        'Failed value',
                        money(d['failed_minor'] as int),
                        color: QB.red,
                      ),
                      _tile(
                        'Completion rate',
                        '${((d['completion_rate'] as num) * 100).toStringAsFixed(1)}%',
                        color: QB.green,
                      ),
                      _tile(
                        'Failure rate',
                        '${((d['failure_rate'] as num) * 100).toStringAsFixed(1)}%',
                        color: QB.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const SectionHeading(
                    'Orders per day.',
                    subtitle: 'Bar height is relative to the busiest day in range.',
                  ),
                  GlassCard(
                    child: daily.isEmpty
                        ? const Text(
                            'No orders in this window.',
                            style: TextStyle(color: QB.muted),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 130,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: daily.map((e) {
                                    final n = e['orders'] as int;
                                    final ratio = peak == 0 ? 0.0 : n / peak;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 1.5,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              '$n',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: QB.muted,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Container(
                                              height: (100 * ratio).clamp(2, 100),
                                              decoration: BoxDecoration(
                                                color: QB.gold.withValues(
                                                  alpha: 0.75,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${daily.first['day']} → ${daily.last['day']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: QB.muted,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 28),
                  const SectionHeading(
                    'Busiest restaurants.',
                    subtitle: 'By settled value in the selected window.',
                  ),
                  GlassCard(
                    child: Column(
                      children: (d['top_restaurants'] as List)
                          .cast<Json>()
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      '${e.key + 1}',
                                      style: const TextStyle(color: QB.muted),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${e.value['restaurant']}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${e.value['orders']} orders',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: QB.muted,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    money(e.value['revenue_minor'] as int),
                                    style: const TextStyle(
                                      color: QB.gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SectionHeading(
                    'Where orders ended up.',
                    subtitle: 'Terminal status mix for the same window.',
                  ),
                  GlassCard(
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: (d['status_mix'] as List)
                          .cast<Json>()
                          .map(
                            (e) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${e['count']}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: friendlyStatus(e['status'] as String)
                                            .contains('fail')
                                        ? QB.red
                                        : QB.gold,
                                  ),
                                ),
                                Text(
                                  friendlyStatus(e['status'] as String),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: QB.muted,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Revenue figures are simulated order values, not settled '
                    'money. QuickBite has no payment gateway, so no funds ever '
                    'move. A failure here means the order was never charged.',
                    style: TextStyle(color: QB.muted, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _tile(String title, String value, {Color color = QB.gold}) =>
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: QB.muted, fontSize: 13)),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
