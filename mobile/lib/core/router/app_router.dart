import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/club/club_apply_screen.dart';
import '../../features/club/club_detail_screen.dart';
import '../../features/club/club_list_screen.dart';
import '../../features/dev/design_preview_screen.dart';
import '../../features/favorite/favorite_screen.dart';
import '../../features/mypage/my_screen.dart';
import '../../features/notification/notification_screen.dart';
import '../../features/post/post_detail_screen.dart';
import '../../features/shell/main_shell.dart';
import 'route_paths.dart';

/// 앱 전체 화면 이동 규칙.
///
/// /welcome, /login, /signup  로그인 전 화면
/// /, /favorites, ...         하단 탭 4개 (MainShell 안에서 열림)
/// /clubs/:id, /posts/:id     상세 화면 (하단 탭 없이 전체 화면)
GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    // 로그인 상태가 바뀌면 redirect를 다시 검사
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthPage = location == RoutePaths.welcome ||
          location == RoutePaths.login ||
          location == RoutePaths.signup;

      // 로그인 안 했으면 시작 화면으로
      if (!auth.isLoggedIn && !isAuthPage) return RoutePaths.welcome;
      // 로그인 했는데 로그인 화면이면 홈으로
      if (auth.isLoggedIn && isAuthPage) return RoutePaths.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        builder: (context, state) => const SignupScreen(),
      ),

      // 하단 탭: 탭마다 화면 상태(스크롤 위치 등)를 따로 유지
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const ClubListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.favorites,
              builder: (context, state) => const FavoriteScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.notifications,
              builder: (context, state) => const NotificationScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.my,
              builder: (context, state) => const MyScreen(),
            ),
          ]),
        ],
      ),

      // 상세 화면
      GoRoute(
        path: '/clubs/:clubId',
        builder: (context, state) =>
            ClubDetailScreen(clubId: _idParam(state, 'clubId')),
        routes: [
          GoRoute(
            path: 'apply',
            builder: (context, state) =>
                ClubApplyScreen(clubId: _idParam(state, 'clubId')),
          ),
        ],
      ),
      GoRoute(
        path: '/posts/:postId',
        builder: (context, state) =>
            PostDetailScreen(postId: _idParam(state, 'postId')),
      ),

      // 개발용: 공통 디자인 요소 미리보기
      GoRoute(
        path: RoutePaths.designPreview,
        builder: (context, state) => const DesignPreviewScreen(),
      ),
    ],
  );
}

int _idParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '') ?? -1;
