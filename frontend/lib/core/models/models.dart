typedef Json = Map<String, dynamic>;
String money(int minor, [String currency = 'INR']) =>
    '${currency == 'INR' ? '₹' : '$currency '}${(minor ~/ 100)}.${(minor % 100).toString().padLeft(2, '0')}';
String friendlyStatus(String s) => s
    .toLowerCase()
    .split('_')
    .map((x) => x[0].toUpperCase() + x.substring(1))
    .join(' ');
const terminalStatuses = {'DRIVER_ASSIGNED', 'PAYMENT_FAILED', 'FAILED'};
const allStatuses = [
  'PENDING',
  'PAID',
  'CONFIRMED',
  'DRIVER_ASSIGNED',
  'PAYMENT_FAILED',
  'FAILED',
];

class User {
  final String id, name, email, role;
  User.fromJson(Json j)
    : id = j['id'],
      name = j['name'],
      email = j['email'],
      role = j['role'];
  bool get isAdmin => role == 'ADMIN';
}

class Restaurant {
  final String id, name, cuisine, description, image;
  final bool available;
  final int ratingTenths, etaMinutes;
  Restaurant.fromJson(Json j)
    : id = j['id'],
      name = j['name'],
      cuisine = j['cuisine'],
      description = j['description'],
      image = j['image'],
      available = j['available'],
      ratingTenths = j['rating_tenths'],
      etaMinutes = j['eta_minutes'];
  String get rating => (ratingTenths / 10).toStringAsFixed(1);
}

class MenuItem {
  final String id, restaurantId, name, description, image, currency;
  final int priceMinor;
  final bool available, vegetarian;
  MenuItem.fromJson(Json j)
    : id = j['id'],
      restaurantId = j['restaurant_id'],
      name = j['name'],
      description = j['description'],
      image = j['image'],
      currency = j['currency'],
      priceMinor = j['price_minor'],
      available = j['available'],
      vegetarian = j['vegetarian'];
  Json toJson() => {
    'id': id,
    'restaurant_id': restaurantId,
    'name': name,
    'description': description,
    'image': image,
    'currency': currency,
    'price_minor': priceMinor,
    'available': available,
    'vegetarian': vegetarian,
  };
}

class PageResult<T> {
  final List<T> items;
  final int page, pageSize, total;
  PageResult.fromJson(Json j, T Function(Json) parse)
    : items = (j['items'] as List)
          .map((x) => parse(Map<String, dynamic>.from(x)))
          .toList(),
      page = j['page'],
      pageSize = j['page_size'],
      total = j['total'];
  bool get hasNext => page * pageSize < total;
}

class MenuResult {
  final Restaurant restaurant;
  final PageResult<MenuItem> menu;
  MenuResult.fromJson(Json j)
    : restaurant = Restaurant.fromJson(j['restaurant']),
      menu = PageResult.fromJson(j, MenuItem.fromJson);
}

class OrderSummary {
  final String id, restaurantName, status, currency;
  final int totalMinor, version;
  final DateTime createdAt;
  OrderSummary.fromJson(Json j)
    : id = j['id'],
      restaurantName =
          j['restaurant_name'] ?? j['restaurant']?['name'] ?? 'Restaurant',
      status = j['status'],
      currency = j['currency'],
      totalMinor = j['total_amount_minor'],
      version = j['version'],
      createdAt = DateTime.parse(j['created_at']);
  bool get terminal => terminalStatuses.contains(status);
}

class OrderLine {
  final String name;
  final int quantity, unitPriceMinor;
  OrderLine.fromJson(Json j)
    : name = j['item_name'],
      quantity = j['quantity'],
      unitPriceMinor = j['unit_price_minor'];
}

class HistoryEntry {
  final String status;
  final int version;
  final DateTime at;
  HistoryEntry.fromJson(Json j)
    : status = j['status'],
      version = j['version'],
      at = DateTime.parse(j['created_at']);
}

class OrderDetail extends OrderSummary {
  final List<OrderLine> items;
  final List<HistoryEntry> history;
  final String address;
  final String? failureMessage, driverName, driverVehicle;
  OrderDetail.fromJson(Json j)
    : items = (j['items'] as List).map((x) => OrderLine.fromJson(x)).toList(),
      history = (j['history'] as List)
          .map((x) => HistoryEntry.fromJson(x))
          .toList(),
      address = j['delivery_address'],
      failureMessage = j['failure_message'],
      driverName = j['driver']?['name'],
      driverVehicle = j['driver']?['vehicle'],
      super.fromJson(j);
}

class Notice {
  final String id, orderId, title, message;
  final DateTime at;
  Notice.fromJson(Json j)
    : id = j['id'],
      orderId = j['order_id'],
      title = j['title'],
      message = j['message'],
      at = DateTime.parse(j['created_at']);
}

class Acceptance {
  final String orderId, status, currency;
  final int totalMinor;
  Acceptance.fromJson(Json j)
    : orderId = j['order_id'],
      status = j['status'],
      currency = j['currency'],
      totalMinor = j['total_amount_minor'];
}

class Catalog {
  final int totalRestaurants;
  final List<String> cuisines;
  final List<Restaurant> restaurants;
  final List<MenuItem> dishes;
  Catalog.fromJson(Json j)
    : totalRestaurants =
          j['total_restaurants'] ?? (j['restaurants'] as List).length,
      cuisines = List<String>.from(j['cuisines'] ?? const <String>[]),
      restaurants = (j['restaurants'] as List)
          .map((x) => Restaurant.fromJson(x))
          .toList(),
      dishes = (j['dishes'] as List).map((x) => MenuItem.fromJson(x)).toList();
}

class AdminSummary {
  final int total, pendingOutbox, retries, quarantined;
  final double oldestAge;
  final Map<String, int> counts;
  AdminSummary.fromJson(Json j)
    : total = j['total_orders'],
      pendingOutbox = j['pending_outbox'],
      retries = j['retry_jobs'],
      quarantined = j['quarantined_events'],
      oldestAge = (j['oldest_pending_outbox_seconds'] as num).toDouble(),
      counts = Map<String, int>.from(j['status_counts']);
}
