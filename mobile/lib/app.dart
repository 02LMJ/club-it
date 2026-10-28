import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'features/auth/auth_provider.dart';

class ClubItApp extends StatefulWidget {
  const ClubItApp({super.key});

  @override
  State<ClubItApp> createState() => _ClubItAppState();
}

class _ClubItAppState extends State<ClubItApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Club-it',
      // TODO(공통 디자인 단계): core/theme/app_theme.dart로 분리
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
