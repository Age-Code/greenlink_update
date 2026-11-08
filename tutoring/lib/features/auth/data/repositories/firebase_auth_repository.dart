import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring/core/errors/app_exception.dart';
import 'package:tutoring/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:tutoring/features/auth/data/data_sources/user_profile_remote_data_source.dart';
import 'package:tutoring/features/auth/domain/entities/auth_user.dart';
import 'package:tutoring/features/auth/domain/entities/user_profile.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._authDataSource, this._profileDataSource);

  final AuthRemoteDataSource _authDataSource;
  final UserProfileRemoteDataSource _profileDataSource;

  @override
  Stream<AuthUser?> watchAuthState() => _authDataSource.watchAuthState().map(
    (user) => user == null ? null : _toDomain(user),
  );

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) => _authenticate(() => _authDataSource.signInWithEmail(email, password));

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) => _authenticate(() => _authDataSource.signUpWithEmail(email, password));

  @override
  Future<AuthUser> signInWithGoogle() =>
      _authenticate(_authDataSource.signInWithGoogle);

  @override
  Future<AuthUser> signInWithApple() =>
      _authenticate(_authDataSource.signInWithApple);

  Future<AuthUser> _authenticate(
    Future<UserCredential> Function() request,
  ) async {
    try {
      final credential = await request();
      final user = credential.user;
      if (user == null) throw const UnknownException();
      return _toDomain(user);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_authMessage(error.code));
    } on FirebaseException catch (error) {
      throw AuthException(_authMessage(error.code));
    } on AppException {
      rethrow;
    } catch (error) {
      throw AuthException(
        '로그인 처리 중 예상하지 못한 오류가 발생했어요 '
        '(${error.runtimeType}).',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authDataSource.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_authMessage(error.code));
    }
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    try {
      return (await _profileDataSource.getProfile(uid))?.toDomain();
    } on FirebaseException catch (error) {
      throw _mapFirestoreException(error);
    }
  }

  @override
  Future<void> saveRole({required String uid, required UserRole role}) async {
    try {
      await _profileDataSource.saveRole(uid, role);
    } on FirebaseException catch (error) {
      throw _mapFirestoreException(error);
    }
  }

  @override
  Future<void> updateName({required String uid, required String name}) async {
    try {
      await _profileDataSource.updateName(uid, name.trim());
    } on FirebaseException catch (error) {
      throw _mapFirestoreException(error);
    }
  }

  @override
  Future<void> reauthenticateWithPassword(String password) =>
      _guard(() => _authDataSource.reauthenticateWithPassword(password));

  @override
  Future<void> reauthenticateWithGoogle() =>
      _guard(_authDataSource.reauthenticateWithGoogle);

  @override
  Future<void> deleteProfile(String uid) async {
    try {
      await _profileDataSource.deleteProfile(uid);
    } on FirebaseException catch (error) {
      throw _mapFirestoreException(error);
    }
  }

  @override
  Future<void> deleteAccount() => _guard(_authDataSource.deleteAccount);

  @override
  Future<void> signOut() => _authDataSource.signOut();

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthException(_authMessage(error.code));
    } on FirebaseException catch (error) {
      throw AuthException(_authMessage(error.code));
    } on AppException {
      rethrow;
    } catch (error) {
      throw AuthException('인증 처리 중 예상하지 못한 오류가 발생했어요 (${error.runtimeType}).');
    }
  }

  AuthUser _toDomain(User user) => AuthUser(
    uid: user.uid,
    email: user.email,
    providerIds: user.providerData
        .map((info) => info.providerId)
        .toList(growable: false),
  );

  AppException _mapFirestoreException(FirebaseException error) {
    final message = error.message?.toLowerCase() ?? '';
    if (message.contains('service_disabled') ||
        message.contains('firestore api') ||
        message.contains('firestore.googleapis.com')) {
      return const BackendSetupException();
    }
    if (error.code == 'permission-denied') return const PermissionException();
    return const UnknownException();
  }

  String _authMessage(String code) => switch (code) {
    'invalid-credential' ||
    'invalid-login-credentials' ||
    'user-not-found' ||
    'wrong-password' => '가입된 이메일과 비밀번호를 확인해 주세요.',
    'email-already-in-use' => '이미 사용 중인 이메일입니다.',
    'invalid-email' => '올바른 이메일 주소를 입력해 주세요.',
    'weak-password' => '비밀번호는 6자 이상 입력해 주세요.',
    'operation-not-allowed' =>
      '현재 Firebase에서 이 로그인 방식이 활성화되지 않았어요. 이메일 로그인을 이용해 주세요.',
    'user-disabled' => '사용이 중지된 계정입니다.',
    'unauthorized-domain' ||
    'app-not-authorized' => '현재 웹 주소가 Firebase 로그인 허용 도메인에 등록되지 않았어요.',
    'network-request-failed' => '네트워크 연결을 확인해 주세요.',
    'too-many-requests' => '요청이 많습니다. 잠시 후 다시 시도해 주세요.',
    'popup-blocked' => '브라우저가 로그인 팝업을 차단했어요.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' => '로그인 팝업이 닫혔어요. 다시 시도해 주세요.',
    'account-exists-with-different-credential' =>
      '같은 이메일이 다른 로그인 방식으로 이미 가입되어 있어요.',
    'web-storage-unsupported' => '브라우저 저장소를 사용할 수 없어요. 시크릿 모드를 끄고 다시 시도해 주세요.',
    'requires-recent-login' => '보안을 위해 다시 로그인한 뒤 시도해 주세요.',
    'user-mismatch' => '지금 로그인한 계정과 다른 계정으로 확인했어요.',
    'no-current-user' => '로그인 정보가 없어요. 다시 로그인해 주세요.',
    'no-email' => '이 계정에는 이메일이 없어 비밀번호로 확인할 수 없어요.',
    _ => '로그인 오류($code)가 발생했어요.',
  };
}
