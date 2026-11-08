import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/quizzes/data/data_sources/quiz_remote_data_source.dart';
import 'package:tutoring/features/quizzes/data/data_sources/quiz_attempt_remote_data_source.dart';
import 'package:tutoring/features/quizzes/data/repositories/firestore_quiz_attempt_repository.dart';
import 'package:tutoring/features/quizzes/data/repositories/firestore_quiz_repository.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_attempt_repository.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return FirestoreQuizRepository(
    QuizRemoteDataSource(FirebaseFirestore.instance),
  );
});

final quizAttemptRepositoryProvider = Provider<QuizAttemptRepository>((ref) {
  return FirestoreQuizAttemptRepository(
    QuizAttemptRemoteDataSource(FirebaseFirestore.instance),
  );
});
