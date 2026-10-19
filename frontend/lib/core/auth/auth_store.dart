import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../models/models.dart';

class AuthStore extends ChangeNotifier {
  final ApiClient api;
  final _storage = const FlutterSecureStorage();
  User? user;
  Timer? _expiry;
  bool busy = false;
  String? error;
  bool expired = false;
  AuthStore(this.api) {
    api.onUnauthorized = expire;
  }
  Future<void> restore() async {
    if (kIsWeb) return; // Web access tokens intentionally exist only in memory.
    try {
      final token = await _storage.read(key: 'quickbite_token');
      final until = await _storage.read(key: 'quickbite_expiry');
      if (token == null || until == null) return;
      final expiry = DateTime.parse(until);
      if (expiry.isBefore(DateTime.now())) {
        await logout();
        return;
      }
      api.token = token;
      user = User.fromJson(await api.get('/api/v1/me'));
      _schedule(expiry);
    } catch (_) {
      api.token = null;
      user = null;
    }
  }

  Future<bool> login(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await api.post('/api/v1/auth/login', {
        'email': email.trim(),
        'password': password,
      }, public: true);
      api.token = result['access_token'];
      user = User.fromJson(result['user']);
      expired = false;
      final until = DateTime.parse(result['expires_at']);
      _schedule(until);
      if (!kIsWeb) {
        await _storage.write(key: 'quickbite_token', value: api.token);
        await _storage.write(
          key: 'quickbite_expiry',
          value: until.toIso8601String(),
        );
      }
      return true;
    } catch (e) {
      error = e.toString();
      api.token = null;
      user = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _schedule(DateTime until) {
    _expiry?.cancel();
    _expiry = Timer(until.difference(DateTime.now()), expire);
  }

  void expire() {
    expired = true;
    unawaited(logout(keepExpiry: true));
  }

  Future<void> logout({bool keepExpiry = false}) async {
    _expiry?.cancel();
    api.token = null;
    user = null;
    if (!keepExpiry) expired = false;
    notifyListeners();
    if (!kIsWeb) {
      await _storage.delete(key: 'quickbite_token');
      await _storage.delete(key: 'quickbite_expiry');
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }
}
