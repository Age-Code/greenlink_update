import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/reviews/data/data_sources/review_remote_data_source.dart';
import 'package:tutoring/features/reviews/data/repositories/firestore_review_repository.dart';
import 'package:tutoring/features/reviews/domain/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return FirestoreReviewRepository(
    ReviewRemoteDataSource(FirebaseFirestore.instance),
  );
});
