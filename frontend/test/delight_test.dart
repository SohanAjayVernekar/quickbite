import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite/core/theme/app_theme.dart';
import 'package:quickbite/core/widgets/delight.dart';
import 'package:quickbite/features/cart/cart_effects.dart';

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
  theme: QB.theme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('Cart burst runs after an accepted add and cleans up', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(
      host(
        BurstAddButton(
          itemName: 'Paneer',
          onAdd: () {
            count++;
            return null;
          },
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(count, 1);
    expect(find.text('Added'), findsOneWidget);
    expect(find.byKey(const ValueKey('cart-add-burst')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
    expect(find.byKey(const ValueKey('cart-add-burst')), findsNothing);
    expect(find.text('Add'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('A rejected add never celebrates success', (tester) async {
    await tester.pumpWidget(
      host(
        BurstAddButton(
          itemName: 'Paneer',
          onAdd: () => 'Your cart belongs to another restaurant.',
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('Added'), findsNothing);
    expect(find.byKey(const ValueKey('cart-add-burst')), findsNothing);
    expect(
      find.text('Your cart belongs to another restaurant.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reduced motion keeps confirmation without particles', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        BurstAddButton(itemName: 'Paneer', onAdd: () => null),
        reduced: true,
      ),
    );
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('Added'), findsOneWidget);
    expect(find.byKey(const ValueKey('cart-add-burst')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Leaving during a burst disposes the overlay and timer', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(BurstAddButton(itemName: 'Paneer', onAdd: () => null)),
    );
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pumpWidget(host(const Text('Another page')));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('cart-add-burst')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('The hero fits a narrow phone with reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: FoodHero(onExplore: () {}),
          ),
        ),
        reduced: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Big cravings.\nHappy endings.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
