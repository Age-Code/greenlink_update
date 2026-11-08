# StudyTogether

A maintainable Flutter + Firebase learning app based on the StudyTogether Figma
design. The current implementation covers onboarding, authentication,
Tutor/Tutee role selection, the responsive mobile/web home, real Firestore class
creation/joining, and the student class-home experience.
The published-note flow is also connected end to end: class notes, a block-based
reader, and private memo/highlight/bookmark annotations.
Tutors can now create and edit the same notes, arrange document blocks, author a
multiple-choice Quick Check, save drafts, publish/unpublish, and delete notes.
Tutor Quiz management is also Firestore-backed: tutors can create multi-question
multiple-choice quizzes, reorder questions, save drafts, publish/unpublish, edit,
and delete them. Note quiz blocks can link to any question in a published quiz.
Tutees can solve published quizzes with immediate feedback, store independent
attempts for every run, and answer the same questions inline from Note Quick
Check blocks. Wrong answers feed a personal review list (오답 노트) with detail
and retry screens, and every signed-in screen follows one responsive frame for
mobile, tablet and desktop.

## Stack

- Flutter 3.29.3 / Dart 3.7.2
- Firebase Authentication and Cloud Firestore
- Riverpod
- go_router
- Feature-first, lightly layered architecture

## Run

```bash
flutter pub get
flutter run -d chrome
```

Firestore rules tests run against the emulator (needs Node and Java):

```bash
cd firestore_rules_test
npm install
npm run test:emulator
```

Firebase Authentication and the Seoul-region Firestore database are connected to
`tugether-a3dea`. Class creation and invite-code joining use the signed-in user's
real Firestore data; no preview classes are inserted automatically. Email/password
and Google sign-in are enabled for web registration and login.

See [ARCHITECTURE.md](ARCHITECTURE.md) for boundaries and the recommended next
slices. See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for provider and Firestore setup.
For manual development fixtures, [tool/seed_notes.md](tool/seed_notes.md) remains
available, but normal note creation now happens in the Tutor Note Editor.


## 구현 상황

### 계정 및 인증
- 이메일 회원가입·로그인
- Google 로그인
- Tutor / Tutee 역할 선택
- Firebase 프로젝트 tugether-a3dea 연결
- Flutter Web 로그인 지원
  
### 클래스
- Tutor 클래스 생성
- 클래스 참여 코드 생성
- Tutee가 코드로 클래스 참여
- Tutor/Tutee별 클래스 화면 분리
- Tutor 화면에서 참여 코드 복사·외부 공유
- Tutor 클래스 대시보드
- 학생별 퀴즈 완료 횟수, 최근 학습 시간, 정답 현황 표시

### Tutor 노트
- 노트 생성·수정·삭제
- Draft 저장, 게시, 게시 취소
- Notion 형태의 자유로운 블록 편집
- 제목 1/2/3, 본문, 코드, 콜아웃, 인용, 이미지, Quick Check 블록
- 블록 추가·삭제·순서 변경
- 기존 블록 수정 시 Block ID 유지
- 노트 PDF 내보내기
  
### Tutee 노트 Reader
- 게시된 노트 목록 및 읽기
- Memo
- 문단 Highlight
- Bookmark
- 자유 필기 및 형광펜
- 텍스트 주석
- 필기 실행 취소·다시 실행
- 기존 노트 콘텐츠와 개인 Annotation 분리 저장
  
### Tutor Quiz
- 퀴즈 목록
- 새 퀴즈 생성·수정·삭제
- Draft 저장
- 게시·게시 취소
- 객관식 문제 여러 개 작성
- 선택지 4개, 정답, 해설 Validation
- 문제 순서 변경
- Local State에서 편집 후 한 번에 Firestore 저장
- 문제별 관련 노트 및 관련 블록 지정
- 초안·게시 노트 모두 선택 가능
- 제목·본문·코드·콜아웃 블록을 관련 학습 위치로 연결

### Tutee Quiz
- 게시된 퀴즈 목록
- 아직 안 푼 퀴즈와 완료 퀴즈 구분
- 문제별 답 선택
- 즉시 정답·오답 Feedback
- 해설 표시
- 다음 문제 이동
- 완료 화면
- 여러 번 다시 풀기
- 각 풀이를 별도 QuizAttempt로 저장
- 최근 Attempt를 기준으로 완료 상태 표시
  
### Quick Check
- Note 안의 Quiz Block이 실제 Quiz Question 참조
- 별도 문제 복사 없이 quizId, questionId만 저장
- Tutor Quiz의 최신 문제 내용 사용
- Note Reader에서 직접 풀이
- 정답 확인·Feedback·Attempt 저장
  
### 오답 관련 노트 이동
- 오답이고 relatedNoteId가 있을 때만 관련 노트 보기 표시
- 기존 Note Reader로 이동
- targetBlockId를 query parameter로 전달
- 렌더링 완료 후 관련 블록으로 자동 스크롤
- 관련 블록을 약 1.6초간 Soft Coral로 강조
- relatedBlockId가 없거나 블록이 삭제된 경우 노트 상단으로 이동
- 노트가 삭제된 경우 기존 안내 화면 표시
- Quick Check에서도 동일하게 동작
- 이동 후에도 Memo·Highlight·Bookmark·필기 유지
  
