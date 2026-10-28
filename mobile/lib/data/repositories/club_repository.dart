import '../mock/mock_clubs.dart';
import '../models/club.dart';

/// 동아리 데이터를 가져오는 방법을 정의한 인터페이스.
/// 화면(Provider)은 이 인터페이스만 알고, 실제 구현이 가짜 데이터인지
/// 서버 API인지는 main.dart에서 갈아끼운다.
abstract class ClubRepository {
  Future<List<Club>> fetchClubs();
}

/// 서버 연동 전 사용하는 가짜 구현
class MockClubRepository implements ClubRepository {
  @override
  Future<List<Club>> fetchClubs() async {
    // 네트워크 지연 흉내
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return mockClubs;
  }
}

// TODO(서버 연동 단계): ApiClubRepository implements ClubRepository 작성
