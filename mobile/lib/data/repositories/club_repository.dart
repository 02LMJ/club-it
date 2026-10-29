import '../../core/network/api_client.dart';
import '../mock/mock_clubs.dart';
import '../models/club.dart';
import '../models/post.dart';

/// 동아리 데이터를 가져오는 방법을 정의한 인터페이스.
/// 화면(Provider)은 이 인터페이스만 알고, 실제 구현이 가짜 데이터인지
/// 서버 API인지는 main.dart에서 갈아끼운다.
abstract class ClubRepository {
  Future<List<Club>> fetchClubs();

  /// 동아리 상세 (내 가입 상태·역할 포함)
  Future<Club> fetchClub(int clubId);

  /// 동아리 게시물 목록 (최신순)
  Future<List<Post>> fetchPosts(int clubId);

  Future<void> addFavorite(int clubId);

  Future<void> removeFavorite(int clubId);
}

/// 실제 서버(FastAPI)와 통신하는 구현
class ApiClubRepository implements ClubRepository {
  ApiClubRepository(this._api);

  final ApiClient _api;

  /// 로그인 토큰이 함께 가므로 응답에 is_favorite, my_status가 채워진다.
  /// 검색·필터는 받아온 목록에서 앱이 바로 처리 (타이핑할 때마다 요청하지 않도록)
  @override
  Future<List<Club>> fetchClubs() async {
    final data = await _api.get('/clubs', query: {'limit': '100'});
    return (data as List)
        .map((e) => Club.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Club> fetchClub(int clubId) async {
    final data = await _api.get('/clubs/$clubId');
    return Club.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Post>> fetchPosts(int clubId) async {
    final data = await _api.get('/clubs/$clubId/posts', query: {'limit': '50'});
    return (data as List)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addFavorite(int clubId) async {
    await _api.post('/clubs/$clubId/favorite');
  }

  @override
  Future<void> removeFavorite(int clubId) async {
    await _api.delete('/clubs/$clubId/favorite');
  }
}

/// 서버 없이 화면을 개발·테스트할 때 쓰는 가짜 구현
class MockClubRepository implements ClubRepository {
  @override
  Future<List<Club>> fetchClubs() async {
    // 네트워크 지연 흉내
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return mockClubs;
  }

  @override
  Future<Club> fetchClub(int clubId) async {
    return mockClubs.firstWhere((c) => c.id == clubId);
  }

  @override
  Future<List<Post>> fetchPosts(int clubId) async {
    return mockPosts.where((p) => p.clubId == clubId).toList();
  }

  @override
  Future<void> addFavorite(int clubId) async {}

  @override
  Future<void> removeFavorite(int clubId) async {}
}
