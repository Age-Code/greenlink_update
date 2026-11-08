import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring/core/firebase/firebase_paths.dart';
import 'package:tutoring/features/auth/data/dtos/user_profile_dto.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';

class UserProfileRemoteDataSource {
  UserProfileRemoteDataSource(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection(FirebasePaths.users).doc(uid);

  Future<UserProfileDto?> getProfile(String uid) async {
    final snapshot = await _user(uid).get();
    return snapshot.exists ? UserProfileDto.fromFirestore(snapshot) : null;
  }

  Future<void> ensureProfile(User user) async {
    final reference = _user(user.uid);
    final existing = await reference.get();
    if (existing.exists) return;
    final email = user.email;
    final dto = UserProfileDto(
      uid: user.uid,
      email: email,
      name: user.displayName ?? email?.split('@').first ?? '사용자',
      role: null,
      profileImageUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
    await reference.set(dto.toFirestore());
  }

  Future<void> updateName(String uid, String name) => _user(uid).set({
    'name': name,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> deleteProfile(String uid) => _user(uid).delete();

  Future<void> saveRole(String uid, UserRole role) async {
    final user = _auth.currentUser;
    if (user != null && user.uid == uid) await ensureProfile(user);
    await _user(uid).set({
      'role': role.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
