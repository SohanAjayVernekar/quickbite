import '../models/models.dart';
import 'api_client.dart';

class Repository {
  final ApiClient api;
  Repository(this.api);
  Future<Catalog> catalog() async =>
      Catalog.fromJson(await api.get('/api/v1/public/catalog', public: true));
  Future<PageResult<Restaurant>> restaurants({
    int page = 1,
    String query = '',
    String cuisine = '',
    bool vegetarian = false,
    int minRating = 0,
    String sort = 'recommended',
  }) async => PageResult.fromJson(
    await api.get(
      '/api/v1/restaurants?page=$page&page_size=12&q=${Uri.encodeQueryComponent(query)}&cuisine=${Uri.encodeQueryComponent(cuisine)}&vegetarian=$vegetarian&min_rating=$minRating&sort=${Uri.encodeQueryComponent(sort)}',
    ),
    Restaurant.fromJson,
  );
  Future<MenuResult> menu(
    String id, {
    int page = 1,
    int pageSize = 24,
    String diet = 'all',
    bool available = false,
    bool withPhoto = false,
    String sort = 'recommended',
    String query = '',
  }) async => MenuResult.fromJson(
    await api.get(
      '/api/v1/restaurants/${Uri.encodeComponent(id)}/menu'
      '?page=$page&page_size=$pageSize'
      '&diet=$diet&available=$available&with_photo=$withPhoto&sort=$sort'
      '&q=${Uri.encodeQueryComponent(query)}',
    ),
  );
  Future<PageResult<OrderSummary>> orders({
    int page = 1,
    String? status,
    bool admin = false,
  }) async => PageResult.fromJson(
    await api.get(
      '/api/v1/${admin ? 'admin/' : ''}orders?page=$page&page_size=12${status == null ? '' : '&status=$status'}',
    ),
    OrderSummary.fromJson,
  );
  Future<OrderDetail> order(String id) async => OrderDetail.fromJson(
    await api.get('/api/v1/orders/${Uri.encodeComponent(id)}'),
  );
  Future<PageResult<Notice>> notifications({
    int page = 1,
    String? orderId,
  }) async => PageResult.fromJson(
    await api.get(
      '/api/v1/${orderId == null ? '' : 'orders/${Uri.encodeComponent(orderId)}/'}notifications?page=$page&page_size=20',
    ),
    Notice.fromJson,
  );
  Future<Acceptance> checkout(Json body, String key) async =>
      Acceptance.fromJson(
        await api.post('/api/v1/orders', body, idempotencyKey: key),
      );
  Future<AdminSummary> summary() async =>
      AdminSummary.fromJson(await api.get('/api/v1/admin/summary'));
  Future<Restaurant> createAdminRestaurant(Json data) async => Restaurant.fromJson(
      await api.post('/api/v1/admin/restaurants', data));
  Future<Restaurant> setRestaurantAvailability(String id, bool available) async =>
      Restaurant.fromJson(await api.patch(
        '/api/v1/admin/restaurants/${Uri.encodeComponent(id)}/availability',
        {'available': available},
      ));
  Future<Json> deleteAdminRestaurant(String id) =>
      api.delete('/api/v1/admin/restaurants/${Uri.encodeComponent(id)}');
  Future<MenuItem> createAdminDish(String restaurantId, Json data) async =>
      MenuItem.fromJson(await api.post(
        '/api/v1/admin/restaurants/${Uri.encodeComponent(restaurantId)}/dishes',
        data,
      ));
  Future<MenuItem> setDishAvailability(String id, bool available) async =>
      MenuItem.fromJson(await api.patch(
        '/api/v1/admin/dishes/${Uri.encodeComponent(id)}/availability',
        {'available': available},
      ));
  Future<Json> deleteAdminDish(String id) =>
      api.delete('/api/v1/admin/dishes/${Uri.encodeComponent(id)}');
  Future<Json> cancelAdminOrder(String id, {String reason = 'GOODWILL'}) =>
      api.post(
        '/api/v1/admin/orders/${Uri.encodeComponent(id)}/cancel?reason=${Uri.encodeQueryComponent(reason)}',
        const {},
      );
  Future<Json> system() => api.get('/api/v1/admin/system');
  Future<Json> quarantine({int page = 1}) =>
      api.get('/api/v1/admin/quarantine?page=$page&page_size=20');
  Future<Json> acknowledgeQuarantine(String id) =>
      api.post('/api/v1/admin/quarantine/$id/acknowledge', const {});
  Future<Json> adminPayments({int page = 1}) =>
      api.get('/api/v1/admin/payments?page=$page&page_size=20');
  Future<Json> adminDrivers() => api.get('/api/v1/admin/drivers');
  Future<Json> adminStuck({int page = 1, int olderThanSeconds = 120}) =>
      api.get('/api/v1/admin/stuck?page=$page&older_than_seconds=$olderThanSeconds&page_size=20');
  Future<Json> adminAnalytics({int days = 30}) =>
      api.get('/api/v1/admin/analytics?days=$days');
}
