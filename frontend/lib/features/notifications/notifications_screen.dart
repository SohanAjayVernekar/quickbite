import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../orders/order_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsState();
}

class _NotificationsState extends State<NotificationsScreen> {
  int page = 1;
  late Future<PageResult<Notice>> data;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    data = context.read<Repository>().notifications(page: page);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            'A little update for you.',
            subtitle: 'Your saved order notifications.',
            action: IconButton(
              tooltip: 'Refresh notifications',
              onPressed: () => setState(load),
              icon: const Icon(Icons.refresh),
            ),
          ),
          FutureBuilder<PageResult<Notice>>(
            future: data,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const LoadingBlock();
              if (s.hasError)
                return StateMessage(
                  title: 'Updates unavailable',
                  message: s.error.toString(),
                  retry: () => setState(load),
                );
              final d = s.data!;
              if (d.items.isEmpty)
                return const StateMessage(
                  title: 'You’re all caught up',
                  message: 'Order updates will appear here after checkout.',
                  icon: Icons.notifications_none,
                );
              return Column(
                children: [
                  ...d.items.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GlassCard(
                        onTap: () => context.go('/orders/${n.orderId}'),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: QB.gold,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    n.message,
                                    style: const TextStyle(color: QB.muted),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    localTime(n.at),
                                    style: const TextStyle(
                                      color: QB.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Pagination(
                    page: page,
                    total: d.total,
                    pageSize: d.pageSize,
                    onPage: (v) => setState(() {
                      page = v;
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
