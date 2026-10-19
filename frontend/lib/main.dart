import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/api/repository.dart';
import 'core/auth/auth_store.dart';
import 'core/routing/router.dart';
import 'core/theme/app_theme.dart';
import 'features/cart/cart_store.dart';
import 'core/widgets/delight.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final api = ApiClient();
  final repo = Repository(api);
  final auth = AuthStore(api);
  await auth.restore();
  final cart = CartStore(repo);
  await cart.bindUser(auth.user?.id);
  auth.addListener(() => cart.bindUser(auth.user?.id));
  final router = createRouter(auth);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MotionPreferences()),
        Provider.value(value: repo),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: cart),
      ],
      child: MaterialApp.router(
        title: 'QuickBite · A little joy in every order',
        debugShowCheckedModeBanner: false,
        theme: QB.theme,
        routerConfig: router,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final enabled = context.watch<MotionPreferences>().enabled;
          return MediaQuery(
            data: media.copyWith(
              disableAnimations: media.disableAnimations || !enabled,
            ),
            child: child!,
          );
        },
      ),
    ),
  );
}
