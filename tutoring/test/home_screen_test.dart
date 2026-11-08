import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/home/presentation/controllers/home_summary.dart';
import 'package:tutoring/features/home/presentation/home_screen.dart';
import 'package:tutoring/features/home/presentation/widgets/home_search_sheet.dart';
import 'package:tutoring/features/home/presentation/controllers/home_search.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

class _Stub extends StatelessWidget {
  const _Stub(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(text)));
}

GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(path: AppRoutes.my, builder: (_, _) => const _Stub('my page')),
    GoRoute(
      path: AppRoutes.classPath,
      builder: (_, state) => _Stub('class ${state.pathParameters['classId']}'),
    ),
    GoRoute(
      path: AppRoutes.classReviewPath,
      builder: (_, state) => _Stub('review ${state.pathParameters['classId']}'),
    ),
    GoRoute(
      path: AppRoutes.noteReaderPath,
      builder: (_, state) => _Stub('reader ${state.pathParameters['noteId']}'),
    ),
  ],
);

List<StudyClass> _threeClasses() => [
  sampleClass(),
  sampleClass(id: 'class-2', title: '자료구조 스터디'),
  sampleClass(id: 'class-3', title: '알고리즘 스터디'),
];

/// Clock one hour after the fixtures' timestamps, so "오늘" holds them.
final _clock = homeClockProvider.overrideWithValue(
  () => testDate.add(const Duration(hours: 1)),
);

