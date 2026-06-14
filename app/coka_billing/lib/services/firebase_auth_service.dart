import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

final _log = Logger('AuthService');

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isSignedIn => _auth.currentUser != null;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      _log.warning('Sign in failed: ${e.code} ${e.message}');
      return null;
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      _log.warning('Sign up failed: ${e.code} ${e.message}');
      return null;
    }
  }

  static String? getFirebaseErrorMessage(dynamic exception) {
    if (exception is FirebaseAuthException) {
      return switch (exception.code) {
        'user-not-found' => 'No user found with this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-credential' => 'Invalid email or password.',
        'email-already-in-use' => 'An account already exists with this email.',
        'weak-password' => 'Password is too weak (min 6 characters).',
        'invalid-email' => 'Invalid email address format.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'network-request-failed' => 'Network error. Check your internet connection.',
        _ => exception.message ?? 'Authentication failed.',
      };
    }
    return 'Authentication failed. Please try again.';
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
