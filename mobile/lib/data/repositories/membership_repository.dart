import '../../core/network/api_client.dart';
import '../models/my_membership.dart';

/// 내 가입 신청·가입 현황
abstract class MembershipRepository {
  Future<List<MyMembership>> fetchMyMemberships();
}

/// 실제 서버(FastAPI)와 통신하는 구현
class ApiMembershipRepository implements MembershipRepository {
  ApiMembershipRepository(this._api);

  final ApiClient _api;

  /// GET /me/memberships (최근 신청 순)
  @override
  Future<List<MyMembership>> fetchMyMemberships() async {
    final data = await _api.get('/me/memberships');
    return (data as List)
        .map((e) => MyMembership.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// 서버 없이 화면을 개발·테스트할 때 쓰는 가짜 구현
class MockMembershipRepository implements MembershipRepository {
  @override
  Future<List<MyMembership>> fetchMyMemberships() async {
    return [
      MyMembership(
        id: 1,
        clubId: 3,
        clubName: 'IPSE',
        status: 'PENDING',
        role: 'MEMBER',
        joinDate: DateTime(2026, 10, 29, 12, 0),
        message: '봉사 활동에 관심이 많습니다.',
      ),
      MyMembership(
        id: 2,
        clubId: 1,
        clubName: 'CATS',
        status: 'REJECTED',
        role: 'MEMBER',
        joinDate: DateTime(2026, 10, 20, 9, 0),
        rejectReason: '이번 학기 모집 정원 마감',
      ),
    ];
  }
}
