import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
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
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
