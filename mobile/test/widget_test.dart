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
import 'package:mobile/data/repositories/membership_repository.dart';
import 'package:mobile/data/repositories/post_repository.dart';
import 'package:mobile/features/auth/auth_provider.dart';
import 'package:mobile/features/club/club_provider.dart';
import 'package:mobile/features/mypage/membership_provider.dart';

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
        ChangeNotifierProvider(
          create: (_) => MembershipProvider(MockMembershipRepository()),
        ),
        Provider<PostRepository>(create: (_) => MockPostRepository()),
      ],
      child: const ClubItApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  // 시작 화면 → 로그인 화면
  expect(find.text('우리 학교 동아리, 한 곳에서'), findsOneWidget);
  await tester.tap(find.widgetWithText(FilledButton, '로그인'));
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

    expect(find.textContaining('어떤 동아리를'), findsOneWidget);
    expect(find.text('CATS'), findsOneWidget);
  });

  testWidgets('카테고리 칩과 모집 중만 필터가 동작한다', (tester) async {
    await pumpApp(tester);
    await tester.enterText(loginField(0), FakeAuthRepository.validEmail);
    await tester.enterText(
        loginField(1), FakeAuthRepository.validPassword);
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('전체 동아리 6'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '봉사'));
    await tester.pumpAndSettle();
    expect(find.text('봉사 동아리 1'), findsOneWidget);
    expect(find.text('IPSE'), findsOneWidget);
    expect(find.text('CATS'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '전체'));
    await tester.tap(find.text('모집 중만'));
    await tester.pumpAndSettle();
    expect(find.text('전체 동아리 4'), findsOneWidget); // 모집 마감 2개 숨김
    expect(find.text('COSMIC'), findsNothing); // 모집 마감 동아리는 숨김
  });

  testWidgets('동아리 카드를 누르면 상세 화면(소개·게시판·가입 버튼)이 열린다',
      (tester) async {
    await pumpApp(tester);
    await tester.enterText(loginField(0), FakeAuthRepository.validEmail);
    await tester.enterText(
        loginField(1), FakeAuthRepository.validPassword);
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CATS'));
    await tester.pumpAndSettle();

    expect(find.text('동아리 소개'), findsOneWidget);
    expect(find.text('게시판 2'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '가입 신청하기'), findsOneWidget);

    await tester.tap(find.text('게시판 2'));
    await tester.pumpAndSettle();
    expect(find.text('이번 주 스터디 공지'), findsOneWidget);
  });

  testWidgets('가입 신청하면 대기 중이 되고, 신청 취소하면 다시 신청할 수 있다',
      (tester) async {
    await pumpApp(tester);
    await tester.enterText(loginField(0), FakeAuthRepository.validEmail);
    await tester.enterText(
        loginField(1), FakeAuthRepository.validPassword);
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    // 상세 → 가입 신청 화면
    await tester.tap(find.text('CATS'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '가입 신청하기'));
    await tester.pumpAndSettle();
    expect(find.text('신청자 정보'), findsOneWidget);
    expect(find.text('학생1'), findsOneWidget); // 로그인 정보 자동 입력

    // 신청하기 → 확인 창 → 신청
    await tester.enterText(find.byType(TextFormField), '열심히 하겠습니다!');
    await tester.tap(find.widgetWithText(FilledButton, '신청하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '신청'));
    await tester.pumpAndSettle();

    // 상세 화면으로 돌아와서 대기 중 + 신청 취소 버튼
    expect(find.textContaining('승인을 기다리고 있어요'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '신청 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '신청 취소'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '가입 신청하기'), findsOneWidget);
  });

  testWidgets('게시물 상세에서 댓글을 작성하고 삭제할 수 있다', (tester) async {
    await pumpApp(tester);
    await tester.enterText(loginField(0), FakeAuthRepository.validEmail);
    await tester.enterText(
        loginField(1), FakeAuthRepository.validPassword);
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    // 홈 → CATS 상세 → 게시판 탭 → 게시물
    await tester.tap(find.text('CATS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('게시판 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이번 주 스터디 공지'));
    await tester.pumpAndSettle();

    expect(find.text('댓글 1'), findsOneWidget);
    expect(find.text('이번 주는 그래프 문제를 풀어요.'), findsOneWidget);

    // 댓글 작성
    await tester.enterText(find.byType(TextField).last, '참석할게요!');
    await tester.tap(find.byTooltip('댓글 등록'));
    await tester.pumpAndSettle();
    expect(find.text('댓글 2'), findsOneWidget);
    expect(find.text('참석할게요!'), findsOneWidget);

    // 내 댓글 메뉴 → 삭제 → 확인
    await tester.tap(find.byTooltip('댓글 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();
    expect(find.text('댓글 1'), findsOneWidget);
    expect(find.text('참석할게요!'), findsNothing);
  });

  testWidgets('마이 탭에서 가입 신청 현황과 거절 사유를 볼 수 있다', (tester) async {
    await pumpApp(tester);
    await tester.enterText(loginField(0), FakeAuthRepository.validEmail);
    await tester.enterText(
        loginField(1), FakeAuthRepository.validPassword);
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    expect(find.text('가입 신청 현황 2'), findsOneWidget);
    expect(find.text('승인 대기'), findsOneWidget);
    expect(find.text('거절 사유: 이번 학기 모집 정원 마감'), findsOneWidget);
  });

  testWidgets('게시판에서 종류 칩으로 공지·모집·홍보만 골라 볼 수 있다', (tester) async {
    await pumpApp(tester);
    await tester.enterText(loginField(0), FakeAuthRepository.validEmail);
    await tester.enterText(
        loginField(1), FakeAuthRepository.validPassword);
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CATS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('게시판 2'));
    await tester.pumpAndSettle();

    // 처음엔 전체: 공지 + 모집글
    expect(find.text('이번 주 스터디 공지'), findsOneWidget);
    expect(find.text('2026-2 신입 부원 모집'), findsOneWidget);

    // 모집만
    await tester.tap(find.widgetWithText(ChoiceChip, '모집'));
    await tester.pumpAndSettle();
    expect(find.text('2026-2 신입 부원 모집'), findsOneWidget);
    expect(find.text('이번 주 스터디 공지'), findsNothing);

    // 홍보글은 없음
    await tester.tap(find.widgetWithText(ChoiceChip, '홍보'));
    await tester.pumpAndSettle();
    expect(find.text('홍보 게시물이 없어요'), findsOneWidget);

    // 다시 전체
    await tester.tap(find.widgetWithText(ChoiceChip, '전체'));
    await tester.pumpAndSettle();
    expect(find.text('이번 주 스터디 공지'), findsOneWidget);
  });
}
