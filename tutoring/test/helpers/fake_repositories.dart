import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/core/theme/app_scroll_behavior.dart';
import 'package:tutoring/core/theme/app_theme.dart';
import 'package:tutoring/core/errors/app_exception.dart';
import 'package:tutoring/features/auth/domain/entities/auth_user.dart';
import 'package:tutoring/features/auth/domain/entities/user_profile.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/domain/repositories/auth_repository.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/domain/repositories/class_repository.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/domain/repositories/annotation_repository.dart';
import 'package:tutoring/features/notes/domain/repositories/note_repository.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';
import 'package:tutoring/features/notifications/domain/repositories/notification_repository.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tutoring/features/notes/domain/entities/quick_check.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_answer.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_attempt_repository.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_repository.dart';
import 'package:tutoring/features/quizzes/data/quiz_data_providers.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';
import 'package:tutoring/features/reviews/domain/repositories/review_repository.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_providers.dart';
import 'package:tutoring/features/classes/domain/entities/class_member.dart';

/// In-memory repositories for screen tests. Only the read paths the screens
/// use are implemented; anything else throws through [noSuchMethod].

final testDate = DateTime(2026, 11, 7, 9);

const tutorUser = AuthUser(uid: 'tutor-1', email: 'tutor@example.com');
const tuteeUser = AuthUser(uid: 'tutee-1', email: 'tutee@example.com');

UserProfile profileFor(AuthUser user, UserRole role) => UserProfile(
  uid: user.uid,
  email: user.email,
  name: role == UserRole.tutor ? '김튜터' : '이튜티',
  role: role,
  profileImageUrl: null,
  createdAt: testDate,
);

StudyClass sampleClass({String id = 'class-1', String title = '파이썬 기초 스터디'}) =>
    StudyClass(
      id: id,
      title: title,
      category: '프로그래밍',
      description: '매주 한 주제씩 차근차근 배워요. 질문은 언제든 환영이에요.',
      tutorId: tutorUser.uid,
      tutorName: '김튜터',
      inviteCode: 'ABCD1234',
      memberCount: 5,
      noteCount: 3,
      createdAt: testDate,
    );

StudyNote sampleNote({
  required String id,
  required int week,
  String classId = 'class-1',
  NoteStatus status = NoteStatus.published,
}) => StudyNote(
  id: id,
  classId: classId,
  title: 'Week $week · 딕셔너리와 집합 자료형 정리',
  summary: '키와 값의 쌍으로 데이터를 다루는 방법과 집합 연산을 정리했어요.',
  week: week,
  authorId: tutorUser.uid,
  status: status,
  createdAt: testDate,
  updatedAt: testDate,
  publishedAt: status == NoteStatus.published ? testDate : null,
);

/// Reader fixture: heading, two paragraphs with `code` spans, a code card
/// and one Quick Check pointing at `quiz-1 / question-1`.
List<NoteBlock> sampleBlocks({String noteId = 'note-2'}) => [
  NoteBlock(
    id: 'block-1',
    noteId: noteId,
    type: NoteBlockType.heading2,
    order: 0,
    content: 'Dictionary 만들기',
    language: null,
  ),
  NoteBlock(
    id: 'block-2',
    noteId: noteId,
    type: NoteBlockType.paragraph,
    order: 1,
    content:
        '중괄호 `{ }`를 사용하거나 내장 함수 `dict()`를 호출하여 생성합니다. '
        '키는 문자열이나 숫자처럼 불변(Immutable) 타입이어야 합니다.',
    language: null,
  ),
  NoteBlock(
    id: 'block-3',
    noteId: noteId,
    type: NoteBlockType.code,
    order: 2,
    content:
        '# 학생 이름(Key)과 점수(Value) 매핑\n'
        'scores = { "Tom": 90, "Jane": 85 }\n\n'
        'print(scores["Tom"])  # 90 출력',
    language: 'python',
  ),
  NoteBlock(
    id: 'block-4',
    noteId: noteId,
    type: NoteBlockType.paragraph,
    order: 3,
    content:
        '대괄호 `scores["Key"]` 구문은 딕셔너리에 대상 키가 존재하지 않을 경우 '
        'KeyError 예외를 발생시키며 프로그램을 중단시킵니다.',
    language: null,
  ),
  NoteBlock(
    id: 'block-5',
    noteId: noteId,
    type: NoteBlockType.quiz,
    order: 4,
    content: '',
    language: null,
    quizId: 'quiz-1',
    questionId: 'question-1',
  ),
];

