import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../core/api/api_client.dart';
import '../../core/api/repository.dart';
import '../../core/models/models.dart';

class TrackingController extends ChangeNotifier with WidgetsBindingObserver {
  final Repository repo;
  final String id;
  OrderDetail? order;
  List<Notice> notices = [];
  String? error;
  bool loading = true, _disposed = false, _background = false, _busy = false;
  int failures = 0;
  /// Wall-clock time of the last successful poll, so the UI can say when the
  /// view was last updated rather than implying the data is live.
  DateTime? lastUpdated;
  /// Increments on every successful poll; lets the UI detect a real change.
  int revision = 0;
  DateTime? _nextPoll;
  Timer? _timer;
  TrackingController(this.repo, this.id) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  bool get isLive => (order?.terminal ?? true) == false;

  /// Whether an automatic poll is still scheduled.
  bool get polling => _timer?.isActive ?? false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background = state != AppLifecycleState.resumed;
    _timer?.cancel();
    if (!_background) refresh();
  }

  Future<void> refresh() async {
    if (_disposed || _busy || _background) return;
    _busy = true;
    _timer?.cancel();
    var unauthorized = false;
    try {
      final next = await repo.order(id);
      final feed = await repo.notifications(orderId: id);
      if (_disposed) return;
      order = next;
      notices = feed.items;
      error = null;
      failures = 0;
      lastUpdated = DateTime.now();
      revision++;
    } on ApiException catch (e) {
      if (_disposed) return;
      error = e.message;
      failures++;
      unauthorized = e.status == 401;
    } catch (_) {
      if (_disposed) return;
      error =
          'Unable to refresh this order. Your accepted order remains saved.';
      failures++;
    } finally {
      _busy = false;
      if (!_disposed) {
        loading = false;
        notifyListeners();
        if (!unauthorized && !_background && !(order?.terminal ?? false)) {
          final seconds = failures == 0
              ? 2
              : (2 * (1 << failures.clamp(0, 4))).clamp(2, 30);
          _nextPoll = DateTime.now().add(Duration(seconds: seconds));
          _timer = Timer(Duration(seconds: seconds), refresh);
        } else {
          // Terminal, unauthorised or backgrounded: nothing further is scheduled.
          _nextPoll = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _nextPoll = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
