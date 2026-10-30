import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/my_membership.dart';
import '../../data/repositories/membership_repository.dart';

/// 내 가입 신청·가입 현황 (마이 탭)
/// 마이 탭을 누를 때, 로그인할 때 다시 불러온다.
class MembershipProvider extends ChangeNotifier {
  MembershipProvider(this._repository);

  final MembershipRepository _repository;

  List<MyMembership> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 취소한 신청은 목록에서 숨김
  List<MyMembership> get items =>
      _items.where((m) => m.status != 'CANCELED').toList();

  List<MyMembership> get joined =>
      items.where((m) => m.status == 'APPROVED').toList();

  List<MyMembership> get applications =>
      items.where((m) => m.status != 'APPROVED').toList();

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.fetchMyMemberships();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = '가입 현황을 불러오지 못했어요.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _items = [];
    _errorMessage = null;
    notifyListeners();
  }
}
