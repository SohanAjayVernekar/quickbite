import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/api/repository.dart';
import '../../core/models/models.dart';

class CartLine {
  final MenuItem item;
  int quantity;
  CartLine(this.item, this.quantity);
  Json toJson() => {'item': item.toJson(), 'quantity': quantity};
}

class CartStore extends ChangeNotifier {
  final Repository repo;
  final List<CartLine> _lines = [];
  List<CartLine> get lines => List.unmodifiable(_lines);
  String address = '';
  String? userId;
  Json? pending;
  String? error;
  bool busy = false, restoring = false;
  Acceptance? receipt;
  CartStore(this.repo);
  int get count => _lines.fold(0, (sum, x) => sum + x.quantity);
  int get subtotal =>
      _lines.fold(0, (sum, x) => sum + x.quantity * x.item.priceMinor);
  bool get locked => pending != null || busy || restoring;
  String? get restaurantId =>
      _lines.isEmpty ? null : _lines.first.item.restaurantId;
  Future<void> bindUser(String? id) async {
    if (userId == id) return;
    userId = id;
    _lines.clear();
    address = '';
    pending = null;
    receipt = null;
    error = null;
    restoring = true;
    notifyListeners();
    if (id != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getString('quickbite_cart_$id');
        if (userId != id) return;
        if (saved != null) {
          final j = Map<String, dynamic>.from(jsonDecode(saved));
          _lines.addAll(
            (j['lines'] as List).map(
              (x) => CartLine(MenuItem.fromJson(x['item']), x['quantity']),
            ),
          );
          address = j['address'] ?? '';
          pending = j['pending'] == null
              ? null
              : Map<String, dynamic>.from(j['pending']);
        }
      } catch (_) {
        error =
            'The saved cart could not be read. Contact support before retrying an uncertain checkout.';
      }
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> _writes = Future<void>.value();
  Future<void> _save() async {
    final id = userId;
    if (id == null) return;
    final snapshot = jsonEncode({
      'lines': _lines.map((x) => x.toJson()).toList(),
      'address': address,
      'pending': pending,
    });
    final operation = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString('quickbite_cart_$id', snapshot))
        throw StateError('Unable to save the pending checkout safely.');
    });
    _writes = operation.catchError((Object _) {});
    await operation;
  }

  String? add(MenuItem item) {
    if (locked)
      return 'Resolve your pending checkout before changing the cart.';
    if (!item.available) return 'This item is currently unavailable.';
    if (restaurantId != null && restaurantId != item.restaurantId)
      return 'Your cart belongs to another restaurant. Remove those items first.';
    final matches = _lines.where((x) => x.item.id == item.id);
    if (matches.isNotEmpty) {
      if (matches.first.quantity >= 20) return 'Maximum quantity is 20.';
      matches.first.quantity++;
    } else {
      if (_lines.length >= 20) return 'Maximum 20 distinct items.';
      _lines.add(CartLine(item, 1));
    }
    _persistDraft();
    notifyListeners();
    return null;
  }

  void quantity(String id, int value) {
    if (locked) return;
    if (value <= 0) {
      _lines.removeWhere((x) => x.item.id == id);
    } else {
      for (final x in _lines) {
        if (x.item.id == id) x.quantity = value.clamp(1, 20);
      }
    }
    _persistDraft();
    notifyListeners();
  }

  void setAddress(String value) {
    if (!locked) {
      address = value;
      _persistDraft();
    }
  }

  void _persistDraft() {
    _save().catchError((Object e) {
      error = 'This device could not save your cart.';
      notifyListeners();
    });
  }

  Future<Acceptance?> submit() async {
    if (busy || restoring || userId == null) return null;
    error = null;
    if (pending == null) {
      if (_lines.isEmpty || address.trim().length < 10) {
        error = 'Add food and enter a complete delivery address.';
        notifyListeners();
        return null;
      }
      pending = {
        'key': const Uuid().v4(),
        'body': {
          'restaurant_id': restaurantId,
          'delivery_address': address.trim(),
          'items': _lines
              .map((x) => {'menu_item_id': x.item.id, 'quantity': x.quantity})
              .toList(),
        },
      };
    }
    busy = true;
    notifyListeners();
    final owner = userId;
    try {
      await _save(); // Persist immutable request + UUID BEFORE sending any network request.
      final accepted = await repo.checkout(
        Map<String, dynamic>.from(pending!['body']),
        pending!['key'],
      );
      if (userId != owner) return null;
      receipt = accepted;
      pending = null;
      _lines.clear();
      address = '';
      await _save();
      return accepted;
    } on ApiException catch (e) {
      error = e.message;
      // Only a definitive validation rejection permits editing with a future new key.
      if (e.status == 422) {
        pending = null;
        await _save();
      }
      return null;
    } catch (e) {
      error =
          'Unable to finish safely. Your saved checkout key will be reused.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
