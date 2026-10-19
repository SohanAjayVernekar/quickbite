import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final form = GlobalKey<FormState>(),
      email = TextEditingController(),
      password = TextEditingController();
  bool hide = true, demoBusy = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (form.currentState!.validate()) {
      await context.read<AuthStore>().login(email.text, password.text);
      password.clear();
    }
  }

  /// Fills the form with a seeded demo identity and signs in immediately.
  Widget _demo(String label, String mail, String pass, IconData icon) =>
      OutlinedButton.icon(
        onPressed: demoBusy ? null : () => signInAs(mail, pass),
        icon: Icon(icon, size: 17),
        label: Text(label),
      );

  Future<void> signInAs(String mail, String pass) async {
    setState(() => demoBusy = true);
    email.text = mail;
    password.text = pass;
    await submit();
    if (mounted) setState(() => demoBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final login = GlassCard(
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR TABLE IS READY',
              style: TextStyle(color: QB.gold, fontSize: 11, letterSpacing: 2),
            ),
            const SizedBox(height: 18),
            Text(
              'Welcome back.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sign in to find your next favourite bite.',
              style: TextStyle(color: QB.muted),
            ),
            const SizedBox(height: 28),
            if (auth.expired)
              const ErrorBanner(
                'Your session expired. Sign in again to continue.',
              ),
            if (auth.error != null) ErrorBanner(auth.error!),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (v) => (v?.contains('@') ?? false)
                  ? null
                  : 'Enter your email address.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: password,
              obscureText: hide,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: hide ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => hide = !hide),
                  icon: Icon(
                    hide
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) =>
                  (v?.isNotEmpty ?? false) ? null : 'Enter your password.',
              onFieldSubmitted: (_) {
                if (!auth.busy) submit();
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.busy ? null : submit,
                child: Text(auth.busy ? 'Signing in…' : 'Log In  →'),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or use a demo account',
                    style: TextStyle(color: QB.muted, fontSize: 11),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _demo('Customer', 'customer@quickbite.test', 'Customer@12345',
                    Icons.person_outline),
                _demo('Second customer', 'customer2@quickbite.test',
                    'Customer@12345', Icons.group_outlined),
                _demo('Admin', 'admin@quickbite.test', 'Admin@12345',
                    Icons.admin_panel_settings_outlined),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Demo accounts are fictional and share one seeded database. The '
              'admin can manage the catalog and orders. Never reuse these passwords '
              'anywhere real.',
              style: TextStyle(color: QB.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      body: SingleChildScrollView(
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to QuickBite'),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, c) => c.maxWidth > 850
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Brand(),
                                const SizedBox(height: 28),
                                Text(
                                  'A good day\nstarts with\na great bite.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(fontSize: 72),
                                ),
                                const SizedBox(height: 20),
                                const SizedBox(
                                  height: 300,
                                  child: FloatingFood(
                                    child: FoodImage(
                                      'dish-classic-margherita.jpg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 70),
                          Expanded(child: login),
                        ],
                      )
                    : login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
