import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
import 'core/storage/token_storage.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/club_repository.dart';
import 'data/repositories/membership_repository.dart';
import 'data/repositories/post_repository.dart';
import 'features/auth/auth_provider.dart';
import 'features/club/club_provider.dart';
import 'features/mypage/membership_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenStorage: tokenStorage,
  );
  final authProvider = AuthProvider(ApiAuthRepository(apiClient), tokenStorage);
  apiClient.onUnauthorized = authProvider.handleUnauthorized;

  // 저장된 토큰이 있으면 자동 로그인
  await authProvider.restore();

  // 동아리 목록: 실제 서버에서 불러오기 (서버 없이 화면만 볼 때는 MockClubRepository())
  final clubProvider = ClubProvider(ApiClubRepository(apiClient));
  final membershipProvider =
      MembershipProvider(ApiMembershipRepository(apiClient));
  if (authProvider.isLoggedIn) {
    clubProvider.loadClubs();
    membershipProvider.load();
  }

  // 로그인하면 내 즐겨찾기·가입 상태가 담긴 목록을 다시 불러오고, 로그아웃하면 비움
  var wasLoggedIn = authProvider.isLoggedIn;
  authProvider.addListener(() {
    if (authProvider.isLoggedIn == wasLoggedIn) return;
    wasLoggedIn = authProvider.isLoggedIn;
    if (wasLoggedIn) {
      clubProvider.loadClubs();
      membershipProvider.load();
    } else {
      clubProvider.clear();
      membershipProvider.clear();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ClubProvider>.value(value: clubProvider),
        ChangeNotifierProvider<MembershipProvider>.value(
          value: membershipProvider,
        ),
        Provider<PostRepository>.value(value: ApiPostRepository(apiClient)),
      ],
      child: const ClubItApp(),
    ),
  );
}
