import '../../core/network/api_client.dart';
import '../mock/mock_clubs.dart';
import '../models/club.dart';

/// 동아리 데이터를 가져오는 방법을 정의한 인터페이스.
/// 화면(Provider)은 이 인터페이스만 알고, 실제 구현이 가짜 데이터인지
/// 서버 API인지는 main.dart에서 갈아끼운다.
abstract class ClubRepository {
  Future<List<Club>> fetchClubs();

  /// 즐겨찾기 추가(true) / 해제(false)
  Future<void> setFavorite(int clubId, {required bool favorite});
}

/// 서버 연동 전 사용하는 가짜 구현 (테스트·디자인 확인용)
class MockClubRepository implements ClubRepository {
  @override
  Future<List<Club>> fetchClubs() async {
    // 네트워크 지연 흉내
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return mockClubs;
  }

  @override
  Future<void> setFavorite(int clubId, {required bool favorite}) async {}
}

/// 실제 서버(FastAPI)와 통신하는 구현
class ApiClubRepository implements ClubRepository {
  ApiClubRepository(this._api);

  final ApiClient _api;

  /// GET /clubs (삭제된 동아리는 서버가 제외해서 보냄)
  /// 로그인 토큰은 ApiClient가 자동으로 붙여서 is_favorite·my_status까지 받아옴
  @override
  Future<List<Club>> fetchClubs() async {
    final data = await _api.get('/clubs', query: {'limit': '100'});
    return (data as List<dynamic>)
        .map((e) => Club.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST / DELETE /clubs/{club_id}/favorite
  @override
  Future<void> setFavorite(int clubId, {required bool favorite}) async {
    if (favorite) {
      await _api.post('/clubs/$clubId/favorite');
    } else {
      await _api.delete('/clubs/$clubId/favorite');
    }
  }
}
