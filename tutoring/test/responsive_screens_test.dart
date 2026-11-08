import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/classes/presentation/screens/class_home_screen.dart';
import 'package:tutoring/features/classes/presentation/screens/tutor_class_home_screen.dart';
import 'package:tutoring/features/home/presentation/home_screen.dart';
import 'package:tutoring/features/notes/presentation/screens/notes_list_screen.dart';
import 'package:tutoring/features/notes/presentation/screens/note_reader_screen.dart';
import 'package:tutoring/features/notes/presentation/screens/tutor_notes_screen.dart';
import 'package:tutoring/features/quizzes/presentation/screens/tutee_quiz_list_screen.dart';
import 'package:tutoring/features/quizzes/presentation/screens/tutor_quiz_list_screen.dart';
import 'package:tutoring/features/auth/presentation/screens/login_screen.dart';
import 'package:tutoring/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:tutoring/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:tutoring/features/notes/presentation/screens/tutor_note_editor_screen.dart';
import 'package:tutoring/features/quizzes/presentation/screens/quiz_solve_screen.dart';
import 'package:tutoring/features/quizzes/presentation/screens/tutor_quiz_editor_screen.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

/// Every signed-in screen must lay out without overflow at the phone,
/// tablet and desktop sizes (plus the narrowest tablet).
void main() {
  const sizes = TestScreenSizes.allWithNarrowTablet;

  testAtScreenSizes(
    'home with classes',
    () => buildSignedInApp(
      home: const HomeScreen(),
      user: tuteeUser,
      classes: [sampleClass(), sampleClass(id: 'class-2', title: '자료구조 스터디')],
    ),
    sizes: sizes,
    verify: (tester, size) async {
      expect(find.text('자료구조 스터디'), findsOneWidget);
    },
  );

  testAtScreenSizes(
    'home without classes',
    () => buildSignedInApp(
      home: const HomeScreen(),
      user: tuteeUser,
      classes: [],
    ),
    sizes: sizes,
  );

  testAtScreenSizes(
    'student class home',
    () => buildSignedInApp(
      home: const ClassHomeScreen(classId: 'class-1'),
      user: tuteeUser,
    ),
    sizes: sizes,
    verify: (tester, size) async {
      expect(find.text('파이썬 기초 스터디'), findsWidgets);
    },
  );

  testAtScreenSizes(
    'tutor class home',
    () => buildSignedInApp(
      home: TutorClassHomeScreen(studyClass: sampleClass()),
      user: tutorUser,
      role: UserRole.tutor,
    ),
    sizes: sizes,
  );

  testAtScreenSizes(
    'student notes list',
    () => buildSignedInApp(
      home: const NotesListScreen(classId: 'class-1'),
      user: tuteeUser,
    ),
    sizes: sizes,
  );

  testAtScreenSizes(
    'note reader',
    () => buildSignedInApp(
      home: const NoteReaderScreen(classId: 'class-1', noteId: 'note-2'),
      user: tuteeUser,
      blocks: sampleBlocks(),
    ),
    sizes: sizes,
    verify: (tester, size) async {
      expect(find.text('Quick Check'), findsOneWidget);
    },
  );

  testAtScreenSizes(
    'student quiz list',
    () => buildSignedInApp(
      home: const TuteeQuizListScreen(classId: 'class-1'),
      user: tuteeUser,
      attempts: [
        sampleAttempt(id: 'attempt-1', quizId: 'quiz-1'),
        sampleAttempt(id: 'attempt-2', quizId: 'quiz-1'),
      ],
    ),
    sizes: sizes,
    verify: (tester, size) async {
      expect(find.text('최근 점수 3/4 · 2번 풀었어요'), findsOneWidget);
      expect(find.text('다시 풀기'), findsOneWidget);
    },
  );

  testAtScreenSizes(
    'tutor notes',
    () => buildSignedInApp(
      home: const TutorNotesScreen(classId: 'class-1'),
      user: tutorUser,
      role: UserRole.tutor,
    ),
    sizes: sizes,
  );

  testAtScreenSizes(
    'tutor quizzes',
    () => buildSignedInApp(
      home: const TutorQuizListScreen(classId: 'class-1'),
      user: tutorUser,
      role: UserRole.tutor,
    ),
    sizes: sizes,
  );

  testAtScreenSizes(
    'quiz solve',
    () => buildSignedInApp(
      home: const QuizSolveScreen(classId: 'class-1', quizId: 'quiz-1'),
      user: tuteeUser,
    ),
    sizes: sizes,
  );

  testAtScreenSizes(
    'tutor note editor (new note)',
    () => buildSignedInApp(
      home: const TutorNoteEditorScreen(classId: 'class-1'),
      user: tutorUser,
      role: UserRole.tutor,
    ),
    sizes: sizes,
    verify: (tester, size) async {
      expect(find.text('초안 저장'), findsOneWidget);
      expect(find.text('게시하기'), findsOneWidget);
    },
  );

  testAtScreenSizes(
    'tutor quiz editor (new quiz)',
    () => buildSignedInApp(
      home: const TutorQuizEditorScreen(classId: 'class-1'),
      user: tutorUser,
      role: UserRole.tutor,
    ),
    sizes: sizes,
    verify: (tester, size) async {
      expect(find.text('문제 추가'), findsOneWidget);
      expect(find.text('게시하기'), findsOneWidget);
    },
  );

  for (final entry
      in <String, Widget Function()>{
        'onboarding': () => const OnboardingScreen(),
        'login': () => const LoginScreen(),
        'role selection': () => const RoleSelectionScreen(),
      }.entries) {
    testAtScreenSizes(
      'auth · ${entry.key}',
      () => buildSignedInApp(home: entry.value(), user: tuteeUser),
      sizes: sizes,
    );
  }
}
