import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/repository.dart';
import '../../core/auth/auth_store.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import 'order_widgets.dart';
import 'tracking_controller.dart';

class OrdersScreen extends StatefulWidget {
  final bool admin;
  const OrdersScreen({super.key, this.admin = false});
  @override
  State<OrdersScreen> createState() => _OrdersState();
}

class _OrdersState extends State<OrdersScreen> {
  int page = 1;
  String? filter;
  late Future<PageResult<OrderSummary>> data;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    data = context.read<Repository>().orders(
      page: page,
      status: filter,
      admin: widget.admin,
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            widget.admin ? 'Order management' : 'Your order stories.',
            subtitle: widget.admin
                ? 'Review, track and manage orders across all customers.'
                : 'Revisit a favourite or follow an order in progress.',
            action: IconButton(
              tooltip: 'Refresh orders',
              onPressed: () => setState(load),
              icon: const Icon(Icons.refresh),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: filter == null,
                onSelected: (_) => setState(() {
                  filter = null;
                  page = 1;
                  load();
                }),
              ),
              ...allStatuses.map(
                (s) => ChoiceChip(
                  label: Text(friendlyStatus(s)),
                  selected: filter == s,
                  onSelected: (_) => setState(() {
                    filter = s;
                    page = 1;
                    load();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<PageResult<OrderSummary>>(
            future: data,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const LoadingBlock();
              if (s.hasError)
                return StateMessage(
                  title: 'Orders could not load',
                  message: s.error.toString(),
                  retry: () => setState(load),
                );
              final d = s.data!;
              if (d.items.isEmpty)
                return StateMessage(
                  title: 'No orders here yet',
                  message: widget.admin
                      ? 'Orders will appear after customers check out.'
                      : 'Your next favourite meal is waiting to be discovered.',
                );
              return Column(
                children: [
                  ResponsiveCards(
                    minWidth: 340,
                    children: d.items
                        .map(
                          (o) => OrderCard(
                            order: o,
                            onTap: () async {
                              final path = '${widget.admin ? '/admin' : ''}/orders/${o.id}';
                              if (widget.admin) {
                                await context.push<void>(path);
                                if (mounted) setState(load);
                              } else {
                                context.go(path);
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                  Pagination(
                    page: page,
                    total: d.total,
                    pageSize: d.pageSize,
                    onPage: (p) => setState(() {
                      page = p;
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

class OrderDetailScreen extends StatefulWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});
  @override
  State<OrderDetailScreen> createState() => _DetailState();
}

class _DetailState extends State<OrderDetailScreen> {
  late TrackingController controller;
  bool cancelling = false;
  @override
  void initState() {
    super.initState();
    controller = TrackingController(context.read<Repository>(), widget.id);
  }

  @override
  void didUpdateWidget(covariant OrderDetailScreen old) {
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

  Future<void> _cancelOrder(OrderDetail order) async {
    var reason = 'GOODWILL';
    final selectedReason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Cancel this order?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This stops order processing. If payment was settled, a refund obligation will be recorded for follow-up.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(value: 'GOODWILL', child: Text('Goodwill')),
                  DropdownMenuItem(value: 'RESTAURANT_REJECTED', child: Text('Restaurant rejected')),
                  DropdownMenuItem(value: 'RESTAURANT_UNAVAILABLE', child: Text('Restaurant unavailable')),
                  DropdownMenuItem(value: 'CUSTOMER_CANCELLED', child: Text('Customer cancelled')),
                  DropdownMenuItem(value: 'DUPLICATE_ORDER', child: Text('Duplicate order')),
                ],
                onChanged: (value) => setDialogState(() => reason = value ?? reason),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep order'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(dialogContext, reason),
              child: const Text('Cancel order'),
            ),
          ],
        ),
      ),
    );
    if (selectedReason == null || !mounted) return;
    setState(() => cancelling = true);
    try {
      final result = await context.read<Repository>().cancelAdminOrder(
        order.id,
        reason: selectedReason,
      );
      await controller.refresh();
      if (!mounted) return;
      final refund = result['refund_required'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refund
                ? 'Order cancelled. A refund obligation was recorded.'
                : 'Order cancelled.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel order: $error')),
      );
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
  }

  /// Makes polling state explicit. Without this the screen looked identical
  /// whether it was live-updating or silently stalled after a failure.
  Widget _liveStatus(TrackingController c) {
    final o = c.order;
    final updated = c.lastUpdated;
    final when = updated == null
        ? 'not yet updated'
        : 'updated ${updated.hour.toString().padLeft(2, '0')}:'
            '${updated.minute.toString().padLeft(2, '0')}:'
            '${updated.second.toString().padLeft(2, '0')}';
    final (color, text) = c.error != null
        ? (QB.red, 'Live updates interrupted · $when')
        : o?.terminal ?? true
            ? (QB.muted, 'Final state · $when')
            : (QB.green, 'Live updates on · $when');
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Icon(
            c.error != null
                ? Icons.cloud_off_outlined
                : (o?.terminal ?? true)
                    ? Icons.flag_outlined
                    : Icons.sensors,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12)),
          ),
          if (c.error != null)
            TextButton(
              onPressed: c.refresh,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => SingleChildScrollView(
      child: PageBody(
        child: Builder(
          builder: (context) {
            final isAdmin = context.watch<AuthStore>().user?.isAdmin ?? false;
            if (controller.loading) return const LoadingBlock();
            final o = controller.order;
            if (o == null)
              return StateMessage(
                title: 'Order unavailable',
                message: controller.error ?? 'Order not found.',
                retry: controller.refresh,
              );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _liveStatus(controller),
                SectionHeading(
                  o.terminal
                      ? 'Your order details.'
                      : 'Good things are in motion.',
                  subtitle: o.restaurantName,
                  action: IconButton(
                    tooltip: 'Refresh order and notifications',
                    onPressed: controller.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                if (controller.error != null) ErrorBanner(controller.error!),
                SelectableText(
                  o.id,
                  style: const TextStyle(color: QB.muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(o.status),
                    if (isAdmin && !o.terminal)
                      OutlinedButton.icon(
                        onPressed: cancelling ? null : () => _cancelOrder(o),
                        icon: cancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cancel_outlined, size: 18),
                        label: Text(cancelling ? 'Cancelling…' : 'Cancel order'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (o.status == 'PENDING')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Your order is accepted and saved. Processing may wait here while messaging recovers.',
                      style: TextStyle(color: QB.muted),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, c) {
                    final timeline = GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your order, step by step',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OrderTimeline(order: o),
                          if (o.driverName != null) ...[
                            const Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.two_wheeler,
                                color: QB.gold,
                              ),
                              title: Text(o.driverName!),
                              subtitle: Text(
                                o.driverVehicle ?? 'Simulated driver',
                              ),
                            ),
                          ],
                          if (o.status == 'DRIVER_ASSIGNED')
                            const Text(
                              'Driver assignment is the final stage of this simulation. Physical delivery is not simulated.',
                              style: TextStyle(color: QB.muted, fontSize: 12),
                            ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.go('/orders/${o.id}/payment'),
                              icon: const Icon(Icons.receipt_long, size: 18),
                              label: const Text('View simulated payment'),
                            ),
                          ),
                        ],
                      ),
                    );
                    final details = GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'The delicious details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...o.items.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${line.quantity} × ${line.name}',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    money(line.quantity * line.unitPriceMinor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            'Total  ${money(o.totalMinor, o.currency)}',
                            style: const TextStyle(
                              fontSize: 24,
                              color: QB.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'DELIVERY ADDRESS',
                            style: TextStyle(
                              color: QB.muted,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(o.address),
                          const SizedBox(height: 20),
                          Text(
                            'Placed ${localTime(o.createdAt)}',
                            style: const TextStyle(
                              color: QB.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                    return c.maxWidth > 850
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: timeline),
                              const SizedBox(width: 24),
                              Expanded(child: details),
                            ],
                          )
                        : Column(
                            children: [
                              timeline,
                              const SizedBox(height: 24),
                              details,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 32),
                const SectionHeading(
                  'Your updates.',
                  subtitle: 'Saved notifications for this order.',
                ),
                if (controller.notices.isEmpty)
                  const StateMessage(
                    title: 'No notifications yet',
                    message:
                        'Your order can continue while notifications are catching up. Use refresh to check again.',
                    icon: Icons.notifications_outlined,
                  )
                else
                  ...controller.notices.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                    ),
                  ),
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('Status history'),
                  children: o.history
                      .map(
                        (h) => ListTile(
                          title: Text(friendlyStatus(h.status)),
                          subtitle: Text(localTime(h.at)),
                          trailing: Text('v${h.version}'),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class AcceptedScreen extends StatelessWidget {
  final String id;
  final Acceptance? receipt;
  const AcceptedScreen({super.key, required this.id, this.receipt});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PageBody(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, color: QB.green, size: 60),
            const SizedBox(height: 24),
            Text(
              'Order Accepted!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your order is saved. We’ll take it from here.',
              style: TextStyle(color: QB.muted, fontSize: 18),
            ),
            const SizedBox(height: 26),
            SelectableText(id),
            if (receipt != null) ...[
              const SizedBox(height: 14),
              Text(
                money(receipt!.totalMinor, receipt!.currency),
                style: const TextStyle(color: QB.gold, fontSize: 30),
              ),
              const SizedBox(height: 14),
              StatusPill(receipt!.status),
            ],
            const SizedBox(height: 22),
            const Text(
              'Acceptance is the start of processing. Payment, restaurant confirmation and driver assignment happen next.',
              style: TextStyle(color: QB.muted),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () => context.go('/orders/$id'),
                  child: const Text('Track Order →'),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('View My Orders'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
