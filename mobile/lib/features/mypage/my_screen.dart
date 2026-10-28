import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import '../auth/auth_provider.dart';

/// S09 마이 탭 — 구조 확인용 임시 화면
/// TODO(마이페이지 단계): 내 정보, 내 가입 신청 현황(신청중/승인/거부+사유)
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.assignment_outlined),
            title: Text('내 가입 신청 현황'),
            subtitle: Text('준비 중'),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('디자인 미리보기 (개발용)'),
            onTap: () => context.push(RoutePaths.designPreview),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            // 로그아웃 → router가 로그인 화면으로 이동시킴
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }
}
