/// "방금", "n분 전", "n시간 전", "어제", "n일 전", then "M/d".
String relativeTimeLabel(DateTime time, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(time);
  if (difference.inMinutes < 1) return '방금';
  if (difference.inHours < 1) return '${difference.inMinutes}분 전';
  if (difference.inHours < 24) return '${difference.inHours}시간 전';
  if (difference.inDays < 2) return '어제';
  if (difference.inDays < 7) return '${difference.inDays}일 전';
  return '${time.month}/${time.day}';
}