QuizAnswer sampleAnswer(String questionId, {bool isCorrect = true}) =>
    QuizAnswer(
      questionId: questionId,
      selectedAnswer: isCorrect ? 1 : 0,
      isCorrect: isCorrect,
      answeredAt: testDate,
    );

/// A memo on [blockId] (or the whole note when null).
StudyAnnotation sampleMemo({
  required String id,
  required String content,
  String? blockId = 'block-4',
  String? selectedText,
  String noteId = 'note-2',
}) => StudyAnnotation(
  id: id,
  userId: tuteeUser.uid,
  classId: 'class-1',
  noteId: noteId,
  blockId: blockId,
  type: AnnotationType.memo,
  content: content,
  selectedText: selectedText,
  startOffset: null,
  endOffset: null,
  createdAt: testDate,
  updatedAt: testDate,
);

StudyQuiz sampleQuiz({
  required String id,
  String classId = 'class-1',
  QuizStatus status = QuizStatus.published,
}) => StudyQuiz(
  id: id,
  classId: classId,
  title: '딕셔너리 기본 개념 확인 퀴즈',
  description: '이번 주 노트를 읽고 핵심 개념을 점검해보세요.',
  createdBy: tutorUser.uid,
  status: status,
  questionCount: 4,
  createdAt: testDate,
  updatedAt: testDate,
  publishedAt: status == QuizStatus.published ? testDate : null,
  noteId: null,
);

/// Four-option question. Labels in backticks render as code, and the
/// explanation carries a fenced block so the parser is exercised.
QuizQuestion sampleQuestion({
  required String id,
  required int order,
  String quizId = 'quiz-1',
  String? relatedNoteId = 'note-3',
  String? relatedBlockId,
}) => QuizQuestion(
  id: id,
  quizId: quizId,
  type: QuizQuestionType.multipleChoice,
  prompt: '다음 중 존재하지 않는 key를 안전하게 조회할 수 있는 방법은?',
  options: const [
    '`data[key]`',
    '`data.get(key)`',
    '`data.fetch(key)`',
    '`data.search(key)`',
  ],
  correctOptionIndex: 1,
  explanation:
      '`data[key]` 방식은 존재하지 않는 key를 조회할 때 KeyError 예외를 '
      '발생시킵니다. 반면 `get()` 메서드는 키가 없을 때 오류 없이 안전하게 '
      'None이나 지정한 기본값을 반환합니다.\n'
      '```python\n# 기본값 0 지정 예시\nitem_count = data.get(\'apple\', 0)\n```',
  order: order,
  relatedNoteId: relatedNoteId,
  relatedBlockId: relatedBlockId,
);

List<QuizQuestion> sampleQuestions() => [
  for (var index = 0; index < 3; index++)
    sampleQuestion(id: 'question-${index + 1}', order: index),
];

