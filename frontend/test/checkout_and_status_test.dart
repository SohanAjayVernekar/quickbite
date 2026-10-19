import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickbite/core/api/api_client.dart';
import 'package:quickbite/core/api/repository.dart';
import 'package:quickbite/core/models/models.dart';
import 'package:quickbite/core/theme/app_theme.dart';
import 'package:quickbite/core/widgets/ui.dart';
import 'package:quickbite/features/cart/cart_store.dart';

class RetryRepository extends Repository{
 final List<String> keys=[];final List<Json> requests=[];
 RetryRepository():super(ApiClient());
 @override Future<Acceptance> checkout(Json body,String key)async{
  keys.add(key);requests.add(body);
  if(keys.length==1)throw ApiException(0,'TIMEOUT','Unknown outcome');
  return Acceptance.fromJson({'order_id':'QB-test','status':'PENDING','currency':'INR','total_amount_minor':28900});
 }
}
void main(){
 test('Timeout preserves the same checkout key and immutable payload',()async{
  SharedPreferences.setMockInitialValues({});final repo=RetryRepository();final cart=CartStore(repo);await cart.bindUser('customer');
  cart.add(MenuItem.fromJson({'id':'item','restaurant_id':'rest','name':'Biryani','description':'Demo','image':'hero-biryani.png','currency':'INR','price_minor':28900,'available':true,'vegetarian':true}));
  cart.setAddress('12 Demo Garden Road, Bengaluru');expect(await cart.submit(),isNull);expect(cart.pending,isNotNull);
  final reloaded=CartStore(repo);await reloaded.bindUser('customer');expect(reloaded.pending,cart.pending);
  expect(await reloaded.submit(),isNotNull);expect(repo.keys[0],repo.keys[1]);expect(repo.requests[0],repo.requests[1]);
 });
 testWidgets('Failure status and readable error fit a narrow phone', (tester)async{
  tester.view.physicalSize=const Size(320,720);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme:QB.theme,home:const Scaffold(body:SingleChildScrollView(child:Padding(padding:EdgeInsets.all(18),child:Column(children:[StatusPill('PAYMENT_FAILED'),ErrorBanner('Payment could not finish. Your order is still saved.')]))))));
  expect(find.text('Payment Failed'),findsOneWidget);expect(tester.takeException(),isNull);
 });
}
