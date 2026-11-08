import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/classes/data/data_sources/class_remote_data_source.dart';
import 'package:tutoring/features/classes/data/repositories/firebase_class_repository.dart';
import 'package:tutoring/features/classes/domain/repositories/class_repository.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return FirebaseClassRepository(
    ClassRemoteDataSource(FirebaseFirestore.instance),
  );
});
