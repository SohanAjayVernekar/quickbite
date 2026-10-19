import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../orders/order_widgets.dart';

class AdminData {
  final AdminSummary summary;
  final PageResult<OrderSummary> orders;
  AdminData(this.summary, this.orders);
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminState();
}

class _AdminMetric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _AdminMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color = QB.gold,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: QB.muted, fontSize: 12)),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: QB.text,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.arrow_forward_ios_rounded, color: QB.muted, size: 15),
      ],
    ),
  );
}

class _AdminState extends State<AdminScreen> {
  late Future<AdminData> data;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    data = fetch();
  }

  Future<AdminData> fetch() async {
    final r = context.read<Repository>();
    final results = await Future.wait<dynamic>([
      r.summary(),
      r.orders(admin: true),
    ]);
    return AdminData(
      results[0] as AdminSummary,
      results[1] as PageResult<OrderSummary>,
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin dashboard', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitor orders and platform processing from one place.',
                    style: TextStyle(color: QB.muted),
                  ),
                ],
              );
              final actions = Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(load),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/admin/orders'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('View orders'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/restaurants'),
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                    label: const Text('Browse catalog'),
                  ),
                ],
              );
              if (constraints.maxWidth < 640) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 18), actions],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Expanded(child: title), actions],
              );
            },
          ),
          const SizedBox(height: 28),
          FutureBuilder<AdminData>(
            future: data,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const LoadingBlock();
              if (s.hasError)
                return StateMessage(
                  title: 'Overview unavailable',
                  message: s.error.toString(),
                  retry: () => setState(load),
                );
              final d = s.data!, v = d.summary;
              final failed = (v.counts['PAYMENT_FAILED'] ?? 0) +
                  (v.counts['FAILED'] ?? 0);
              final active = (v.counts['PENDING'] ?? 0) +
                  (v.counts['PAID'] ?? 0) +
                  (v.counts['CONFIRMED'] ?? 0);
              final needsAttention = v.quarantined > 0 || v.retries > 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: needsAttention ? const Color(0xFFFFF0E8) : QB.mint,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: needsAttention
                            ? QB.gold.withValues(alpha: .25)
                            : QB.green.withValues(alpha: .18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          needsAttention
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          color: needsAttention ? QB.gold : QB.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                needsAttention
                                    ? 'Platform needs attention'
                                    : 'Platform processing normally',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${v.pendingOutbox} pending events · ${v.retries} retries · ${v.quarantined} quarantined',
                                style: const TextStyle(color: QB.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'View system details',
                          onPressed: () => context.go('/admin/system'),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeading('Order summary'),
                  ResponsiveCards(
                    minWidth: 225,
                    children: [
                      _AdminMetric(
                        label: 'Total orders',
                        value: '${v.total}',
                        icon: Icons.receipt_long_outlined,
                        onTap: () => context.go('/admin/orders'),
                      ),
                      _AdminMetric(
                        label: 'In progress',
                        value: '$active',
                        icon: Icons.hourglass_bottom_rounded,
                        color: QB.gold,
                        onTap: () => context.go('/admin/orders'),
                      ),
                      _AdminMetric(
                        label: 'Driver assigned',
                        value: '${v.counts['DRIVER_ASSIGNED'] ?? 0}',
                        icon: Icons.delivery_dining_rounded,
                        color: QB.green,
                        onTap: () => context.go('/admin/operations'),
                      ),
                      _AdminMetric(
                        label: 'Failed orders',
                        value: '$failed',
                        icon: Icons.error_outline_rounded,
                        color: failed > 0 ? QB.red : QB.green,
                        onTap: () => context.go('/admin/orders'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  const SectionHeading('Processing health'),
                  ResponsiveCards(
                    minWidth: 225,
                    children: [
                      _AdminMetric(
                        label: 'Pending events',
                        value: '${v.pendingOutbox}',
                        icon: Icons.outbox_outlined,
                        color: QB.gold,
                      ),
                      _AdminMetric(
                        label: 'Retry jobs',
                        value: '${v.retries}',
                        icon: Icons.replay_rounded,
                        color: v.retries > 0 ? QB.gold : QB.green,
                      ),
                      _AdminMetric(
                        label: 'Quarantined events',
                        value: '${v.quarantined}',
                        icon: Icons.shield_outlined,
                        color: v.quarantined > 0 ? QB.red : QB.green,
                      ),
                      _AdminMetric(
                        label: 'Oldest pending',
                        value: '${v.oldestAge.toStringAsFixed(1)} s',
                        icon: Icons.schedule_rounded,
                        color: v.oldestAge > 120 ? QB.red : QB.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  SectionHeading(
                    'Recent orders',
                    subtitle: 'Latest activity across the platform.',
                    action: TextButton(
                      onPressed: () => context.go('/admin/orders'),
                      child: const Text('View all'),
                    ),
                  ),
                  if (d.orders.items.isEmpty)
                    const StateMessage(
                      title: 'Ready for the first order',
                      message: 'Customer orders will appear here.',
                    )
                  else
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 760),
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('ORDER')),
                              DataColumn(label: Text('RESTAURANT')),
                              DataColumn(label: Text('STATUS')),
                              DataColumn(label: Text('DATE')),
                              DataColumn(label: Text('TOTAL'), numeric: true),
                            ],
                            rows: d.orders.items.take(8).map((o) {
                              final shortId = o.id.length > 10
                                  ? o.id.substring(0, 10)
                                  : o.id;
                              return DataRow(
                                onSelectChanged: (_) =>
                                    context.go('/admin/orders/${o.id}'),
                                cells: [
                                  DataCell(Text(shortId)),
                                  DataCell(Text(o.restaurantName)),
                                  DataCell(StatusPill(o.status)),
                                  DataCell(Text(localTime(o.createdAt))),
                                  DataCell(Text(money(o.totalMinor, o.currency))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.go('/admin/analytics'),
                        icon: const Icon(Icons.insights_outlined),
                        label: const Text('Open analytics'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/admin/operations'),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Open operations'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key});
  @override
  State<SystemScreen> createState() => _SystemState();
}

class _SystemState extends State<SystemScreen> {
  late Future<List<Json>> data;
  int quarantinePage = 1;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    final r = context.read<Repository>();
    data = Future.wait([r.system(), r.quarantine(page: quarantinePage)]);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            'System status',
            subtitle: 'Queue health and quarantined processing events.',
            action: IconButton(
              tooltip: 'Refresh system status',
              onPressed: () => setState(load),
              icon: const Icon(Icons.refresh),
            ),
          ),
          FutureBuilder<List<Json>>(
            future: data,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const LoadingBlock();
              if (s.hasError)
                return StateMessage(
                  title: 'System status unavailable',
                  message: s.error.toString(),
                  retry: () => setState(load),
                );
              final system = s.data![0], quarantine = s.data![1];
              final queues = system['queues'] as List;
              final records = quarantine['items'] as List;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(
                          system['broker'] == 'connected'
                              ? Icons.check_circle_outline
                              : Icons.cloud_off,
                          color: system['broker'] == 'connected'
                              ? QB.green
                              : QB.red,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'RabbitMQ: ${system['broker']}',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (system['message'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        system['message'],
                        style: const TextStyle(color: QB.muted),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ResponsiveCards(
                    children: queues
                        .map(
                          (q) => GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${q['name']}',
                                  style: const TextStyle(
                                    color: QB.gold,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('Ready: ${q['messages_ready']}'),
                                Text(
                                  'Unacknowledged: ${q['messages_unacknowledged']}',
                                ),
                                Text('Consumers: ${q['consumers']}'),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 36),
                  const SectionHeading(
                    'Quarantine records.',
                    subtitle:
                        'Read-only inspection. Replays are outside the baseline.',
                  ),
                  if (records.isEmpty)
                    const StateMessage(
                      title: 'No quarantined events',
                      message: 'Events needing investigation will appear here.',
                      icon: Icons.shield_outlined,
                    )
                  else
                    ...records.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r['failure_code']}',
                                style: const TextStyle(
                                  color: QB.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Worker: ${r['consumer_name']} · Attempts: ${r['attempts']}',
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                'Event: ${r['event_id']}',
                                style: const TextStyle(
                                  color: QB.muted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${r['created_at']}',
                                style: const TextStyle(
                                  color: QB.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if ((quarantine['total'] as int) > 0)
                    Pagination(
                      page: quarantine['page'] as int,
                      total: quarantine['total'] as int,
                      pageSize: quarantine['page_size'] as int,
                      onPage: (page) => setState(() {
                        quarantinePage = page;
                        load();
                      }),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
