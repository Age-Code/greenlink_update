import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/core/firebase/firebase_paths.dart';
import 'package:tutoring/features/classes/data/dtos/class_member_dto.dart';
import 'package:tutoring/features/classes/data/dtos/study_class_dto.dart';

class ClassRemoteDataSource {
  ClassRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  final Random _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection(FirebasePaths.classes);

  CollectionReference<Map<String, dynamic>> _memberships(String uid) =>
      _firestore
          .collection(FirebasePaths.users)
          .doc(uid)
          .collection(FirebasePaths.classMemberships);

  Stream<List<StudyClassDto>> watchMyClasses(String uid) {
    return _memberships(uid)
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(StudyClassDto.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<ClassMemberDto>> watchMembers(String classId) => _classes
      .doc(classId)
      .collection(FirebasePaths.members)
      .orderBy('joinedAt')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(ClassMemberDto.fromFirestore)
            .toList(growable: false),
      );

  Stream<StudyClassDto?> watchClass(String classId) {
    return _classes
        .doc(classId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists ? StudyClassDto.fromFirestore(snapshot) : null,
        );
  }

  Future<StudyClassDto> createClass({
    required String userId,
    required String tutorName,
    required String title,
    required String description,
  }) async {
    final reference = _classes.doc();
    final dto = StudyClassDto(
      id: reference.id,
      title: title.trim(),
      category: 'STUDY',
      description: description.trim(),
      tutorId: userId,
      tutorName: tutorName.trim().isEmpty ? 'Tutor' : tutorName.trim(),
      inviteCode: _inviteCode(),
      memberCount: 1,
      noteCount: 0,
      createdAt: DateTime.now(),
    );
    final batch = _firestore.batch();
    batch.set(reference, dto.toFirestore());
    batch.set(reference.collection(FirebasePaths.members).doc(userId), {
      'uid': userId,
      'role': 'tutor',
      'name': dto.tutorName,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _memberships(userId).doc(reference.id),
      dto.toMembershipFirestore('tutor'),
    );
    await batch.commit();
    return dto;
  }

  Future<StudyClassDto> joinClass({
    required String userId,
    required String userName,
    required String inviteCode,
  }) async {
    final normalized = inviteCode.trim().toUpperCase();
    final result =
        await _classes
            .where('inviteCode', isEqualTo: normalized)
            .limit(1)
            .get();
    if (result.docs.isEmpty) throw StateError('invite-code-not-found');

    final classReference = result.docs.single.reference;
    final memberReference = classReference
        .collection(FirebasePaths.members)
        .doc(userId);
    final membershipReference = _memberships(userId).doc(classReference.id);

    return _firestore.runTransaction((transaction) async {
      final classSnapshot = await transaction.get(classReference);
      final membershipSnapshot = await transaction.get(membershipReference);
      final dto = StudyClassDto.fromFirestore(classSnapshot);
      if (membershipSnapshot.exists) return dto;

      transaction.set(memberReference, {
        'uid': userId,
        'role': 'tutee',
        'name': userName.trim(),
        'joinedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(membershipReference, {
        ...dto.toMembershipFirestore('tutee'),
        'memberCount': dto.memberCount + 1,
      });
      transaction.update(classReference, {
        'memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return dto;
    });
  }

  Future<List<StudyClassDto>> getMyClasses(String uid) async {
    final snapshot =
        await _memberships(uid).orderBy('joinedAt', descending: true).get();
    return snapshot.docs
        .map(StudyClassDto.fromFirestore)
        .toList(growable: false);
  }

  Future<bool> ownsAnyClass(String uid) async {
    final snapshot =
        await _classes.where('tutorId', isEqualTo: uid).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> leaveClass({required String userId, required String classId}) {
    final classReference = _classes.doc(classId);
    final memberReference = classReference
        .collection(FirebasePaths.members)
        .doc(userId);
    final membershipReference = _memberships(userId).doc(classId);
    return _firestore.runTransaction((transaction) async {
      final classSnapshot = await transaction.get(classReference);
      final memberSnapshot = await transaction.get(memberReference);
      transaction.delete(membershipReference);
      if (memberSnapshot.exists) transaction.delete(memberReference);
      if (classSnapshot.exists && memberSnapshot.exists) {
        transaction.update(classReference, {
          'memberCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> deleteClass({
    required String userId,
    required String classId,
  }) async {
    final classReference = _classes.doc(classId);
    final classSnapshot = await classReference.get();
    if (!classSnapshot.exists || classSnapshot.data()?['tutorId'] != userId) {
      throw StateError('class-delete-not-allowed');
    }

    final members = await classReference.collection(FirebasePaths.members).get();
    final notes = await classReference.collection(FirebasePaths.notes).get();
    final quizzes = await classReference.collection(FirebasePaths.quizzes).get();
    final notifications =
        await classReference.collection(FirebasePaths.notifications).get();

    final contentReferences = <DocumentReference<Map<String, dynamic>>>[];
    for (final note in notes.docs) {
      final blocks = await note.reference.collection(FirebasePaths.blocks).get();
      contentReferences.addAll(blocks.docs.map((item) => item.reference));
      contentReferences.add(note.reference);
    }
    for (final quiz in quizzes.docs) {
      final questions =
          await quiz.reference.collection(FirebasePaths.questions).get();
      contentReferences.addAll(questions.docs.map((item) => item.reference));
      contentReferences.add(quiz.reference);
    }
    contentReferences.addAll(notifications.docs.map((item) => item.reference));
    await _deleteReferences(contentReferences);

    final membershipReferences = <DocumentReference<Map<String, dynamic>>>[
      for (final member in members.docs) _memberships(member.id).doc(classId),
    ];
    await _deleteReferences(membershipReferences);
    await _deleteReferences(members.docs.map((item) => item.reference).toList());
    await classReference.delete();
  }

  Future<void> _deleteReferences(
    List<DocumentReference<Map<String, dynamic>>> references,
  ) async {
    const batchSize = 400;
    for (var start = 0; start < references.length; start += batchSize) {
      final batch = _firestore.batch();
      final end = min(start + batchSize, references.length);
      for (final reference in references.sublist(start, end)) {
        batch.delete(reference);
      }
      await batch.commit();
    }
  }

  Future<void> updateMemberName({
    required String userId,
    required String name,
  }) async {
    final memberships = await _memberships(userId).get();
    if (memberships.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final membership in memberships.docs) {
      batch.update(
        _classes
            .doc(membership.id)
            .collection(FirebasePaths.members)
            .doc(userId),
        {'name': name},
      );
    }
    await batch.commit();
  }

  String _inviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix =
        List.generate(
          6,
          (_) => alphabet[_random.nextInt(alphabet.length)],
        ).join();
    return 'STUDY-$suffix';
  }
}
