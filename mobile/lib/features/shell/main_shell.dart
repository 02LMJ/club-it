import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../mypage/membership_provider.dart';
import '../notification/notification_provider.dart';

/// 하단 탭 4개(홈·즐겨찾기·알림·마이)를 감싸는 틀
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    // 탭을 옮길 때마다 알림을 새로 불러와 배지 숫자를 최신으로 유지
    context.read<NotificationProvider>().load();
    // 마이 탭을 누를 때마다 가입 현황을 새로 불러옴
    if (index == 3) context.read<MembershipProvider>().load();
    // 이미 선택된 탭을 다시 누르면 그 탭의 첫 화면으로
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          const NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: '즐겨찾기',
          ),
          NavigationDestination(
            icon: _UnreadBadge(
              count: unread,
              child: const Icon(Icons.notifications_none),
            ),
            selectedIcon: _UnreadBadge(
              count: unread,
              child: const Icon(Icons.notifications),
            ),
            label: '알림',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}

/// 알림 아이콘 위 안 읽은 개수 (0이면 숨김, 100개 이상은 99+)
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.accent,
      textColor: AppColors.surface,
      child: child,
    );
  }
}
