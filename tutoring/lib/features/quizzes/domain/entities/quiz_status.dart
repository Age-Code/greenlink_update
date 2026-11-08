enum QuizStatus {
  draft('draft'),
  published('published');

  const QuizStatus(this.firestoreValue);

  final String firestoreValue;

  static QuizStatus fromFirestore(String? value) =>
      value == 'published' ? QuizStatus.published : QuizStatus.draft;
}