### 복습 (오답 노트)
- 퀴즈·Quick Check 오답 시 `users/{uid}/reviews/{classId_quizId_questionId}`에 자동 upsert
- 같은 문제를 다시 틀리면 wrongCount 증가, 다시 맞히면 `reviewed`
- 클래스 복습 목록: 요약 카드, 전체 / 복습 필요 / 다시 확인함 필터
- 복습 상세: 내가 고른 답 vs 정답, 해설, 관련 노트 이동, 다시 확인함 표시 / 삭제
- 다시 풀기 세션: 진행바 + n/m, 정답이면 reviewed 처리, QuizAttempt는 저장하지 않음
- 학생 클래스 홈·드로어·홈 요약 카드에 남은 복습 수 표시
- 문제가 삭제·비공개되면 안내 카드 표시 (크래시 없음)

### 홈
- 인사말에 프로필 이름 표시
- 오늘의 요약: 학생은 오늘 푼 퀴즈 수 · 남은 복습 수, 튜터는 작성 중 노트 · 이번 주 게시 수
- 클래스 카드에 최신 게시 노트 제목, ⋯로 클래스 정보 시트
- 검색: 내 클래스 이름 + 게시 노트 제목, 탭하면 이동
- 클래스가 없을 때 안내 화면
- 미구현(TODO): 스터디 탐색, 알림, 동료 학습자 활동, 마이 페이지

### 반응형 (모바일 · 태블릿 · PC)
- 기준: `AppBreakpoints` 하나 (mobile <600 / tablet 600~1199 / desktop ≥1200)
- 모든 로그인 후 화면이 `AppResponsiveScaffold` 가운데 칼럼 사용 (기본 780, 리더 720, 홈 1024)
- 클래스 메뉴: 모바일·태블릿 드로어, PC는 햄버거로 여닫는 280px 사이드바
- 모달 시트: 모바일 전체 너비, 태블릿 좌우 64 여백, PC 가운데 다이얼로그
- 인증 화면: 태블릿·PC에서 가운데 폰 카드
- 홈 클래스 카드 1 / 2 / 3열, 모바일에서 가로 카드는 세로로 쌓기, 터치 높이 48 이상
- 에디터 저장·게시는 하단 고정 바, 노트 리더 ←/→ 키로 이전·다음 노트
- 390×844 / 600×1024 / 1024×1366 / 1440×900 위젯 테스트로 overflow 검증

### 알림 (인앱)
- 튜터가 노트/퀴즈를 게시하면 학생에게, 학생이 참여 코드로 들어오면 튜터에게 알림
- `classes/{classId}/notifications`에 저장, 홈 벨에 안 읽은 개수 배지
- 벨을 누르면 목록 시트, 항목을 누르면 노트 리더 / 퀴즈 목록 / 클래스 홈으로 이동
- 목록을 열면 `users/{uid}.notificationsSeenAt`에 본 시각을 저장해 읽음 처리
- 푸시(FCM)는 아직 없음: 앱이 켜져 있을 때 실시간으로만 보임

### 마이
- 프로필 카드: 이름, 이메일, 역할 배지, 가입일
- 학습 요약: 학생은 참여 클래스 · 푼 퀴즈 · 남은 복습, 튜터는 운영 클래스 · 작성 노트 · 학생 수
- 설정: 이름 수정(클래스 멤버 이름 스냅샷도 갱신), 역할 변경(튜터 ↔ 튜티), 비밀번호 재설정 메일(이메일 계정)
- 개인정보 처리방침 · 서비스 이용약관 · 내 데이터 안내 (앱 내 초안, `policy_texts.dart`에서 수정)
- 로그아웃, 회원 탈퇴(재인증 → 클래스 나가기 → 필기·복습·퀴즈 기록·프로필 삭제 → 계정 삭제)
- 운영 중인 클래스가 있는 튜터는 탈퇴 전에 클래스를 정리하라고 안내
- 홈 하단 탭 "마이"와 PC 아바타 메뉴에서 진입

### Firestore
- Notification: classes/{classId}/notifications — 멤버 읽기, 게시 알림은 튜터만, 참여 알림은 본인만 생성
- 계정 삭제: 본인 프로필·quizAttempts 삭제 허용, 멤버가 나갈 때 memberCount −1 허용
- Review:
  - users/{uid}/reviews/{classId_quizId_questionId}
  - 본인만 읽기·쓰기, 튜터 읽기 불가
  - 생성 시 wrongCount 1, 수정 시 wrongCount 감소 불가
- 규칙 테스트: `firestore_rules_test/` (classMemberships, members, quizAttempts, reviews)
- Quiz:
  - classes/{classId}/quizzes/{quizId}
  - classes/{classId}/quizzes/{quizId}/questions/{questionId}
- Attempt:
  - users/{uid}/quizAttempts/{attemptId}
- Tutor만 Quiz/Question 변경 가능
- Tutee는 게시된 Quiz만 조회 가능
- 자신의 Attempt만 생성·조회 가능
- Tutor는 담당 클래스의 학습 현황 조회 가능
