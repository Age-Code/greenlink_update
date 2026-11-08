# StudyTogether architecture

## Implemented scope

The implemented flow follows Figma Page 2 (1024 tablet frames) on mobile,
tablet and desktop:

1. Onboarding, email and Google authentication (Apple client flow ready for
   provider setup), Tutor/Tutee role selection persisted to Firestore
2. Home: greeting from the profile, a live "오늘의 요약" card (student: quizzes
   solved today and pending reviews; tutor: draft notes and this week's
   publishes), class shelf with the latest published note per class and a
   class-info sheet behind ⋯, class/note search, the 01_Home_Empty state, and
   홈·마이 tabs below desktop
3. Firestore-backed class list, create, and invite-code join flows
4. Student class home: hero with the latest note, 학습 달성도 from finished
   quizzes, task cards with live counts; class menu as a drawer below desktop
   and a toggleable sidebar on desktop; shared class-info sheet
5. Tutor class home: continue-draft card, metric cards, recent notes and a
   per-student 학습 현황 table built from the class's quiz attempts
6. Real-time published notes list and the block-based note reader with
   클래스 · Week · 학습 진행률 (Quick Check completion), a selection toolbar
   (강조 · 메모 · 북마크 · 복사), memo cards with edit, code copy, previous /
   next note footer and ←/→ keys
7. User-owned memo, paragraph highlight, bookmark, free-hand ink and text
   annotations; PDF export with or without annotations
8. Tutor note management and the local-state Note Editor with batched
   Note/Block/Quick Check writes, a tiled block picker and a pinned action bar
9. Tutor Quiz list and the local-state multi-question Quiz Editor with a
   pinned action bar
10. Draft/published Quiz lifecycle and Note-to-Quiz question references
11. Tutee Quiz sessions with immediate client-side grading, keyboard
    shortcuts, and one immutable `QuizAttempt` per run
12. Interactive Note Quick Checks that store their own attempt
13. Reviews: every wrong answer upserts a user-owned review item; class review
    list with filters, review detail with the chosen vs. correct answer and the
    related note, and a retry session that marks items reviewed
14. Responsive frame for every signed-in screen (`AppResponsiveScaffold`,
    `showAppSheet`, `AdaptiveAuthFrame`), see "Responsive layout" below
15. Firestore security rules with emulator tests for the user-owned
    collections and class members
17. In-app notifications: tutor publishes and student joins are written to
    `classes/{classId}/notifications`; the home bell shows the unread count
    and opens the list (see "Notifications" below)
16. 마이 (`/my`): profile card, learning summary, settings (rename with the
    class member-name snapshot, tutor ↔ tutee role change, password reset
    mail for email accounts), draft privacy / terms / my-data pages, logout
    and real account deletion (see "Account deletion" below)

The home watches the signed-in user's `classMemberships` stream through the domain
`ClassRepository` contract. Creating a class and joining by invite code update the
class, member, and user membership documents atomically.

Still extension points: tutor member management and student detail, class
settings and leaving a single class from its own screen, a richer quiz result
screen, push notifications (FCM needs Cloud Functions), study discovery, the
peer-activity feed, and any AI assistant (which must go through a server,
never an API key in the app).

## Dependency direction

```text
presentation -> domain <- data
```

- `presentation` owns screens, Riverpod controllers, UI state, and navigation.
- `domain` owns Firebase-independent entities and repository contracts.
- `data` owns Firebase SDK calls, DTO mapping, and repository implementations.
- `core` contains app-wide routing, theme tokens, Firebase paths, errors, and widgets.

Firebase types must not cross the data layer. Firestore `Timestamp` values are
converted to `DateTime` by DTOs before reaching domain or presentation code.

## Authentication and profile state

Authentication identity and app profile are deliberately separate:

- Firebase Auth: `uid`, `email`, authentication providers
- `users/{uid}`: `name`, `role`, `profileImageUrl`, `createdAt`

`UserRole` is the single serialization authority for `tutor` and `tutee`.
Screens do not compare role strings. Authentication succeeds independently of profile
loading. Role selection creates the user's Firestore profile when needed, persists the
role, and mirrors it in Riverpod for immediate UI use.

## Firestore query design

The proposed nested collections fit these reads well:

- class notes: `classes/{classId}/notes`
- quiz questions: `classes/{classId}/quizzes/{quizId}/questions`
- personal annotations: `users/{uid}/annotations`
- personal reviews: `users/{uid}/reviews`

