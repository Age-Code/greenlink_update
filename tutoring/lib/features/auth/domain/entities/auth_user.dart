class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.providerIds = const <String>[],
  });

  final String uid;
  final String? email;

  /// Firebase sign-in provider ids, such as `password` or `google.com`.
  final List<String> providerIds;

  bool get hasPasswordProvider => providerIds.contains('password');

  bool get hasGoogleProvider => providerIds.contains('google.com');
}
