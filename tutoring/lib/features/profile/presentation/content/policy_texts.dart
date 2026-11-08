/// Static texts behind 마이 › 개인정보 및 약관.
///
/// These are DRAFTS written from what the app actually stores. Replace the
/// wording (and remove [policyDraftNotice]) once the operator finalises them.
enum PolicyKind {
  privacy('privacy', '개인정보 처리방침'),
  terms('terms', '서비스 이용약관'),
  data('data', '내 데이터 안내');

  const PolicyKind(this.slug, this.title);

  final String slug;
  final String title;

  static PolicyKind? fromSlug(String slug) {
    for (final kind in values) {
      if (kind.slug == slug) return kind;
    }
    return null;
  }
}

class PolicySection {
  const PolicySection(this.heading, this.body);

  final String heading;
  final String body;
}

const policyDraftNotice = '이 문서는 초안이에요. 서비스 운영자가 내용을 확정하기 전까지 참고용으로만 봐주세요.';

const policyEffectiveDate = '2026년 11월 8일 (초안)';

List<PolicySection> policySections(PolicyKind kind) => switch (kind) {
  PolicyKind.privacy => _privacy,
  PolicyKind.terms => _terms,
  PolicyKind.data => _data,
};

const _privacy = <PolicySection>[
  PolicySection(
    '1. 수집하는 개인정보',
    'Tugether는 서비스 제공에 필요한 최소한의 정보만 수집해요.\n'
        '• 계정 정보: 이메일, 이름, 역할(튜터/튜티). Google 로그인을 쓰면 Google이 제공하는 '
        '프로필 사진 주소가 함께 저장될 수 있어요.\n'
        '• 학습 정보: 참여한 클래스, 노트에 남긴 메모·강조·북마크·필기, 퀴즈와 Quick Check 풀이 기록, '
        '복습(오답 노트) 항목.\n'
        '• 자동 수집 정보: 로그인 보안을 위해 Firebase Authentication이 기록하는 접속 정보.',
  ),
  PolicySection(
    '2. 이용 목적',
    '• 로그인과 계정 식별\n'
        '• 클래스 참여와 튜터가 공유한 노트·퀴즈 제공\n'
        '• 내 학습 기록과 복습 목록 제공\n'
        '• 튜터에게 담당 클래스 학생의 퀴즈 풀이 현황 제공 (이름과 풀이 결과만 보여요. '
        '개인 필기와 복습 항목은 튜터에게 공개되지 않아요.)',
  ),
  PolicySection(
    '3. 보관 기간과 파기',
    '회원 탈퇴 시 프로필, 클래스 참여 정보, 필기, 퀴즈 풀이 기록, 복습 항목을 즉시 삭제해요. '
        '튜터가 작성한 노트와 퀴즈는 튜터의 자료이므로 학생의 탈퇴와 무관하게 유지돼요. '
        '튜터는 운영 중인 클래스를 정리한 뒤 탈퇴할 수 있어요.',
  ),
  PolicySection(
    '4. 제3자 제공과 처리 위탁',
    '개인정보를 제3자에게 판매하거나 제공하지 않아요. 인증과 데이터 저장은 Google LLC의 '
        'Firebase(Authentication, Cloud Firestore · 서울 리전)를 이용하며, 해당 서비스의 보안 정책을 따라요.',
  ),
  PolicySection(
    '5. 이용자의 권리',
    '마이 화면에서 이름 수정, 역할 변경, 로그아웃, 회원 탈퇴를 직접 할 수 있어요. '
        '그 밖의 열람·정정 요청은 운영자 이메일로 문의해 주세요. (문의처: 운영자 이메일을 넣어주세요)',
  ),
  PolicySection('6. 시행일', '이 방침은 $policyEffectiveDate부터 적용돼요.'),
];

const _terms = <PolicySection>[
  PolicySection(
    '1. 목적',
    '이 약관은 Tugether(이하 "서비스")의 이용 조건과 이용자·운영자의 권리와 의무를 정해요.',
  ),
  PolicySection(
    '2. 계정',
    '서비스는 이메일 또는 Google 계정으로 가입해요. 계정은 본인만 사용해야 하고, '
        '비밀번호 관리 책임은 이용자에게 있어요. 역할(튜터/튜티)은 언제든 마이 화면에서 바꿀 수 있어요.',
  ),
  PolicySection(
    '3. 튜터와 튜티',
    '튜터는 클래스를 만들고 노트와 퀴즈를 게시해요. 튜티는 참여 코드로 클래스에 들어가 '
        '게시된 자료를 보고 풀이 기록을 남겨요. 튜터는 담당 클래스 학생의 퀴즈 풀이 현황을 볼 수 있어요.',
  ),
  PolicySection(
    '4. 콘텐츠의 권리',
    '튜터가 작성한 노트와 퀴즈의 권리는 작성한 튜터에게 있어요. 이용자가 남긴 메모·강조·필기는 '
        '본인만 볼 수 있는 개인 기록이에요. 다른 사람의 자료를 허락 없이 외부에 공개하면 안 돼요.',
  ),
  PolicySection(
    '5. 금지 행위',
    '• 타인의 계정 사용, 참여 코드의 무단 공유\n'
        '• 저작권을 침해하거나 불법적인 내용의 게시\n'
        '• 서비스의 정상 운영을 방해하는 행위',
  ),
  PolicySection(
    '6. 서비스 변경과 중단',
    '운영자는 서비스 내용을 바꾸거나 일시 중단할 수 있어요. 중요한 변경은 서비스 안에서 미리 알려요.',
  ),
  PolicySection(
    '7. 책임의 한계',
    '서비스는 학습을 돕기 위한 도구이며, 이용자가 작성·게시한 내용의 정확성은 작성자에게 책임이 있어요. '
        '무료로 제공되는 범위에서 운영자는 법령이 허용하는 한도 안에서 책임을 져요.',
  ),
  PolicySection('8. 시행일', '이 약관은 $policyEffectiveDate부터 적용돼요.'),
];

const _data = <PolicySection>[
  PolicySection(
    '내 계정에 저장되는 것',
    '• 프로필: 이메일, 이름, 역할, (Google 로그인 시) 프로필 사진 주소\n'
        '• 클래스 참여 목록과 각 클래스의 멤버 명단에 적힌 내 이름',
  ),
  PolicySection(
    '학습하면서 쌓이는 것',
    '• 노트 필기: 메모, 문단 강조, 북마크, 펜·형광펜·텍스트 필기 (나만 볼 수 있어요)\n'
        '• 퀴즈와 Quick Check 풀이 기록: 문제별 선택과 정답 여부, 풀이 시각\n'
        '• 복습(오답 노트): 틀린 문제, 틀린 횟수, 다시 확인 여부',
  ),
  PolicySection(
    '누가 볼 수 있나요',
    '• 필기와 복습 항목: 나만\n'
        '• 퀴즈 풀이 결과: 나와 그 클래스의 튜터\n'
        '• 이름: 같은 클래스의 멤버',
  ),
  PolicySection(
    '탈퇴하면',
    '위의 모든 기록과 프로필이 즉시 삭제되고 클래스에서도 빠져요. '
        '내가 튜터로 만든 클래스가 있으면 먼저 정리해야 탈퇴할 수 있어요. 삭제된 기록은 복구할 수 없어요.',
  ),
];