QuizAttempt sampleAttempt({
  required String id,
  required String quizId,
  String userId = 'tutee-1',
  String classId = 'class-1',
  String? noteId,
  int totalQuestions = 4,
  List<QuizAnswer> answers = const [],
}) => QuizAttempt(
  id: id,
  userId: userId,
  classId: classId,
  quizId: quizId,
  noteId: noteId,
  startedAt: testDate,
  completedAt: testDate.add(const Duration(minutes: 3)),
  totalQuestions: totalQuestions,
  correctCount: 3,
  answers: answers,
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    required this.user,
    this.profile,
    List<String>? log,
    this.failReauth = false,
  }) : log = log ?? [];

  final AuthUser? user;
  final UserProfile? profile;

  /// Every write, in order, shared with the other fakes when a test passes
  /// the same list (`auth.updateName:…`, `auth.deleteAccount`, ...).
  final List<String> log;

  /// When true both reauthentication methods throw, like a wrong password.
  final bool failReauth;

  @override
  Stream<AuthUser?> watchAuthState() => Stream.value(user);

  @override
  Future<UserProfile?> getProfile(String uid) async => profile;

  @override
  Future<void> saveRole({required String uid, required UserRole role}) async {
    log.add('auth.saveRole:${role.name}');
  }

  @override
  Future<void> updateName({required String uid, required String name}) async {
    log.add('auth.updateName:$name');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    log.add('auth.resetMail:$email');
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    log.add('auth.reauth.password');
    if (failReauth) throw const AuthException('비밀번호가 맞지 않아요.');
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    log.add('auth.reauth.google');
    if (failReauth) throw const AuthException('Google 확인이 취소됐어요.');
  }

  @override
  Future<void> deleteProfile(String uid) async {
    log.add('auth.deleteProfile');
  }

  @override
  Future<void> deleteAccount() async {
    log.add('auth.deleteAccount');
  }

  @override
  Future<void> signOut() async {
    log.add('auth.signOut');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

ClassMember sampleMember({
  required String uid,
  required String name,
  UserRole role = UserRole.tutee,
}) => ClassMember(uid: uid, role: role, name: name, joinedAt: testDate);

/// Tutor plus two students.
List<ClassMember> sampleMembers() => [
  sampleMember(uid: tutorUser.uid, name: '김튜터', role: UserRole.tutor),
  sampleMember(uid: tuteeUser.uid, name: '이튜티'),
  sampleMember(uid: 'tutee-2', name: '박학생'),
];

class FakeClassRepository implements ClassRepository {
  FakeClassRepository(
    this.classes, {
    List<ClassMember>? members,
    List<String>? log,
  }) : members = members ?? sampleMembers(),
       log = log ?? [];

  final List<StudyClass> classes;
  final List<ClassMember> members;
  final List<String> log;

  @override
  Future<List<StudyClass>> getMyClasses(String userId) async => classes;

  @override
  Future<bool> ownsAnyClass(String userId) async =>
      classes.any((studyClass) => studyClass.tutorId == userId);

  @override
  Future<void> leaveClass({
    required String userId,
    required String classId,
  }) async {
    log.add('classes.leave:$classId');
  }

  @override
  Future<void> deleteClass({
    required String userId,
    required String classId,
  }) async {
    classes.removeWhere((studyClass) => studyClass.id == classId);
    log.add('classes.delete:$classId');
  }

  @override
  Future<StudyClass> joinClass({
    required String userId,
    required String userName,
    required String inviteCode,
  }) async {
    final match = classes.where((c) => c.inviteCode == inviteCode);
    if (match.isEmpty) throw StateError('invite-code-not-found');
    log.add('classes.join:${match.first.id}');
    return match.first;
  }

  @override
  Future<void> updateMemberName({
    required String userId,
    required String name,
  }) async {
    log.add('classes.memberName:$name');
  }

  @override
  Stream<List<ClassMember>> watchMembers(String classId) =>
      Stream.value(members);

  @override
  Stream<List<StudyClass>> watchMyClasses(String userId) =>
      Stream.value(classes);

  @override
  Stream<StudyClass?> watchClass(String classId) => Stream.value(
    classes.cast<StudyClass?>().firstWhere(
      (item) => item!.id == classId,
      orElse: () => null,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository(this.notes, {this.blocks = const [], List<String>? log})
    : log = log ?? [];

  final List<StudyNote> notes;
  final List<NoteBlock> blocks;
  final List<String> log;

  @override
  Stream<List<StudyNote>> watchPublishedNotes(String classId) =>
      Stream.value(publishedNotes(notes));

  @override
  Stream<List<StudyNote>> watchAllNotes(String classId) => Stream.value(notes);

  @override
  Future<StudyNote?> getNote(String classId, String noteId) async => notes
      .cast<StudyNote?>()
      .firstWhere((note) => note!.id == noteId, orElse: () => null);

  @override
  Future<StudyNote?> getNoteForAuthor(String classId, String noteId) =>
      getNote(classId, noteId);

  @override
  Future<void> setNoteStatus({
    required String classId,
    required String noteId,
    required NoteStatus status,
  }) async {
    log.add('notes.status:$noteId:${status.name}');
  }

  @override
  Future<QuickCheck?> getQuickCheck({
    required String classId,
    required String quizId,
    required String questionId,
  }) async => null;

  List<NoteBlock> _blocksOf(String noteId) =>
      blocks.where((block) => block.noteId == noteId).toList(growable: false);

  @override
  Future<List<NoteBlock>> getNoteBlocks(String classId, String noteId) async =>
      _blocksOf(noteId);

  @override
  Stream<List<NoteBlock>> watchNoteBlocks(String classId, String noteId) =>
      Stream.value(_blocksOf(noteId));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// In-memory annotations. Writes land in [annotations] so a test can assert
/// them; the stream emits once, so the screen does not refresh afterwards.
class FakeAnnotationRepository implements AnnotationRepository {
  FakeAnnotationRepository([
    List<StudyAnnotation> seed = const [],
    List<String>? log,
  ]) : annotations = [...seed],
       log = log ?? [];

  final List<StudyAnnotation> annotations;
  final List<String> log;
  var _nextId = 0;

  @override
  Future<void> deleteAllForUser(String userId) async {
    annotations.removeWhere((item) => item.userId == userId);
    log.add('annotations.deleteAll');
  }

  @override
  Stream<List<StudyAnnotation>> watchAnnotations({
    required String userId,
    required String noteId,
  }) => Stream.value(
    annotations
        .where((item) => item.userId == userId && item.noteId == noteId)
        .toList(growable: false),
  );

  @override
  Future<StudyAnnotation> createAnnotation({
    required String userId,
    required String classId,
    required String noteId,
    required String? blockId,
    required AnnotationType type,
    required String content,
    String? selectedText,
    int? startOffset,
    int? endOffset,
  }) async {
    final annotation = StudyAnnotation(
      id: 'annotation-${_nextId++}',
      userId: userId,
      classId: classId,
      noteId: noteId,
      blockId: blockId,
      type: type,
      content: content,
      selectedText: selectedText,
      startOffset: startOffset,
      endOffset: endOffset,
      createdAt: testDate,
      updatedAt: testDate,
    );
    annotations.add(annotation);
    return annotation;
  }

  @override
  Future<void> updateAnnotation(StudyAnnotation annotation) async {
    final index = annotations.indexWhere((item) => item.id == annotation.id);
    if (index >= 0) annotations[index] = annotation;
  }

  @override
  Future<void> saveAnnotation(StudyAnnotation annotation) async {
    annotations.removeWhere((item) => item.id == annotation.id);
    annotations.add(annotation);
  }

  @override
  Future<void> deleteAnnotation({
    required String userId,
    required String annotationId,
  }) async {
    annotations.removeWhere((item) => item.id == annotationId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeQuizRepository implements QuizRepository {
  FakeQuizRepository(
    this.quizzes, {
    this.questions = const [],
    List<String>? log,
  }) : log = log ?? [];

  final List<StudyQuiz> quizzes;
  final List<QuizQuestion> questions;
  final List<String> log;

  @override
  Future<void> setQuizStatus({
    required String classId,
    required String quizId,
    required QuizStatus status,
  }) async {
    log.add('quizzes.status:$quizId:${status.name}');
  }

  @override
  Stream<List<StudyQuiz>> watchAllQuizzes(String classId) =>
      Stream.value(quizzes);

  @override
  Stream<List<StudyQuiz>> watchPublishedQuizzes(String classId) => Stream.value(
    quizzes
        .where((quiz) => quiz.status == QuizStatus.published)
        .toList(growable: false),
  );

  @override
  Future<StudyQuiz?> getQuiz(String classId, String quizId) async => quizzes
      .cast<StudyQuiz?>()
      .firstWhere((quiz) => quiz!.id == quizId, orElse: () => null);

  @override
  Future<List<QuizQuestion>> getQuestions(
    String classId,
    String quizId,
  ) async => questions.where((q) => q.quizId == quizId).toList(growable: false);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeQuizAttemptRepository implements QuizAttemptRepository {
  FakeQuizAttemptRepository(this.attempts, {List<String>? log})
    : log = log ?? [];

  final List<QuizAttempt> attempts;
  final List<String> log;

  @override
  Future<void> deleteAllForUser(String userId) async {
    log.add('attempts.deleteAll');
  }

  @override
  Stream<List<QuizAttempt>> watchAttempts(String userId) => Stream.value(
    attempts.where((a) => a.userId == userId).toList(growable: false),
  );

  @override
  Stream<List<QuizAttempt>> watchClassAttempts(String classId) => Stream.value(
    attempts.where((a) => a.classId == classId).toList(growable: false),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

ReviewItem sampleReview({
  required String questionId,
  required String topic,
  required String prompt,
  ReviewStatus status = ReviewStatus.needsReview,
  int wrongCount = 1,
  DateTime? updatedAt,
  String userId = 'tutee-1',
  String classId = 'class-1',
  String quizId = 'quiz-1',
  String? noteId = 'note-3',
}) => ReviewItem(
  id: ReviewItem.idFor(
    classId: classId,
    quizId: quizId,
    questionId: questionId,
  ),
  userId: userId,
  classId: classId,
  quizId: quizId,
  questionId: questionId,
  noteId: noteId,
  blockId: null,
  topic: topic,
  prompt: prompt,
  lastSelectedOptionIndex: 0,
  status: status,
  wrongCount: wrongCount,
  createdAt: testDate,
  updatedAt: updatedAt ?? testDate,
);

/// Three items as in the Figma frame: two pending, one reviewed.
List<ReviewItem> sampleReviews() => [
  sampleReview(
    questionId: 'question-1',
    topic: 'Dictionary',
    prompt: '존재하지 않는 key 조회하기',
    updatedAt: testDate.add(const Duration(hours: 2)),
  ),
  sampleReview(
    questionId: 'question-2',
    topic: 'List & Tuple',
    prompt: 'Tuple의 특징 (불변성)',
    updatedAt: testDate.add(const Duration(hours: 1)),
  ),
  sampleReview(
    questionId: 'question-3',
    topic: '반복문',
    prompt: 'for문의 기본 구조 및 range()',
    status: ReviewStatus.reviewed,
    updatedAt: testDate.add(const Duration(hours: 3)),
  ),
];

/// In-memory review list applying the same upsert rule as Firestore.
class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository([List<ReviewItem>? seed, List<String>? log])
    : items = {for (final item in seed ?? const <ReviewItem>[]) item.id: item},
      log = log ?? [];

  final Map<String, ReviewItem> items;
  final List<String> log;

  @override
  Future<void> deleteAllForUser(String userId) async {
    items.removeWhere((_, item) => item.userId == userId);
    log.add('reviews.deleteAll');
  }

  /// Injectable clock so tests can assert timestamps.
  DateTime Function() clock = DateTime.now;

  /// When true every write throws, like undeployed security rules.
  bool failWrites = false;

  @override
  Stream<List<ReviewItem>> watchReviews({
    required String userId,
    required String classId,
  }) => Stream.value(
    items.values
        .where((item) => item.userId == userId && item.classId == classId)
        .toList(growable: true)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );

  @override
  Stream<List<ReviewItem>> watchAllReviews({required String userId}) =>
      Stream.value(
        items.values
            .where((item) => item.userId == userId)
            .toList(growable: true)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      );

  @override
  Future<ReviewItem?> getReview({
    required String userId,
    required String reviewId,
  }) async => items[reviewId];

  @override
  Future<ReviewItem> recordWrongAnswer({
    required String userId,
    required String classId,
    required String quizId,
    required String questionId,
    required String? noteId,
    required String? blockId,
    required String topic,
    required String prompt,
    required int selectedOptionIndex,
  }) async {
    if (failWrites) throw StateError('permission-denied');
    final id = ReviewItem.idFor(
      classId: classId,
      quizId: quizId,
      questionId: questionId,
    );
    final next = ReviewItem.recordWrongAnswer(
      existing: items[id],
      userId: userId,
      classId: classId,
      quizId: quizId,
      questionId: questionId,
      noteId: noteId,
      blockId: blockId,
      topic: topic,
      prompt: prompt,
      selectedOptionIndex: selectedOptionIndex,
      now: clock(),
    );
    items[id] = next;
    return next;
  }

  @override
  Future<void> markReviewed({
    required String userId,
    required String reviewId,
  }) async {
    final item = items[reviewId];
    if (item == null) return;
    items[reviewId] = item.copyWith(
      status: ReviewStatus.reviewed,
      updatedAt: clock(),
    );
  }

  @override
  Future<void> deleteReview({
    required String userId,
    required String reviewId,
  }) async {
    if (failWrites) throw StateError('permission-denied');
    items.remove(reviewId);
  }
}

AppNotification sampleNotification({
  required String id,
  required NotificationType type,
  String classId = 'class-1',
  String actorId = 'tutor-1',
  String? targetId = 'note-3',
  String title = '새 노트가 게시됐어요',
  String body = 'Week 3 · 딕셔너리와 집합 자료형 정리',
  DateTime? createdAt,
}) => AppNotification(
  id: id,
  classId: classId,
  type: type,
  title: title,
  body: body,
  actorId: actorId,
  actorName: '김튜터',
  targetId: targetId,
  createdAt: createdAt ?? testDate,
);

/// In-memory notifications; writes land in [items] and [log].
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({
    List<AppNotification> items = const [],
    this.seenAt,
    List<String>? log,
    this.failWrites = false,
  }) : items = [...items],
       log = log ?? [];

  final List<AppNotification> items;
  DateTime? seenAt;
  final List<String> log;
  final bool failWrites;

  @override
  Stream<List<AppNotification>> watchClassNotifications(String classId) =>
      Stream.value(
        items.where((item) => item.classId == classId).toList(growable: false),
      );

  @override
  Future<void> create(AppNotification notification) async {
    if (failWrites) throw StateError('permission-denied');
    items.add(notification);
    log.add(
      'notifications.create:${notification.type.name}:${notification.classId}',
    );
  }

  @override
  Stream<DateTime?> watchSeenAt(String userId) => Stream.value(seenAt);

  @override
  Future<void> markSeen({required String userId, required DateTime at}) async {
    seenAt = at;
    log.add('notifications.seen');
  }
}

/// Provider overrides that replace every repository with a fake; the shape
/// behind [buildSignedInApp], exposed for tests that need the real router.
List<Override> signedInOverrides({
  required AuthUser user,
  UserRole role = UserRole.tutee,
  UserProfile? profile,
  List<StudyClass>? classes,
  List<ClassMember>? members,
  List<StudyNote>? notes,
  List<NoteBlock>? blocks,
  List<StudyAnnotation>? annotations,
  FakeAnnotationRepository? annotationRepository,
  List<StudyQuiz>? quizzes,
  List<QuizQuestion>? questions,
  List<QuizAttempt>? attempts,
  FakeReviewRepository? reviews,
  List<AppNotification>? notifications,
  FakeNotificationRepository? notificationRepository,
  List<Override> extraOverrides = const [],
  List<String>? log,
  bool failReauth = false,
}) => [
  ...extraOverrides,
  notificationRepositoryProvider.overrideWithValue(
    notificationRepository ??
        FakeNotificationRepository(items: notifications ?? const [], log: log),
  ),
  authRepositoryProvider.overrideWithValue(
    FakeAuthRepository(
      user: user,
      profile: profile ?? profileFor(user, role),
      log: log,
      failReauth: failReauth,
    ),
  ),
  classRepositoryProvider.overrideWithValue(
    FakeClassRepository(classes ?? [sampleClass()], members: members, log: log),
  ),
  noteRepositoryProvider.overrideWithValue(
    FakeNoteRepository(
      notes ??
          [
            sampleNote(id: 'note-3', week: 3),
            sampleNote(id: 'note-2', week: 2),
            sampleNote(id: 'note-1', week: 1, status: NoteStatus.draft),
          ],
      blocks: blocks ?? const [],
      log: log,
    ),
  ),
  annotationRepositoryProvider.overrideWithValue(
    annotationRepository ??
        FakeAnnotationRepository(annotations ?? const [], log),
  ),
  quizRepositoryProvider.overrideWithValue(
    FakeQuizRepository(
      quizzes ??
          [
            sampleQuiz(id: 'quiz-1'),
            sampleQuiz(id: 'quiz-2', status: QuizStatus.draft),
          ],
      questions: questions ?? sampleQuestions(),
      log: log,
    ),
  ),
  reviewRepositoryProvider.overrideWithValue(
    reviews ?? FakeReviewRepository(null, log),
  ),
  quizAttemptRepositoryProvider.overrideWithValue(
    FakeQuizAttemptRepository(
      attempts ?? [sampleAttempt(id: 'attempt-1', quizId: 'quiz-1')],
      log: log,
    ),
  ),
];

/// A signed-in app shell with every repository replaced by a fake. Pass
/// [home] for one screen, or [router] when the test navigates between routes.
Widget buildSignedInApp({
  Widget? home,
  GoRouter? router,
  required AuthUser user,
  UserRole role = UserRole.tutee,
  UserProfile? profile,
  List<StudyClass>? classes,
  List<ClassMember>? members,
  List<StudyNote>? notes,
  List<NoteBlock>? blocks,
  List<StudyAnnotation>? annotations,
  FakeAnnotationRepository? annotationRepository,
  List<StudyQuiz>? quizzes,
  List<QuizQuestion>? questions,
  List<QuizAttempt>? attempts,
  FakeReviewRepository? reviews,
  List<AppNotification>? notifications,
  FakeNotificationRepository? notificationRepository,
  List<Override> extraOverrides = const [],
  List<String>? log,
  bool failReauth = false,
}) => ProviderScope(
  overrides: signedInOverrides(
    user: user,
    role: role,
    profile: profile,
    classes: classes,
    members: members,
    notes: notes,
    blocks: blocks,
    annotations: annotations,
    annotationRepository: annotationRepository,
    quizzes: quizzes,
    questions: questions,
    attempts: attempts,
    reviews: reviews,
    notifications: notifications,
    notificationRepository: notificationRepository,
    extraOverrides: extraOverrides,
    log: log,
    failReauth: failReauth,
  ),
  child:
      router != null
          ? MaterialApp.router(
            theme: AppTheme.light,
            scrollBehavior: const AppScrollBehavior(),
            routerConfig: router,
          )
          : MaterialApp(
            theme: AppTheme.light,
            scrollBehavior: const AppScrollBehavior(),
            home: home,
          ),
);
