import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/club_repository.dart';
import 'features/auth/auth_provider.dart';
import 'features/club/club_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // 서버 연동 시 MockClubRepository() → ApiClubRepository()로 교체
        ChangeNotifierProvider(
          create: (_) => ClubProvider(MockClubRepository())..loadClubs(),
        ),
      ],
      child: const ClubItApp(),
    ),
  );
}
