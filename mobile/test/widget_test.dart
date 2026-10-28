import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/app.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/models/user.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/data/repositories/club_repository.dart';
import 'package:mobile/features/auth/auth_provider.dart';
import 'package:mobile/features/club/club_provider.dart';

/// 서버 없이 테스트하기 위한 가짜 로그인 저장소
class FakeAuthRepository implements AuthRepository {
  static const validEmail = 'student1@cbnu.ac.kr';
  static const validPassword = 'test1234';

  @override
  Future<String> login({required String email, required String password}) async {
    if (email == validEmail && password == validPassword) return 'fake-token';
    throw const ApiException(
      statusCode: 401,
      message: '이메일 또는 비밀번호가 올바르지 않습니다.',
    );
  }

  @override
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {}

  @override
  Future<User> fetchMe() async => const User(
        id: 1,
        email: validEmail,
        name: '학생1',
        role: 'STUDENT',
      );
}

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(FakeAuthRepository(), TokenStorage()),
        ),
        ChangeNotifierProvider(
          create: (_) => ClubProvider(MockClubRepository())..loadClubs(),
        ),
      ],
      child: const ClubItApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// 로그인 화면 입력창: 0번 이메일, 1번 비밀번호
Finder loginField(int index) => find.byType(TextFormField).at(index);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('빈 값으로 로그인하면 검증 문구가 보인다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('이메일을 입력해주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);
  });

  testWidgets('비밀번호가 틀리면 서버 오류 메시지가 보인다', (tester) async {
    await pumpApp(tester);

    await tester.enterText(loginField(0), FakeAuthRepository.validEmail);
    await tester.enterText(loginField(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('이메일 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
  });

  testWidgets('로그인에 성공하면 동아리 목록으로 이동한다', (tester) async {
    await pumpApp(tester);

    await tester.enterText(loginField(0), FakeAuthRepository.validEmail);
    await tester.enterText(
        loginField(1), FakeAuthRepository.validPassword);
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('동아리 목록'), findsOneWidget);
    expect(find.text('CATS'), findsOneWidget);
  });
}
