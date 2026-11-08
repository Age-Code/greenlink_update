enum NoteBlockType {
  heading('heading'),
  heading2('heading2'),
  heading3('heading3'),
  paragraph('paragraph'),
  code('code'),
  image('image'),
  quote('quote'),
  callout('callout'),
  quiz('quiz');

  const NoteBlockType(this.firestoreValue);

  final String firestoreValue;

  static NoteBlockType fromFirestore(String? value) => switch (value) {
    'heading' => NoteBlockType.heading,
    'heading2' => NoteBlockType.heading2,
    'heading3' => NoteBlockType.heading3,
    'code' => NoteBlockType.code,
    'image' => NoteBlockType.image,
    'quote' => NoteBlockType.quote,
    'callout' => NoteBlockType.callout,
    'quiz' => NoteBlockType.quiz,
    _ => NoteBlockType.paragraph,
  };
}

class NoteBlock {
  const NoteBlock({
    required this.id,
    required this.noteId,
    required this.type,
    required this.order,
    required this.content,
    required this.language,
    this.quizId,
    this.questionId,
  });

  final String id;
  final String noteId;
  final NoteBlockType type;
  final int order;
  final String content;
  final String? language;
  final String? quizId;
  final String? questionId;

  NoteBlock copyWith({
    String? id,
    String? noteId,
    NoteBlockType? type,
    int? order,
    String? content,
    String? language,
    String? quizId,
    String? questionId,
  }) => NoteBlock(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    type: type ?? this.type,
    order: order ?? this.order,
    content: content ?? this.content,
    language: language ?? this.language,
    quizId: quizId ?? this.quizId,
    questionId: questionId ?? this.questionId,
  );
}
