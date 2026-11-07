import 'package:flutter_test/flutter_test.dart';
import 'package:front/screens/auth/signup_page.dart';

void main() {
  test('signup validation matches server rules', () {
    expect(validateSignupInput('a@b.co', 'password', '닉네임'), isNull);
    expect(validateSignupInput('not-email', 'password', '닉'), isNotNull);
    expect(validateSignupInput('a@b.co', 'short', '닉'), isNotNull);
    expect(validateSignupInput('a@b.co', 'password', ''), isNotNull);
    expect(validateSignupInput('a@b.co', 'password', 'x' * 51), isNotNull);
  });
}
