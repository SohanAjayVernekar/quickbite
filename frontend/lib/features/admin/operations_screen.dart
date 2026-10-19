import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

/// Read-only operational detail plus a single safe triage action:
/// acknowledging a quarantined event. Acknowledging never requeues or
/// reprocesses anything, so it cannot cause an order to run twice.
class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsState();
}

class _OperationsState extends State<OperationsScreen> {
  late Future<Json> data;
  String? busyId, banner;
  bool bannerIsError = false;
  int stuckPage = 1, paymentPage = 1, quarantinePage = 1;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => data = Future.wait([
    context.read<Repository>().adminStuck(page: stuckPage),
    context.read<Repository>().adminPayments(page: paymentPage),
    context.read<Repository>().adminDrivers(),
    context.read<Repository>().quarantine(page: quarantinePage),
  ]).then((r) => {
    'stuck': r[0],
    'payments': r[1],
    'drivers': r[2],
    'quarantine': r[3],
  });

  Future<void> acknowledge(String id) async {
    setState(() {
      busyId = id;
      banner = null;
    });
    try {
      await context.read<Repository>().acknowledgeQuarantine(id);
      if (!mounted) return;
      setState(() {
        banner = 'Recorded. The event stays quarantined and is not retried.';
        bannerIsError = false;
        load();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        banner = e.toString();
        bannerIsError = true;
      });
    } finally {
      if (mounted) setState(() => busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            'Operations.',
            subtitle: 'Pipeline detail · read-only except acknowledgement',
            action: IconButton(
              tooltip: 'Refresh operations',
              onPressed: () => setState(load),
              icon: const Icon(Icons.refresh),
            ),
          ),
          if (banner != null) ...[
            ErrorBanner(banner!),
            const SizedBox(height: 18),
          ],
          FutureBuilder<Json>(
            future: data,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const LoadingBlock();
              if (s.hasError)
                return StateMessage(
                  title: 'Operations unavailable',
                  message: s.error.toString(),
                  retry: () => setState(load),
                );
              final d = s.data!;
              final stuck = d['stuck']['items'] as List;
              final payments = d['payments']['items'] as List;
              final drivers = (d['drivers']['items'] as List).cast<Json>();
              final quarantine = d['quarantine']['items'] as List;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stuck(stuck, d['stuck']),
                  const SizedBox(height: 32),
                  _payments(payments, d['payments']),
                  const SizedBox(height: 32),
                  _drivers(drivers),
                  const SizedBox(height: 32),
                  _quarantine(quarantine, d['quarantine']),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _stuck(List items, Json pageData) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeading(
        'Stuck orders.',
        subtitle: 'Still PENDING after 120s. Usually a broker outage, not a fault.',
      ),
      if (items.isEmpty)
        const GlassCard(
          child: Text(
            'Nothing is stuck. Every accepted order has advanced.',
            style: TextStyle(color: QB.muted),
          ),
        )
      else
        ...items.map((e) {
          final o = e as Json;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              onTap: () => context.go('/admin/orders/${o['id']}'),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_empty, color: QB.gold),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${o['restaurant_name']}'),
                        const SizedBox(height: 3),
                        Text(
                          '${money(o['total_minor'] as int, o['currency'] as String)} · pending ${(o['age_seconds'] as num).toStringAsFixed(0)}s',
                          style: const TextStyle(
                            fontSize: 12,
                            color: QB.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Open →',
                    style: TextStyle(fontSize: 12, color: QB.muted),
                  ),
                ],
              ),
            ),
          );
        }),
      if ((pageData['total'] as int) > 0)
        Pagination(
          page: pageData['page'] as int,
          total: pageData['total'] as int,
          pageSize: pageData['page_size'] as int,
          onPage: (page) => setState(() {
            stuckPage = page;
            load();
          }),
        ),
    ],
  );

  Widget _payments(List items, Json pageData) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeading(
        'Simulated payments.',
        subtitle: '${pageData['total']} recorded · no card or bank data is stored anywhere',
      ),
      GlassCard(
        child: items.isEmpty
            ? const Text(
                'No payment records yet.',
                style: TextStyle(color: QB.muted),
              )
            : Column(
                children: (items.cast<Json>().toList().asMap().entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${e.value['order_id']}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  money(
                                    e.value['amount_minor'] as int,
                                    e.value['currency'] as String,
                                  ),
                                  style: const TextStyle(
                                    color: QB.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                StatusPill(e.value['status'] as String),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
      ),
      if ((pageData['total'] as int) > 0)
        Pagination(
          page: pageData['page'] as int,
          total: pageData['total'] as int,
          pageSize: pageData['page_size'] as int,
          onPage: (page) => setState(() {
            paymentPage = page;
            load();
          }),
        ),
    ],
  );

  Widget _drivers(List drivers) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeading(
        'Drivers.',
        subtitle: 'Four simulated drivers. Assignment completes this simulation.',
      ),
      ResponsiveCards(
        minWidth: 210,
        children: drivers
            .map(
              (d) => GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.two_wheeler,
                          color: QB.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${d['name']}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${d['assigned_orders']} orders assigned',
                      style: TextStyle(
                        color: (d['assigned_orders'] as int) == 0
                            ? QB.muted
                            : QB.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['active'] ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        fontSize: 12,
                        color: QB.muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _quarantine(List items, Json pageData) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeading(
        'Quarantined events.',
        subtitle: 'Dead-lettered after exhausting retries. Acknowledging records '
            'that a human reviewed it; it does not requeue anything.',
      ),
      if (items.isEmpty)
        const GlassCard(
          child: Text(
            'Nothing is quarantined.',
            style: TextStyle(color: QB.muted),
          ),
        )
      else
        ...items.map((e) {
          final q = e as Json;
          final done = q['acknowledged'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        done ? Icons.task_alt : Icons.report_gmailerrorred,
                        color: done ? QB.green : QB.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${q['consumer_name']} · ${q['failure_code']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${q['attempts']} attempts',
                        style: const TextStyle(
                          fontSize: 12,
                          color: QB.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${q['reason']}',
                    style: const TextStyle(color: QB.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'queue ${q['source_queue']}',
                    style: const TextStyle(color: QB.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  if (done)
                    Text(
                      'Acknowledged${q['acknowledged_by'] == null ? '' : ' by ${q['acknowledged_by']}'}',
                      style: const TextStyle(color: QB.green, fontSize: 13),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: busyId == q['id']
                          ? null
                          : () => acknowledge('${q['id']}'),
                      icon: busyId == q['id']
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('Acknowledge reviewed'),
                    ),
                ],
              ),
            ),
          );
        }),
      if ((pageData['total'] as int) > 0)
        Pagination(
          page: pageData['page'] as int,
          total: pageData['total'] as int,
          pageSize: pageData['page_size'] as int,
          onPage: (page) => setState(() {
            quarantinePage = page;
            load();
          }),
        ),
    ],
  );
}
