// 상대 시간 표시 — "방금 전", "5분 전", "3시간 전", "2일 전"

String formatRelativeTime(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);

  if (diff.isNegative || diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}

// 문자열 시각을 상대 시간으로 — 파싱 실패 시 null
String? formatRelativeTimeString(String? raw, {DateTime? now}) {
  if (raw == null) return null;
  final time = DateTime.tryParse(raw);
  if (time == null) return null;
  return formatRelativeTime(time, now: now);
}
