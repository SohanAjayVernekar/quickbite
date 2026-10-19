import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>(), user = auth.user;
    final name = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : user?.isAdmin == true
        ? 'QuickBite Admin'
        : 'QuickBite Customer';
    final initial = String.fromCharCode(name.runes.first).toUpperCase();
    return SingleChildScrollView(
      child: PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              'Your profile.',
              subtitle: 'Account details and sign-in options.',
            ),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: QB.gold,
                    child: Text(
                      initial,
                      style: const TextStyle(color: QB.bg, fontSize: 30),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: QB.muted),
                  ),
                  const SizedBox(height: 22),
                  Chip(
                    label: Text(
                      user?.isAdmin == true ? 'ADMINISTRATOR' : 'CUSTOMER',
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    user?.isAdmin == true
                        ? 'Your administrator account can manage the QuickBite catalog, orders, and platform operations.'
                        : 'Your account can order food and access only your own orders and notifications.',
                    style: const TextStyle(color: QB.muted),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: auth.logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
