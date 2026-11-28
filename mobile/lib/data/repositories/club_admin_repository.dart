import '../../core/network/api_client.dart';
import '../models/club_application.dart';

/// 동아리 임원 전용: 가입 신청 관리, 부원 목록
abstract class ClubAdminRepository {
  /// 대기 중인 가입 신청 목록 (먼저 신청한 순)
  Future<List<ClubApplication>> fetchApplications(int clubId);

  /// 가입 신청 승인 / 거절(사유 포함). 처리 결과는 신청자에게 알림으로 감
  Future<void> decideApplication(
    int clubId,
    int membershipId, {
    required bool approve,
    String? rejectReason,
  });

  /// 승인된 부원 목록 (임원 먼저, 이름순)
  Future<List<ClubApplication>> fetchMembers(int clubId);
}

/// 실제 서버(FastAPI)와 통신하는 구현
class ApiClubAdminRepository implements ClubAdminRepository {
  ApiClubAdminRepository(this._api);

  final ApiClient _api;

  /// GET /clubs/{clubId}/applications?status=PENDING
  @override
  Future<List<ClubApplication>> fetchApplications(int clubId) async {
    final data = await _api.get(
      '/clubs/$clubId/applications',
      query: {'status': 'PENDING'},
    );
    return (data as List)
        .map((e) => ClubApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /clubs/{clubId}/applications/{membershipId}
  @override
  Future<void> decideApplication(
    int clubId,
    int membershipId, {
    required bool approve,
    String? rejectReason,
  }) async {
    await _api.patch('/clubs/$clubId/applications/$membershipId', body: {
      'status': approve ? 'APPROVED' : 'REJECTED',
      if (!approve) 'reject_reason': rejectReason,
    });
  }

  /// GET /clubs/{clubId}/members
  @override
  Future<List<ClubApplication>> fetchMembers(int clubId) async {
    final data = await _api.get('/clubs/$clubId/members');
    return (data as List)
        .map((e) => ClubApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// 서버 없이 화면을 개발·테스트할 때 쓰는 가짜 구현
class MockClubAdminRepository implements ClubAdminRepository {
  final List<ClubApplication> _pending = [
    ClubApplication(
      id: 11,
      userId: 4,
      userName: '학생2',
      userEmail: 'student2@cbnu.ac.kr',
      status: 'PENDING',
      role: 'MEMBER',
      joinDate: DateTime(2026, 11, 25, 14, 0),
      message: '기타를 3년 쳤고 공연 무대에 서 보고 싶어요!',
    ),
    ClubApplication(
      id: 12,
      userId: 5,
      userName: '학생3',
      userEmail: 'student3@cbnu.ac.kr',
      status: 'PENDING',
      role: 'MEMBER',
      joinDate: DateTime(2026, 11, 26, 9, 30),
    ),
  ];

  @override
  Future<List<ClubApplication>> fetchApplications(int clubId) async =>
      List.of(_pending);

  @override
  Future<void> decideApplication(
    int clubId,
    int membershipId, {
    required bool approve,
    String? rejectReason,
  }) async {
    final i = _pending.indexWhere((a) => a.id == membershipId);
    if (i < 0) return;
    final a = _pending.removeAt(i);
    if (approve) {
      _members.add(ClubApplication(
        id: a.id,
        userId: a.userId,
        userName: a.userName,
        userEmail: a.userEmail,
        status: 'APPROVED',
        role: 'MEMBER',
        joinDate: a.joinDate,
        message: a.message,
      ));
    }
  }

  final List<ClubApplication> _members = [
    ClubApplication(
      id: 1,
      userId: 1,
      userName: '학생1',
      userEmail: 'student1@cbnu.ac.kr',
      status: 'APPROVED',
      role: 'OFFICER',
      joinDate: DateTime(2026, 3, 2, 10, 0),
    ),
    ClubApplication(
      id: 5,
      userId: 6,
      userName: '김부원',
      userEmail: 'member1@cbnu.ac.kr',
      status: 'APPROVED',
      role: 'MEMBER',
      joinDate: DateTime(2026, 3, 10, 18, 0),
    ),
  ];

  @override
  Future<List<ClubApplication>> fetchMembers(int clubId) async {
    final list = List.of(_members)
      ..sort((a, b) {
        if (a.role != b.role) return a.role == 'OFFICER' ? -1 : 1;
        return a.userName.compareTo(b.userName);
      });
    return list;
  }
}
