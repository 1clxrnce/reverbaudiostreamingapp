// auth_service.dart
// Handles Firebase authentication - sign in, sign up, sign out

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user stream - rebuilds UI when auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user (null if not signed in)
  User? get currentUser => _auth.currentUser;

  // Is user signed in?
  bool get isSignedIn => _auth.currentUser != null;

  // Is user anonymous?
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  // ── Anonymous Sign In ──────────────────────────────────────────────────
  // Sign in anonymously - no email/password needed
  // Perfect for first-time users who just want to try the app
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Email/Password Sign Up ─────────────────────────────────────────────
  // Create a new account with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Email/Password Sign In ─────────────────────────────────────────────
  // Sign in with existing email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Link Anonymous Account to Email ────────────────────────────────────
  // Upgrade anonymous account to permanent email/password account
  // Preserves playlists and favorites from anonymous session
  Future<UserCredential?> linkAnonymousToEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        throw 'Not signed in anonymously';
      }

      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      return await user.linkWithCredential(credential);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error Handler ──────────────────────────────────────────────────────
  String _handleError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        case 'operation-not-allowed':
          return 'Operation not allowed';
        case 'weak-password':
          return 'Password is too weak (minimum 6 characters)';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'user-not-found':
          return 'No account found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'invalid-credential':
          return 'Invalid email or password';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later';
        default:
          return e.message ?? 'Authentication error: ${e.code}';
      }
    }
    return e.toString();
  }
}
