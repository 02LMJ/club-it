import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
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
  String? _selectedCategory; // null이면 '전체'
  bool _recruitingOnly = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;
  String? get selectedCategory => _selectedCategory;
  bool get recruitingOnly => _recruitingOnly;

  /// 칩으로 보여줄 카테고리 목록 (불러온 동아리에 있는 것만, 정해진 순서대로)
  List<String> get categories {
    const order = ['학술', '봉사', '예술', '체육', '종교', '취미', '기타'];
    final existing = _clubs.map((c) => c.category).toSet();
    return [
      ...order.where(existing.contains),
      ...existing.where((c) => !order.contains(c)),
    ];
  }

  /// 검색어 + 카테고리 + 모집 중 필터가 모두 적용된 동아리 목록
  List<Club> get filteredClubs {
    final keyword = _keyword.trim().toLowerCase();
    return _clubs.where((club) {
      if (_selectedCategory != null && club.category != _selectedCategory) {
        return false;
      }
      if (_recruitingOnly && !club.isRecruiting) return false;
      if (keyword.isEmpty) return true;
      return club.name.toLowerCase().contains(keyword) ||
          club.category.toLowerCase().contains(keyword) ||
          club.description.toLowerCase().contains(keyword);
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
      // 서버가 알려준 즐겨찾기 상태로 초기화
      _favoriteIds
        ..clear()
        ..addAll(_clubs.where((c) => c.isFavorite).map((c) => c.id));
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
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

  /// null을 넘기면 '전체'
  void selectCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setRecruitingOnly(bool value) {
    _recruitingOnly = value;
    notifyListeners();
  }

  /// 별을 누르면 화면에 먼저 반영하고 서버에 저장.
  /// 서버 저장에 실패하면 원래대로 되돌리고 [ApiException]을 던진다.
  Future<void> toggleFavorite(int clubId) async {
    final wasFavorite = _favoriteIds.contains(clubId);
    _setFavorite(clubId, !wasFavorite);
    try {
      if (wasFavorite) {
        await _repository.removeFavorite(clubId);
      } else {
        await _repository.addFavorite(clubId);
      }
    } catch (_) {
      _setFavorite(clubId, wasFavorite);
      rethrow;
    }
  }

  void _setFavorite(int clubId, bool value) {
    value ? _favoriteIds.add(clubId) : _favoriteIds.remove(clubId);
    notifyListeners();
  }

  /// 로그아웃 시: 사용자별 정보(즐겨찾기 등) 비우기
  void clear() {
    _clubs = [];
    _favoriteIds.clear();
    _keyword = '';
    _selectedCategory = null;
    _recruitingOnly = false;
    _errorMessage = null;
    notifyListeners();
  }
}
