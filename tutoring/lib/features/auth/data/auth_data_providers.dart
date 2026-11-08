import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tutoring/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:tutoring/features/auth/data/data_sources/user_profile_remote_data_source.dart';
import 'package:tutoring/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:tutoring/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = FirebaseAuth.instance;
  return FirebaseAuthRepository(
    AuthRemoteDataSource(
      firebaseAuth,
      kIsWeb ? null : GoogleSignIn(),
    ),
    UserProfileRemoteDataSource(FirebaseFirestore.instance, firebaseAuth),
  );
});
