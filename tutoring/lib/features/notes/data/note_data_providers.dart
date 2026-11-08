import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/notes/data/data_sources/annotation_remote_data_source.dart';
import 'package:tutoring/features/notes/data/data_sources/note_remote_data_source.dart';
import 'package:tutoring/features/notes/data/repositories/firestore_annotation_repository.dart';
import 'package:tutoring/features/notes/data/repositories/firestore_note_repository.dart';
import 'package:tutoring/features/notes/domain/repositories/annotation_repository.dart';
import 'package:tutoring/features/notes/domain/repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return FirestoreNoteRepository(
    NoteRemoteDataSource(FirebaseFirestore.instance),
  );
});

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  return FirestoreAnnotationRepository(
    AnnotationRemoteDataSource(FirebaseFirestore.instance),
  );
});
