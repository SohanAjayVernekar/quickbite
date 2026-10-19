import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quickbite/main.dart' as app;
import 'package:quickbite/features/restaurants/food_cards.dart';

Future<void> waitFor(WidgetTester tester,Finder finder)async{
 for(var i=0;i<120;i++){await tester.pump(const Duration(milliseconds:500));if(finder.evaluate().isNotEmpty)return;}
 throw TestFailure('Timed out waiting for $finder');
}
void main(){
 IntegrationTestWidgetsFlutterBinding.ensureInitialized();
 testWidgets('Customer signs in, orders and tracks the server state',(tester)async{
  await app.main();await waitFor(tester,find.text('Log In'));await tester.tap(find.text('Log In').first);await tester.pump(const Duration(seconds:1));
  await tester.enterText(find.byType(TextFormField).at(0),'customer@quickbite.test');await tester.enterText(find.byType(TextFormField).at(1),'Customer@12345');
  await tester.tap(find.text('Log In  →'));await waitFor(tester,find.byType(RestaurantCard));
  await tester.ensureVisible(find.byType(RestaurantCard).first);await tester.tap(find.byType(RestaurantCard).first);await waitFor(tester,find.text('Add'));
  await tester.ensureVisible(find.text('Add').first);await tester.tap(find.text('Add').first);await tester.pump(const Duration(seconds:1));
  await tester.tap(find.text('Cart').first);await waitFor(tester,find.text('Continue to Checkout'));await tester.ensureVisible(find.text('Continue to Checkout'));await tester.tap(find.text('Continue to Checkout'));
  await waitFor(tester,find.byType(TextFormField));await tester.enterText(find.byType(TextFormField),'20 Demo Grove Road, Bengaluru 560001');
  await tester.ensureVisible(find.text('Place Order'));await tester.tap(find.text('Place Order'));await waitFor(tester,find.text('Order Accepted!'));
  await tester.tap(find.text('Track Order →'));await waitFor(tester,find.text('Driver Assigned'));
  await tester.tap(find.text('My Orders').first);await waitFor(tester,find.text('Your order stories.'));
 });
}