Widget _app({
  List<StudyClass>? classes,
  UserRole role = UserRole.tutee,
  FakeNotificationRepository? notifications,
}) => buildSignedInApp(
  router: _router(),
  user: role == UserRole.tutor ? tutorUser : tuteeUser,
  role: role,
  classes: classes ?? _threeClasses(),
  reviews: FakeReviewRepository(sampleReviews()),
  notificationRepository: notifications,
  extraOverrides: [_clock],
);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testAtScreenSizes(
    'home shows greeting, live summary and the class shelf',
    _app,
    sizes: TestScreenSizes.allWithNarrowTablet,
    verify: (tester, size) async {
      expect(find.text('안녕하세요, 이튜티님 👋'), findsOneWidget);
      expect(find.text('오늘 푼 퀴즈'), findsOneWidget);
      expect(find.text('1개'), findsOneWidget);
      expect(find.text('남은 복습'), findsOneWidget);
      expect(find.text('2개'), findsOneWidget);
      expect(find.text('3개 진행 중'), findsOneWidget);
      expect(find.text('진행률'), findsNothing);
      expect(find.textContaining('최근 학습: Week 3'), findsNWidgets(3));

      // Columns: 1 on mobile, 2 on tablet, 3 on desktop.
      final tops = [
        for (final id in ['class-1', 'class-2', 'class-3'])
          tester.getRect(find.byKey(HomeScreen.classCardKey(id))).top,
      ];
      final expectedColumns = switch (size.width) {
        < 600 => 1,
        < 1200 => 2,
        _ => 3,
      };
      expect(tops.toSet().length, 3 - expectedColumns + 1);

      // Bottom tabs below desktop; 마이 moves into the avatar menu on PC.
      expect(
        find.text('마이'),
        size.width >= 1200 ? findsNothing : findsOneWidget,
      );
    },
  );

  testAtScreenSizes(
    'empty home follows 01_Home_Empty',
    () => _app(classes: const []),
    verify: (tester, size) async {
      expect(find.text('아직 참여한 클래스가 없어요.'), findsOneWidget);
      expect(find.text('클래스 추가하기'), findsOneWidget);
      expect(find.text('클래스 추가'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('오늘 푼 퀴즈'), findsNothing);
      expect(find.text('새로운 스터디 찾기'), findsNothing);
    },
  );

  testWidgets('tutor summary counts drafts and this week\'s publishes', (
    tester,
  ) async {
    await tester.pumpAtSize(
      _app(classes: [sampleClass()], role: UserRole.tutor),
      TestScreenSizes.tablet,
    );
    expect(find.text('안녕하세요, 김튜터님 👋'), findsOneWidget);
    expect(find.text('작성 중 노트'), findsOneWidget);
    expect(find.text('1개'), findsOneWidget);
    expect(find.text('이번 주 게시'), findsOneWidget);
    expect(find.text('2개'), findsOneWidget);
  });

  testWidgets('the avatar opens 마이 directly', (tester) async {
    await tester.pumpAtSize(_app(), TestScreenSizes.desktop);
    await tester.tap(find.byTooltip('마이'));
    await _settle(tester);
    expect(find.text('my page'), findsOneWidget);
  });

  testWidgets('search lists classes and notes and opens the reader', (
    tester,
  ) async {
    await tester.pumpAtSize(_app(), TestScreenSizes.desktop);
    await tester.tap(find.byTooltip('검색'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '스터디');
    await tester.pump();
    expect(find.text('파이썬 기초 스터디'), findsWidgets);
    expect(find.text('자료구조 스터디'), findsWidgets);

    await tester.enterText(find.byType(TextField), '딕셔너리');
    await tester.pump();
    final note = HomeSearchResult.note(
      sampleClass(),
      sampleNote(id: 'note-3', week: 3),
    );
    await tester.tap(find.byKey(HomeSearchSheet.resultKey(note)).first);
    await _settle(tester);
    expect(find.text('reader note-3'), findsOneWidget);
  });

  testWidgets('card ⋯ opens the class info sheet', (tester) async {
    await tester.pumpAtSize(
      _app(classes: [sampleClass()]),
      TestScreenSizes.tablet,
    );
    await tester.tap(find.byTooltip('클래스 정보'));
    await tester.pumpAndSettle();
    expect(find.text('클래스 정보'), findsOneWidget);
    expect(find.text('ABCD1234'), findsOneWidget);
  });

  testWidgets('남은 복습 tile opens the busiest class review', (tester) async {
    await tester.pumpAtSize(_app(), TestScreenSizes.tablet);
    await tester.tap(find.text('남은 복습'));
    await _settle(tester);
    expect(find.text('review class-1'), findsOneWidget);
  });

  testWidgets('the bell shows unread notifications and opens them', (
    tester,
  ) async {
    final log = <String>[];
    final notifications = FakeNotificationRepository(
      log: log,
      items: [
        sampleNotification(id: 'n1', type: NotificationType.notePublished),
        sampleNotification(
          id: 'n2',
          type: NotificationType.quizPublished,
          targetId: 'quiz-1',
          title: '새 퀴즈가 게시됐어요',
          body: '딕셔너리 퀴즈',
        ),
        // Joins are for the tutor, so this one stays hidden for a student.
        sampleNotification(
          id: 'n3',
          type: NotificationType.memberJoined,
          actorId: 'tutee-2',
        ),
      ],
    );
    await tester.pumpAtSize(
      _app(notifications: notifications),
      TestScreenSizes.tablet,
    );
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();
    expect(find.text('새 노트가 게시됐어요'), findsOneWidget);
    expect(find.text('새 퀴즈가 게시됐어요'), findsOneWidget);
    expect(find.text('새 학생이 참여했어요'), findsNothing);
    expect(log, contains('notifications.seen'));

    await tester.tap(find.text('새 노트가 게시됐어요'));
    await _settle(tester);
    expect(find.text('reader note-3'), findsOneWidget);
  });

  testWidgets('a bell with nothing unread shows no badge', (tester) async {
    final notifications = FakeNotificationRepository(
      seenAt: testDate.add(const Duration(days: 1)),
      items: [
        sampleNotification(id: 'n1', type: NotificationType.notePublished),
      ],
    );
    await tester.pumpAtSize(
      _app(notifications: notifications),
      TestScreenSizes.desktop,
    );
    expect(find.text('1'), findsNothing);
  });
}
