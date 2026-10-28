import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
import 'core/storage/token_storage.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/club_repository.dart';
import 'features/auth/auth_provider.dart';
import 'features/club/club_provider.dart';

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

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        // TODO(동아리 목록 서버 연동 단계): ApiClubRepository(apiClient)로 교체
        ChangeNotifierProvider(
          create: (_) => ClubProvider(MockClubRepository())..loadClubs(),
        ),
      ],
      child: const ClubItApp(),
    ),
  );
}
