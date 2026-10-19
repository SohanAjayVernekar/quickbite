import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_store.dart';
import '../models/models.dart';
import '../widgets/app_shell.dart';
import '../widgets/ui.dart';
import '../../features/landing/landing_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/restaurants/restaurants_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/admin/analytics_screen.dart';
import '../../features/admin/operations_screen.dart';
import '../../features/dishes/dish_3d_screen.dart';
import '../../features/payment/payment_screen.dart';

GoRouter createRouter(AuthStore auth) => GoRouter(
  refreshListenable: auth,
  redirect: (context, state) {
    final path = state.uri.path, user = auth.user;
    if (path == '/') return null;
    if (user == null && path != '/login')
      return '/login?next=${Uri.encodeComponent(state.uri.toString())}';
    if (user != null && path == '/login') {
      if (user.isAdmin) return '/admin';
      final next = state.uri.queryParameters['next'];
      return next != null &&
              next.startsWith('/') &&
              !next.startsWith('//') &&
              !next.startsWith('/admin') &&
              !next.startsWith('/login')
          ? next
          : '/home';
    }
    if (user != null) {
      if (path.startsWith('/admin') && !user.isAdmin) return '/home';
      final adminCatalog = user.isAdmin && path.startsWith('/restaurants');
      if (user.isAdmin &&
          !path.startsWith('/admin') &&
          path != '/profile' &&
          !adminCatalog)
        return '/admin';
    }
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    body: PageBody(
      child: StateMessage(
        title: 'This page is off the menu',
        message: 'Return to QuickBite to continue.',
        retry: () => context.go('/'),
        retryLabel: 'Go home',
      ),
    ),
  ),
  routes: [
    GoRoute(path: '/', builder: (c, s) => const LandingScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    ShellRoute(
      builder: (c, s, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        GoRoute(
          path: '/restaurants',
          builder: (c, s) => RestaurantsScreen(
            initialCuisine: s.uri.queryParameters['cuisine'] ?? '',
          ),
        ),
        GoRoute(
          path: '/restaurants/:id',
          builder: (c, s) => MenuScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(path: '/cart', builder: (c, s) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (c, s) => const CheckoutScreen()),
        GoRoute(
          path: '/accepted/:id',
          builder: (c, s) => AcceptedScreen(
            id: s.pathParameters['id']!,
            receipt: s.extra is Acceptance ? s.extra as Acceptance : null,
          ),
        ),
        GoRoute(path: '/orders', builder: (c, s) => const OrdersScreen()),
        GoRoute(
          path: '/orders/:id',
          builder: (c, s) => OrderDetailScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/orders/:id/payment',
          builder: (c, s) => PaymentScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/notifications',
          builder: (c, s) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (c, s) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/dishes/:id/3d',
          builder: (c, s) => Dish3DScreen(
            id: s.pathParameters['id']!,
            name: s.uri.queryParameters['name'] ?? 'Dish',
          ),
        ),
        GoRoute(path: '/admin', builder: (c, s) => const AdminScreen()),
        GoRoute(
          path: '/admin/orders',
          builder: (c, s) => const OrdersScreen(admin: true),
        ),
        GoRoute(
          path: '/admin/orders/:id',
          builder: (c, s) => OrderDetailScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/admin/orders/:id/payment',
          builder: (c, s) => PaymentScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(path: '/admin/system', builder: (c, s) => const SystemScreen()),
        GoRoute(
          path: '/admin/analytics',
          builder: (c, s) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/admin/operations',
          builder: (c, s) => const OperationsScreen(),
        ),
      ],
    ),
  ],
);
