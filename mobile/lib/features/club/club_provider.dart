import 'package:flutter/foundation.dart';

import '../../data/models/club.dart';
import '../../data/repositories/club_repository.dart';

/// 동아리 목록, 검색어, 즐겨찾기 상태 관리.
/// 홈 탭과 즐겨찾기 탭이 같은 객체를 보기 때문에
/// 한쪽에서 별을 누르면 다른 탭에도 바로 반영된다.
class ClubProvider extends ChangeNotifier {
  ClubProvider(this._repository);

  final ClubRepository _repository;

  List<Club> _clubs = [];
  final Set<int> _favoriteIds = {};
  String _keyword = '';
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;

  /// 검색어가 적용된 동아리 목록 (동아리명·카테고리·한 줄 소개에서 검색)
  List<Club> get filteredClubs {
    final keyword = _keyword.trim().toLowerCase();
    if (keyword.isEmpty) return List.unmodifiable(_clubs);
    return _clubs.where((club) {
      return club.name.toLowerCase().contains(keyword) ||
          club.category.toLowerCase().contains(keyword) ||
          club.summary.toLowerCase().contains(keyword);
    }).toList();
  }

  List<Club> get favoriteClubs =>
      _clubs.where((club) => _favoriteIds.contains(club.id)).toList();

  Club? findById(int id) {
    for (final club in _clubs) {
      if (club.id == id) return club;
    }
    return null;
  }

  bool isFavorite(int clubId) => _favoriteIds.contains(clubId);

  Future<void> loadClubs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _clubs = await _repository.fetchClubs();
    } catch (e) {
      _errorMessage = '동아리 목록을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateKeyword(String value) {
    _keyword = value;
    notifyListeners();
  }

  /// TODO(즐겨찾기 구현 단계): 서버 FAVORITE API 호출
  void toggleFavorite(int clubId) {
    if (!_favoriteIds.remove(clubId)) {
      _favoriteIds.add(clubId);
    }
    notifyListeners();
  }
}
