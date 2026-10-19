import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_store.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../../features/cart/cart_store.dart';
import '../../features/cart/cart_effects.dart';
import 'ui.dart';
import 'delight.dart';

class NavItem {
  final String label, path;
  final IconData icon;
  const NavItem(this.label, this.path, this.icon);
}

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});
  static String _initial(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? 'Q' : trimmed.substring(0, 1).toUpperCase();
  }

  List<NavItem> items(bool admin) => admin
      ? const [
          NavItem('Dashboard', '/admin', Icons.space_dashboard_outlined),
          NavItem('Catalog', '/restaurants', Icons.restaurant_menu_rounded),
          NavItem('Orders', '/admin/orders', Icons.receipt_long_outlined),
          NavItem(
            'System Status',
            '/admin/system',
            Icons.monitor_heart_outlined,
          ),
          NavItem('Analytics', '/admin/analytics', Icons.insights_outlined),
          NavItem('Operations', '/admin/operations', Icons.fact_check_outlined),
          NavItem('Profile', '/profile', Icons.person_outline),
        ]
      : const [
          NavItem('Home', '/home', Icons.grid_view_rounded),
          NavItem('Restaurants', '/restaurants', Icons.restaurant_menu_rounded),
          NavItem('Cart', '/cart', Icons.shopping_bag_outlined),
          NavItem('My Orders', '/orders', Icons.receipt_long_outlined),
          NavItem(
            'Notifications',
            '/notifications',
            Icons.notifications_outlined,
          ),
          NavItem('Profile', '/profile', Icons.person_outline),
        ];
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>(),
        admin = auth.user?.isAdmin ?? false;
    final cart = context.watch<CartStore>();
    final motion = context.watch<MotionPreferences>();
    final nav = items(admin), path = GoRouterState.of(context).uri.path;
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    bool selected(NavItem n) => n.path == '/admin'
        ? path == '/admin'
        : path.startsWith(n.path) || (n.path == '/cart' && path == '/checkout');
    void navigate(String route) {
      if (!wide) Navigator.of(context).pop();
      context.go(route);
    }

    Widget navList() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 28, 18, 26),
          child: Brand(size: 21),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 8, 18),
                child: Text(
                  admin ? 'ADMIN WORKSPACE' : 'A LITTLE EVERYDAY JOY',
                  style: const TextStyle(
                    color: QB.muted,
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...nav.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    selected: selected(n),
                    selectedTileColor: QB.gold,
                    selectedColor: Colors.white,
                    iconColor: QB.muted,
                    textColor: QB.muted,
                    leading: Icon(n.icon, size: 21),
                    title: Text(
                      n.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: n.path == '/cart' && cart.count > 0
                        ? Badge(
                            label: Text('${cart.count}'),
                            backgroundColor: QB.ink,
                            textColor: QB.onDark,
                          )
                        : null,
                    onTap: () => navigate(n.path),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: QB.mint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      admin ? Icons.space_dashboard_rounded : Icons.spa_outlined,
                      color: QB.green,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      admin ? 'Operations\nat a glance.' : 'Find your\nhappy plate.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                        height: 1.2,
                        color: QB.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      admin
                          ? 'Read-only control panel'
                          : 'A world of flavours awaits.',
                      style: const TextStyle(fontSize: 11, color: QB.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: const Text('Animations', style: TextStyle(fontSize: 12)),
                value: motion.enabled,
                onChanged: (_) => motion.toggle(),
              ),
              TextButton.icon(
                onPressed: auth.logout,
                icon: const Icon(Icons.logout, size: 17),
                label: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ],
    );
    Widget body() => Stack(
      children: [
        Positioned.fill(child: child),
        if (!admin &&
            cart.count > 0 &&
            (path == '/home' || path.startsWith('/restaurants')))
          Positioned(
            left: 18,
            right: 18,
            bottom: 20,
            child: Align(
              alignment: Alignment.bottomRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: FloatingFood(
                  child: Material(
                    key: cartDockKey,
                    color: QB.ink,
                    elevation: 14,
                    shadowColor: QB.ink.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => context.go('/cart'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Your happy little cart',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 240),
                                    child: Text(
                                      '${cart.count} items · ${money(cart.subtotal)}',
                                      key: ValueKey(
                                        '${cart.count}:${cart.subtotal}',
                                      ),
                                      style: const TextStyle(
                                        color: QB.mutedOnDark,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: QB.ember,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    Widget topbar() => Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 22, 0),
      padding: const EdgeInsets.fromLTRB(22, 10, 14, 10),
      decoration: BoxDecoration(
        color: QB.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: QB.gold.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined, color: QB.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              admin
                  ? 'QuickBite Admin · Read-only'
                  : 'Good food is always a good idea.',
              style: const TextStyle(fontSize: 12, color: QB.muted),
            ),
          ),
          IconButton(
            tooltip: motion.enabled ? 'Pause animations' : 'Enable animations',
            onPressed: motion.toggle,
            icon: Icon(
              motion.enabled
                  ? Icons.motion_photos_on_outlined
                  : Icons.motion_photos_off_outlined,
              size: 21,
            ),
          ),
          if (!admin) ...[
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.go('/notifications'),
              icon: const Icon(Icons.notifications_outlined, size: 21),
            ),
            IconButton(
              tooltip: 'Cart (${cart.count} items)',
              onPressed: () => context.go('/cart'),
              icon: Badge(
                isLabelVisible: cart.count > 0,
                label: Text('${cart.count}'),
                child: const Icon(Icons.shopping_bag_outlined, size: 21),
              ),
            ),
          ],
          const SizedBox(width: 10),
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(30),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: QB.peach,
              child: Text(
                _initial(auth.user?.name),
                style: const TextStyle(
                  color: QB.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (wide)
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              Container(
                width: 226,
                margin: const EdgeInsets.fromLTRB(18, 16, 0, 18),
                decoration: BoxDecoration(
                  color: QB.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: QB.gold.withValues(alpha: .12)),
                  boxShadow: [
                    BoxShadow(
                      color: QB.ink.withValues(alpha: .045),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: navList(),
              ),
              Expanded(
                child: Column(
                  children: [
                    topbar(),
                    Expanded(child: body()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    // Keep the admin's five operational destinations reachable on mobile;
    // profile remains available from the avatar and drawer.
    final bottom = admin
        ? nav.where((n) => n.path != '/profile').toList()
        : nav.take(4).toList();
    var index = bottom.indexWhere(selected);
    if (index < 0) index = 0;
    return Scaffold(
      appBar: AppBar(
        title: const Brand(size: 18),
        actions: [
          IconButton(
            tooltip: motion.enabled ? 'Pause animations' : 'Enable animations',
            onPressed: motion.toggle,
            icon: Icon(
              motion.enabled
                  ? Icons.motion_photos_on_outlined
                  : Icons.motion_photos_off_outlined,
            ),
          ),
          if (!admin)
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.go('/notifications'),
              icon: const Icon(Icons.notifications_outlined),
            ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: QB.bg,
        child: SafeArea(child: navList()),
      ),
      body: SafeArea(top: false, child: body()),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              height: 68,
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(bottom[i].path),
              destinations: bottom
                  .map(
                    (n) => NavigationDestination(
                      icon: n.path == '/cart'
                          ? Badge(
                              isLabelVisible: cart.count > 0,
                              label: Text('${cart.count}'),
                              child: Icon(n.icon),
                            )
                          : Icon(n.icon),
                      label: n.label == 'System Status'
                          ? 'System'
                          : n.label == 'Dashboard'
                          ? 'Home'
                          : n.label == 'Operations'
                          ? 'Ops'
                          : n.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
