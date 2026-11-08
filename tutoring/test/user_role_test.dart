import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';

void main() {
  group('UserRole Firestore serialization', () {
    test('uses one canonical value per role', () {
      expect(UserRole.tutor.firestoreValue, 'tutor');
      expect(UserRole.tutee.firestoreValue, 'tutee');
    });

    test('parses only supported values', () {
      expect(UserRole.fromFirestore('tutor'), UserRole.tutor);
      expect(UserRole.fromFirestore('tutee'), UserRole.tutee);
      expect(UserRole.fromFirestore('student'), isNull);
      expect(UserRole.fromFirestore(null), isNull);
    });
  });
}
