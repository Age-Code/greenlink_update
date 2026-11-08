/// How the user proves their identity right before deleting the account.
sealed class AccountReauth {
  const AccountReauth();
}

final class PasswordReauth extends AccountReauth {
  const PasswordReauth(this.password);

  final String password;
}

final class GoogleReauth extends AccountReauth {
  const GoogleReauth();
}
