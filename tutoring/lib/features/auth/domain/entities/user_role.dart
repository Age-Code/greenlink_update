enum UserRole {
  tutor('tutor'),
  tutee('tutee');

  const UserRole(this.firestoreValue);

  final String firestoreValue;

  static UserRole? fromFirestore(String? value) {
    for (final role in values) {
      if (role.firestoreValue == value) return role;
    }
    return null;
  }
}
