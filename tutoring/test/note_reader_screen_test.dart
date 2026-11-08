import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';
import 'package:tutoring/features/notes/presentation/screens/note_reader_screen.dart';
import 'package:tutoring/features/notes/presentation/screens/notes_list_screen.dart';
import 'package:tutoring/features/notes/presentation/widgets/note_reader_footer.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

const _week2Title = 'Week 2 · 딕셔너리와 집합 자료형 정리';
const _week3Title = 'Week 3 · 딕셔너리와 집합 자료형 정리';

GoRouter _router({String noteId = 'note-2', String? targetBlockId}) => GoRouter(
  initialLocation: AppRoutes.noteReader(
    'class-1',
    noteId,
    targetBlockId: targetBlockId,
  ),
  routes: [
    GoRoute(
      path: AppRoutes.classNotesPath,
      builder:
          (_, state) =>
              NotesListScreen(classId: state.pathParameters['classId']!),
    ),
    GoRoute(
      path: AppRoutes.noteReaderPath,
      builder:
          (_, state) => NoteReaderScreen(
            classId: state.pathParameters['classId']!,
            noteId: state.pathParameters['noteId']!,
            targetBlockId: state.uri.queryParameters['targetBlockId'],
          ),
    ),
  ],
);

/// Reader on note-2 (week 2). note-1 is a draft, so note-3 is the only
/// neighbour; the single Quick Check is already answered.
FakeAnnotationRepository _annotations() => FakeAnnotationRepository([
  sampleMemo(
    id: 'memo-1',
    content: '[] 방식과 비교하기. get()은 KeyError가 발생하지 않음.',
    selectedText: 'KeyError 예외를 발생시키며',
  ),
]);

Widget _app({
  String noteId = 'note-2',
  String? targetBlockId,
  FakeAnnotationRepository? annotations,
}) => buildSignedInApp(
  router: _router(noteId: noteId, targetBlockId: targetBlockId),
  user: tuteeUser,
  blocks: sampleBlocks(),
  annotationRepository: annotations ?? _annotations(),
  attempts: [
    sampleAttempt(
      id: 'attempt-1',
      quizId: 'quiz-1',
      noteId: 'note-2',
      totalQuestions: 1,
      answers: [sampleAnswer('question-1')],
    ),
  ],
);

TextButton _footerButton(WidgetTester tester, Key key) =>
    tester.widget<TextButton>(
      find.descendant(of: find.byKey(key), matching: find.byType(TextButton)),
    );

/// Lets the replaced route load its note and blocks.
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
    'note reader shows meta, progress badge, memo card and footer',
    _app,
    sizes: TestScreenSizes.allWithNarrowTablet,
    verify: (tester, size) async {
      expect(find.text('파이썬 기초 스터디 · Week 02'), findsOneWidget);
      expect(find.text('학습 진행률 100%'), findsOneWidget);
      expect(find.text('다음 장: $_week3Title'), findsOneWidget);
      expect(find.text('내 메모'), findsOneWidget);
      expect(find.text('코드 복사'), findsOneWidget);
      // The always-on paragraph chips are gone; actions live in the
      // selection toolbar now.
      expect(find.text('문단 강조'), findsNothing);
      // note-1 is a draft, so there is nothing before note-2.
      expect(
        _footerButton(tester, NoteReaderFooter.previousKey).onPressed,
        isNull,
      );
      expect(
        _footerButton(tester, NoteReaderFooter.nextKey).onPressed,
        isNotNull,
      );
      // The "노트 목록" label only fits beside the title above mobile.
      expect(
        find.text('노트 목록'),
        size.width < 600 ? findsNothing : findsOneWidget,
      );
    },
  );

  testWidgets('next section opens the following published note', (
    tester,
  ) async {
    await tester.pumpAtSize(_app(), TestScreenSizes.tablet);
    expect(find.text(_week2Title), findsWidgets);

    // The footer sits below the fold on a long note.
    await tester.ensureVisible(find.byKey(NoteReaderFooter.nextKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NoteReaderFooter.nextKey));
    await _settle(tester);

    expect(find.text(_week3Title), findsWidgets);
    expect(find.text('마지막 노트예요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrow keys move between notes on desktop', (tester) async {
    await tester.pumpAtSize(_app(), TestScreenSizes.desktop);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(find.text(_week3Title), findsWidgets);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(find.text(_week2Title), findsWidgets);

    // Nothing before note-2: the key does nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(find.text(_week2Title), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile footer stacks the section links in two rows', (
    tester,
  ) async {
    await tester.pumpAtSize(_app(noteId: 'note-3'), TestScreenSizes.phone);

    final previous = tester.getRect(find.byKey(NoteReaderFooter.previousKey));
    final next = tester.getRect(find.byKey(NoteReaderFooter.nextKey));
    expect(previous.bottom, lessThanOrEqualTo(next.top));
    expect(previous.left, next.left);
    expect(previous.width, next.width);
    expect(previous.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mouse selection shows the toolbar and 강조 highlights the block', (
    tester,
  ) async {
    final repository = _annotations();
    await tester.pumpAtSize(
      _app(annotations: repository),
      TestScreenSizes.desktop,
    );
    expect(find.text('강조'), findsNothing);

    // Drag across the first paragraph with the mouse.
    final paragraph = find.byType(SelectableText).first;
    final start = tester.getTopLeft(paragraph) + const Offset(4, 12);
    final gesture = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(start + const Offset(160, 0));
    await gesture.up();
    await tester.pump();
    await tester.pump();

    expect(find.text('강조'), findsOneWidget);
    expect(find.text('메모'), findsOneWidget);
    expect(find.text('북마크'), findsOneWidget);
    expect(find.text('복사'), findsOneWidget);

    await tester.tap(find.text('강조'));
    await tester.pump();
    await tester.pump();

    final highlight = repository.annotations.where(
      (item) => item.type == AnnotationType.highlight,
    );
    expect(highlight.single.blockId, 'block-2');
    expect(find.text('강조'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('편집 rewrites the memo through the repository', (tester) async {
    final repository = _annotations();
    await tester.pumpAtSize(
      _app(annotations: repository),
      TestScreenSizes.desktop,
    );

    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();
    expect(find.text('내 메모 편집'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'get()은 기본값도 받을 수 있음');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(repository.annotations.single.content, 'get()은 기본값도 받을 수 있음');
    expect(tester.takeException(), isNull);
  });

  testWidgets('target block is still wrapped for auto scroll and emphasis', (
    tester,
  ) async {
    await tester.pumpAtSize(
      _app(targetBlockId: 'block-4'),
      TestScreenSizes.tablet,
    );

    expect(find.byKey(const ValueKey('related-block-4')), findsOneWidget);
    // Let the scroll animation and the emphasis timer finish.
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