“My classes” uses a user-scoped membership index. Querying every
`classes/{classId}/members/{uid}` path is not efficient from the client, so class
create/join writes both:

```text
classes/{classId}/members/{uid}
users/{uid}/classMemberships/{classId}
```

The user-scoped membership document contains `classId`, `role`, `joinedAt`, and a
small display snapshot. Creation uses a batch and joining uses a transaction so the
class count and membership records remain consistent.

Tutor notes and tutee-owned annotations remain separate documents. Personal edits
must never update the tutor's source note.

Published note reads use:

```text
classes/{classId}/notes             status == published, week descending
classes/{classId}/notes/{noteId}/blocks  order ascending
users/{uid}/annotations             noteId == selected note
```

`NoteStatus`, `NoteBlockType`, and `AnnotationType` are the serialization
authorities; presentation code does not compare stored strings. Bookmark records
reuse `AnnotationType.bookmark` because their lifetime, owner, and note lookup are
identical to memo and highlight records. Paragraph highlighting stores both the
full selected text and offsets so a future selection UI does not require a schema
migration.

The note editor keeps metadata, blocks, order, dirty state, and Quick Check drafts in
a Riverpod `StateNotifier`. Firestore is written only when Save/Publish is chosen.
An inline Quick Check is created with the note, while a reference to an existing
quiz is never copied, overwritten, or deleted by note persistence. A quiz block
stores only `quizId` and `questionId`; the latest question body lives under:

```text
classes/{classId}/quizzes/{quizId}/questions/{questionId}
```

The Quiz Editor follows the same boundary: `QuizEditorController` owns unsaved
local state, `QuizRepository` is the domain contract, and
`QuizRemoteDataSource` writes a quiz plus all of its questions atomically with a
Firestore `WriteBatch`. Quiz and question collections are:

```text
classes/{classId}/quizzes/{quizId}
classes/{classId}/quizzes/{quizId}/questions/{questionId}
```

`QuizStatus` and `QuizQuestionType` are the serialization authorities. Quiz
questions currently support `multipleChoice` only; a published quiz requires at
least one complete question with four choices, one answer, and an explanation.

Tutee answers remain in `QuizSessionController` local state while a quiz is in
progress. The controller grades against `QuizQuestion.correctOptionIndex` and
writes one immutable attempt only after the final answer. A one-question Note
Quick Check uses the same controller and question entity, but stores its attempt
immediately after checking the answer. Attempt history is user-owned:

```text
users/{uid}/quizAttempts/{attemptId}
```

`QuizAttemptRepository` is separate from `QuizRepository`: the former owns a
learner's repeated results, while the latter owns tutor-authored source content.
Presentation code does not import Firestore and every retry creates a new attempt
document instead of overwriting an earlier result.

Publishing only changes the shared note's `NoteStatus`. The existing tutee
`watchPublishedNotes` stream therefore adds and removes the note automatically.
Tutor edits and deletes never write to `users/{uid}/annotations`.

## Reviews (오답 노트)

A wrong answer in a quiz session or an inline Quick Check upserts one review
item per question, owned by the learner:

```text
users/{uid}/reviews/{classId_quizId_questionId}
```

The deterministic id makes the write idempotent. `ReviewItem.recordWrongAnswer`
holds the upsert rule: a first miss creates the item with `wrongCount 1` and
`status needsReview`; a repeat miss increments `wrongCount` and resets the status
to `needsReview`; answering correctly in a retry session marks it `reviewed`.
`ReviewStatus` is the serialization authority. The item also snapshots `topic`,
`prompt`, `noteId` and `blockId` so the list renders even when the tutor later
edits or deletes the question; the detail screen reads the live question and
shows a notice when it is gone.

Retries reuse the quiz machinery instead of copying it: `QuizSessionController`
takes a `QuizSessionSource` (`QuizRunSource` for quizzes and Quick Checks,
`ReviewRunSource` for retries). A retry never writes a `QuizAttempt`; it only
updates the review items. Rules allow a learner to read and write their own
reviews, require the composite id, `wrongCount >= 1` on create and a
non-decreasing `wrongCount` on update, and deny tutors any read.

## Notifications

Notifications are in-app only and need no server. The client that causes an
event writes one document to the class feed:

```text
classes/{classId}/notifications/{id}   type, title, body, actorId, actorName,
                                        targetId, createdAt
```

