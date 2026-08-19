import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/auth/account_deletion.dart';

void main() {
  test('detects Sign in with Apple among linked providers', () {
    expect(usesAppleSignIn(['google.com', 'apple.com']), isTrue);
    expect(usesAppleSignIn(['google.com']), isFalse);
    expect(usesAppleSignIn(const []), isFalse);
  });

  test('detects Google sign-in', () {
    expect(usesGoogleSignIn(['google.com']), isTrue);
    expect(usesGoogleSignIn(['apple.com']), isFalse);
  });
}
