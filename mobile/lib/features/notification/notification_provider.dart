import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';

/// 내 알림 목록 (알림 탭)
/// 알림 탭을 누를 때, 로그인할 때 다시 불러온다.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repository);

  final NotificationRepository _repository;

  List<AppNotification> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AppNotification> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 안 읽은 알림 수 (하단 탭 배지 등에 사용)
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.fetchNotifications();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = '알림을 불러오지 못했어요.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 알림 하나 읽음 처리: 화면에 먼저 반영하고 서버에 저장
  Future<void> markRead(int notificationId) async {
    final i = _items.indexWhere((n) => n.id == notificationId);
    if (i < 0 || _items[i].isRead) return;
    _items = List.of(_items)..[i] = _items[i].copyWith(isRead: true);
    notifyListeners();
    try {
      await _repository.markRead(notificationId);
    } catch (_) {
      // 읽음 저장이 실패해도 이동은 막지 않음. 다음에 불러올 때 서버 상태로 맞춰짐
    }
  }

  /// 모두 읽음
  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    final before = _items;
    _items = [for (final n in _items) n.copyWith(isRead: true)];
    notifyListeners();
    try {
      await _repository.markAllRead();
    } catch (_) {
      // 실패하면 원래 상태로 되돌림
      _items = before;
      notifyListeners();
    }
  }

  void clear() {
    _items = [];
    _errorMessage = null;
    notifyListeners();
  }
}
