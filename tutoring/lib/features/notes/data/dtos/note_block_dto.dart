import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';

class NoteBlockDto {
  const NoteBlockDto({
    required this.id,
    required this.noteId,
    required this.type,
    required this.order,
    required this.content,
    required this.language,
    required this.quizId,
    required this.questionId,
  });

  final String id;
  final String noteId;
  final String type;
  final int order;
  final String content;
  final String? language;
  final String? quizId;
  final String? questionId;

  factory NoteBlockDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) => NoteBlockDto.fromMap(
    snapshot.id,
    snapshot.data() ?? const <String, dynamic>{},
  );

  factory NoteBlockDto.fromMap(String id, Map<String, dynamic> data) {
    return NoteBlockDto(
      id: id,
      noteId: data['noteId'] as String? ?? '',
      type: data['type'] as String? ?? 'paragraph',
      order: (data['order'] as num?)?.toInt() ?? 0,
      content: data['content'] as String? ?? '',
      language: data['language'] as String?,
      quizId: data['quizId'] as String?,
      questionId: data['questionId'] as String?,
    );
  }

  NoteBlock toDomain() => NoteBlock(
    id: id,
    noteId: noteId,
    type: NoteBlockType.fromFirestore(type),
    order: order,
    content: content,
    language: language,
    quizId: quizId,
    questionId: questionId,
  );

  factory NoteBlockDto.fromDomain(NoteBlock block) => NoteBlockDto(
    id: block.id,
    noteId: block.noteId,
    type: block.type.firestoreValue,
    order: block.order,
    content: block.content,
    language: block.language,
    quizId: block.quizId,
    questionId: block.questionId,
  );

  Map<String, Object?> toFirestore() => {
    'noteId': noteId,
    'type': type,
    'order': order,
    'content': content,
    'language': language,
    'quizId': quizId,
    'questionId': questionId,
  };
}
