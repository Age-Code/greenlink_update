import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/classes/presentation/controllers/tutor_dashboard.dart';
import 'package:tutoring/features/classes/presentation/screens/tutor_class_home_screen.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

void main() {
  group('tutor dashboard aggregation', () {
    final notes = [sampleNote(id: 'note-3', week: 3), sampleNote(id: 'note-2', week: 2)];
    final quizzes = [sampleQuiz(id: 'quiz-1')];

    QuizAttempt quickCheck(String userId, String noteId) => QuizAttempt(
      id: 'qc-$userId',
      userId: userId,
      classId: 'class-1',
      quizId: 'quiz-1',
      noteId: noteId,
      startedAt: testDate,
      completedAt: testDate.add(const Duration(hours: 1)),
      totalQuestions: 1,
      correctCount: 1,
      answers: const [],
    );

    test('groups attempts per student and leaves the tutor out', () {
      final students = buildStudentProgress(
        members: sampleMembers(),
        publishedNotes: notes,
        publishedQuizzes: quizzes,
        attempts: [
          sampleAttempt(id: 'a1', quizId: 'quiz-1'),
          quickCheck('tutee-1', 'note-3'),
        ],
      );
      expect(students.map((s) => s.name), ['이튜티', '박학생']);
      final first = students.first;
      expect(first.quizzesDone, 1);
      expect(first.quizTotal, 1);
      expect(first.notesTouched, 1);
      expect(first.noteTotal, 2);
      expect(first.progressPercent, 100);
      expect(first.currentNote?.id, 'note-3');
      expect(first.lastStudied, testDate.add(const Duration(hours: 1)));
      final second = students.last;
      expect(second.progress, 0);
      expect(second.lastStudied, isNull);
      expect(second.currentNote, isNull);
    });

    test('average, weekly activity and submission rate', () {
      final students = buildStudentProgress(
        members: sampleMembers(),
        publishedNotes: notes,
        publishedQuizzes: quizzes,
        attempts: [sampleAttempt(id: 'a1', quizId: 'quiz-1')],
      );
      expect(averageProgress(students), 0.5);
      expect(
        activeThisWeek(students, now: testDate.add(const Duration(days: 2))),
        1,
      );
      expect(
        activeThisWeek(students, now: testDate.add(const Duration(days: 30))),
        0,
      );
      expect(
        submissionRate(
          students: students,
          publishedQuizzes: quizzes,
          attempts: [sampleAttempt(id: 'a1', quizId: 'quiz-1')],
        ),
        0.5,
      );
      expect(averageProgress(const []), 0);
      expect(
        submissionRate(students: students, publishedQuizzes: const [], attempts: const []),
        0,
      );
    });

    test('a resized quiz no longer counts an old attempt', () {
      final resized = sampleQuiz(id: 'quiz-1').copyWith(questionCount: 9);
      final students = buildStudentProgress(
        members: sampleMembers(),
        publishedNotes: notes,
        publishedQuizzes: [resized],
        attempts: [sampleAttempt(id: 'a1', quizId: 'quiz-1')],
      );
      expect(students.first.quizzesDone, 0);
    });

    test('semester label', () {
      expect(semesterLabel(DateTime(2026, 3, 2)), '2026년 1학기');
      expect(semesterLabel(DateTime(2026, 8, 31)), '2026년 1학기');
      expect(semesterLabel(DateTime(2026, 11, 7)), '2026년 2학기');
      expect(semesterLabel(DateTime(2027, 1, 15)), '2026년 2학기');
    });

    test('members without a stored name get a short label', () {
      expect(
        sampleMember(uid: 'abcdefgh', name: '').displayName,
        '학생 abcd',
      );
    });
  });

  Widget app({List<QuizAttempt>? attempts}) => buildSignedInApp(
    home: TutorClassHomeScreen(studyClass: sampleClass()),
    user: tutorUser,
    role: UserRole.tutor,
    attempts: attempts ?? [sampleAttempt(id: 'attempt-1', quizId: 'quiz-1')],
  );

  testAtScreenSizes(
    'tutor home shows the intro, draft, metrics, notes and students',
    app,
    sizes: TestScreenSizes.allWithNarrowTablet,
    verify: (tester, size) async {
      expect(find.text('강의 워크스페이스'), findsOneWidget);
      expect(find.text('2026년 2학기'), findsOneWidget);
      expect(find.text('최근 작업'), findsOneWidget);
      expect(find.text('Week 01 Week 1 · 딕셔너리와 집합 자료형 정리'), findsOneWidget);
      expect(find.text('이어서 작성'), findsOneWidget);
      expect(find.text('노트 2개'), findsOneWidget);
      expect(find.text('퀴즈 1개'), findsOneWidget);
      expect(find.text('평균 제출율 50%'), findsOneWidget);
      expect(find.text('참여 학생 2명'), findsOneWidget);
      expect(find.text('1명 이번 주 활동'), findsOneWidget);
      expect(find.text('최근 노트'), findsOneWidget);
      expect(find.text('게시됨'), findsNWidgets(2));
      expect(find.text('작성 중'), findsNWidgets(2));
      expect(find.text('평균 학습 진행률'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('2명 중 1명이 이번 주 학습을 진행하고 있어요.'), findsOneWidget);
      expect(find.text('이튜티'), findsOneWidget);
      expect(find.text('박학생'), findsOneWidget);
      expect(find.text('노트 0/2 · 퀴즈 1/1'), findsOneWidget);
      expect(find.text('노트 0/2 · 퀴즈 0/1'), findsOneWidget);
      expect(find.text('새 노트 작성'), findsWidgets);
      expect(find.text('참여자'), findsNothing);
      if (size.width < 600) {
        expect(find.byType(SingleChildScrollView), findsWidgets);
      }
    },
  );

  testWidgets('no students and no drafts read plainly', (tester) async {
    await tester.pumpAtSize(
      buildSignedInApp(
        home: TutorClassHomeScreen(studyClass: sampleClass()),
        user: tutorUser,
        role: UserRole.tutor,
        members: [sampleMember(uid: tutorUser.uid, name: '김튜터', role: UserRole.tutor)],
        notes: [
          sampleNote(id: 'note-3', week: 3, status: NoteStatus.published),
        ],
        attempts: const [],
      ),
      TestScreenSizes.tablet,
    );
    expect(find.text('작성 중인 노트가 없어요'), findsOneWidget);
    expect(find.text('참여 학생 0명'), findsOneWidget);
    expect(find.text('참여 코드를 공유해보세요'), findsOneWidget);
    expect(find.text('아직 참여한 학생이 없어요. 참여 코드를 공유해보세요.'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('the tutor drawer has the quick action, counts and exit', (
    tester,
  ) async {
    await tester.pumpAtSize(app(), TestScreenSizes.phone);
    await tester.tap(find.byTooltip('클래스 메뉴'));
    await tester.pumpAndSettle();
    expect(find.text('새 노트 작성'), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('클래스 정보'), findsOneWidget);
    expect(find.text('나가기'), findsOneWidget);
    expect(find.text('참여자'), findsNothing);
    expect(find.text('복습'), findsNothing);
  });
}
