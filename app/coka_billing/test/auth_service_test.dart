import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coka_billing/services/firebase_auth_service.dart';

void main() {
  group('AuthService error messages', () {
    test('user-not-found returns correct message', () {
      final e = FirebaseAuthException(code: 'user-not-found', message: 'There is no user record.');
      expect(AuthService.getFirebaseErrorMessage(e), 'No user found with this email.');
    });

    test('wrong-password returns correct message', () {
      final e = FirebaseAuthException(code: 'wrong-password', message: 'Wrong password.');
      expect(AuthService.getFirebaseErrorMessage(e), 'Incorrect password.');
    });

    test('invalid-credential returns correct message', () {
      final e = FirebaseAuthException(code: 'invalid-credential', message: 'Bad.');
      expect(AuthService.getFirebaseErrorMessage(e), 'Invalid email or password.');
    });

    test('email-already-in-use returns correct message', () {
      final e = FirebaseAuthException(code: 'email-already-in-use', message: 'Exists.');
      expect(AuthService.getFirebaseErrorMessage(e), 'An account already exists with this email.');
    });

    test('weak-password returns correct message', () {
      final e = FirebaseAuthException(code: 'weak-password', message: 'Too weak.');
      expect(AuthService.getFirebaseErrorMessage(e), 'Password is too weak (min 6 characters).');
    });

    test('invalid-email returns correct message', () {
      final e = FirebaseAuthException(code: 'invalid-email', message: 'Bad format.');
      expect(AuthService.getFirebaseErrorMessage(e), 'Invalid email address format.');
    });

    test('user-disabled returns correct message', () {
      final e = FirebaseAuthException(code: 'user-disabled', message: 'Disabled.');
      expect(AuthService.getFirebaseErrorMessage(e), 'This account has been disabled.');
    });

    test('too-many-requests returns correct message', () {
      final e = FirebaseAuthException(code: 'too-many-requests', message: 'Blocked.');
      expect(AuthService.getFirebaseErrorMessage(e), 'Too many attempts. Try again later.');
    });

    test('network-request-failed returns correct message', () {
      final e = FirebaseAuthException(code: 'network-request-failed', message: 'No network.');
      expect(AuthService.getFirebaseErrorMessage(e), 'Network error. Check your internet connection.');
    });

    test('unknown code returns exception message', () {
      final e = FirebaseAuthException(code: 'unknown', message: 'Something went wrong.');
      expect(AuthService.getFirebaseErrorMessage(e), 'Something went wrong.');
    });

    test('unknown code with null message returns default', () {
      final e = FirebaseAuthException(code: 'unknown');
      expect(AuthService.getFirebaseErrorMessage(e), 'Authentication failed.');
    });

    test('non-Firebase exception returns default message', () {
      expect(AuthService.getFirebaseErrorMessage('random error'), 'Authentication failed. Please try again.');
      expect(AuthService.getFirebaseErrorMessage(Exception('test')), 'Authentication failed. Please try again.');
    });
  });
}
