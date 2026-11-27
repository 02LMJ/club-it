import '../../core/network/api_client.dart';
import '../models/app_notification.dart';

/// 내 알림 목록·읽음 처리
abstract class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications();

  /// 알림 하나 읽음 처리
  Future<void> markRead(int notificationId);

  /// 모든 알림 읽음 처리
  Future<void> markAllRead();
}

/// 실제 서버(FastAPI)와 통신하는 구현
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._api);

  final ApiClient _api;

  /// GET /notifications (최신순)
  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final data = await _api.get('/notifications', query: {'limit': '50'});
    return (data as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markRead(int notificationId) async {
    await _api.patch('/notifications/$notificationId/read');
  }

  @override
  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all');
  }
}

/// 서버 없이 화면을 개발·테스트할 때 쓰는 가짜 구현
class MockNotificationRepository implements NotificationRepository {
  final List<AppNotification> _items = [
    AppNotification(
      id: 2,
      message: '[CATS] 새 공지사항: 이번 주 스터디 공지',
      postId: 1,
      isRead: false,
      createdAt: DateTime(2026, 10, 27, 18, 30),
    ),
    AppNotification(
      id: 1,
      message: '[IPSE] 가입 신청이 승인되었습니다.',
      isRead: true,
      createdAt: DateTime(2026, 10, 25, 10, 0),
    ),
  ];

  @override
  Future<List<AppNotification>> fetchNotifications() async =>
      List.of(_items);

  @override
  Future<void> markRead(int notificationId) async {
    final i = _items.indexWhere((n) => n.id == notificationId);
    if (i >= 0) _items[i] = _items[i].copyWith(isRead: true);
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }
}
