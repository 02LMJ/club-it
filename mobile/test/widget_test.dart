import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/app.dart';
import 'package:mobile/data/repositories/club_repository.dart';
import 'package:mobile/features/auth/auth_provider.dart';
import 'package:mobile/features/club/club_provider.dart';

void main() {
  testWidgets('로그인 전에는 로그인 화면, 로그인 후에는 동아리 목록이 보인다',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(
            create: (_) => ClubProvider(MockClubRepository())..loadClubs(),
          ),
        ],
        child: const ClubItApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('로그인 (임시)'), findsOneWidget);

    await tester.tap(find.text('로그인 (임시)'));
    // 가짜 데이터 로딩 지연(300ms)이 끝날 때까지 기다림
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('동아리 목록'), findsOneWidget);
    expect(find.text('CATS'), findsOneWidget);
  });
}
