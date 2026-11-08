class StudyClass {
  const StudyClass({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.tutorId,
    required this.tutorName,
    required this.inviteCode,
    required this.memberCount,
    required this.noteCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String tutorId;
  final String tutorName;
  final String inviteCode;
  final int memberCount;
  final int noteCount;
  final DateTime createdAt;
}
