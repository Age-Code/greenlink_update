sealed class AppException implements Exception {
  const AppException(this.userMessage);

  final String userMessage;
}

final class AuthException extends AppException {
  const AuthException(super.userMessage);
}

final class NetworkException extends AppException {
  const NetworkException() : super('네트워크 연결을 확인해 주세요.');
}

final class PermissionException extends AppException {
  const PermissionException() : super('이 작업을 수행할 권한이 없습니다.');
}

final class BackendSetupException extends AppException {
  const BackendSetupException()
    : super('Cloud Firestore 설정이 필요합니다. Firebase Console에서 데이터베이스를 만들어 주세요.');
}

/// A tutor who still owns classes cannot delete the account; the classes
/// (and their notes and quizzes) have to be handed over or removed first.
final class AccountDeletionBlockedException extends AppException {
  const AccountDeletionBlockedException()
    : super('아직 운영 중인 클래스가 있어요. 클래스를 먼저 정리한 뒤 탈퇴할 수 있어요.');
}

final class UnknownException extends AppException {
  const UnknownException() : super('잠시 후 다시 시도해 주세요.');
}