`NotificationWriter` (features/notifications/presentation/controllers) is
called after a tutor publishes a note or quiz (list controllers and both
editors, only on a draft → published transition) and after a student joins a
class. Writes are best effort: a failed notification never fails the action.
Readers merge the feeds of their classes (`myNotificationsProvider`) and drop
items they caused themselves; publishes go to students, joins to the tutor
(`visibleNotifications`). "Seen" is one timestamp on the profile,
`users/{uid}.notificationsSeenAt`, written when the bell sheet opens; the badge
counts items newer than it. Rules let members read, tutors create publish
items, members create a `memberJoined` item about themselves, and nobody
update. Push delivery (FCM + Cloud Functions) is a later slice.

## Account deletion

`DeleteAccountUseCase` (features/profile/domain) is the one operation that
spans every repository, which is why it is a use case rather than a controller
method. The order is deliberate: a tutor who still owns classes is refused
before anything changes (`ClassRepository.ownsAnyClass`); the identity is
confirmed next (`AuthRepository.reauthenticateWithPassword` or
`reauthenticateWithGoogle`) so the final Firebase Auth deletion cannot fail on
`requires-recent-login` after data is gone; then every membership is left
(`leaveClass`: member document, membership document and `memberCount - 1` in
one transaction), annotations, reviews and quiz attempts are deleted in
batches (`core/firebase/firestore_batch.dart`), the profile document is removed
and the Auth user last. Rules allow owners to delete their profile and
attempts and let a current member lower `memberCount` by one; the emulator
tests cover those cases. `AuthUser.providerIds` tells the 마이 screen whether
to ask for a password or open the Google popup.

## Responsive layout

`AppBreakpoints` is the only source of width classes: mobile `< 600`, tablet
`600–1199`, desktop `≥ 1200` (`context.screenType`). Figma Page 2 frames are the
1024 tablet layout and every size derives from them:

- `AppResponsiveScaffold` + `AppPageBody` frame every signed-in screen: a
  centered column of at most 780 (`AppLayout.contentMaxWidth`), 720 for the
  note reader, 1024 for the home dashboard; side padding 20 on mobile, 24
  otherwise; an optional `bottomBar` pinned under the column.
- Class screens pass a `menu`: a drawer below desktop, a 280px sidebar on
  desktop that starts closed and is toggled by the hamburger
  (`sidebarOpenProvider`). The reader, editors and quiz solving are focus mode
  without a menu.
- `showAppSheet` renders modals as a full-width bottom sheet on mobile, a
  sheet inset 64 on tablet and a centered dialog on desktop (class add, class
  info, block picker, home search).
- `AdaptiveAuthFrame` keeps the mobile auth screens in a centered 430 × ≤844
  card on wider windows.
- Grids follow 1 / 2 / 3 columns (home class shelf); two-column rows stack on
  mobile; touch targets stay ≥ 48px.

`test/responsive_screens_test.dart` pumps every screen at 390×844, 600×1024,
1024×1366 and 1440×900 and fails on overflow; `test/helpers/` holds the fake
repositories and size helpers.

## Firestore rules tests

`firestore_rules_test/` is a small Node project using
`@firebase/rules-unit-testing` against the Firestore emulator. It seeds a class,
its members and a published and a draft quiz with rules disabled, then checks
allow / deny cases for `users/{uid}/classMemberships`,
`classes/{classId}/members`, `users/{uid}/quizAttempts` (including the tutor
collection-group query) and `users/{uid}/reviews`.

```bash
cd firestore_rules_test
npm install
npm run test:emulator   # firebase emulators:exec --only firestore --project demo-studytogether "npm test"
```

## Next implementation slices

Recommended order:

1. Tutor member list and student detail (names from `members`, per-student
   attempts, encourage / feedback actions once specified)
2. Class info edits and leaving a single class from its screen (reuse
   `ClassRepository.leaveClass`), tutor class settings and class deletion
3. Quiz result screen rebuilt from the stored `QuizAttempt`
   (`/classes/:classId/quizzes/:quizId/attempts/:attemptId`)
4. Home leftovers: study discovery, peer activity feed; push notifications
   (FCM + Cloud Functions, Blaze plan) on top of the in-app feed
5. Notes list reading badges and per-note progress, tutor notes search and
   status filters
6. AI assistant in the reader, server-side only

Introduce UseCase classes only for operations with rules spanning repositories,
such as joining a class by code or submitting a quiz.
