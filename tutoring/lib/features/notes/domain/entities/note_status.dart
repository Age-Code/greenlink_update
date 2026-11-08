enum NoteStatus {
  draft('draft'),
  published('published');

  const NoteStatus(this.firestoreValue);

  final String firestoreValue;

  static NoteStatus fromFirestore(String? value) => switch (value) {
    'published' => NoteStatus.published,
    _ => NoteStatus.draft,
  };
}
