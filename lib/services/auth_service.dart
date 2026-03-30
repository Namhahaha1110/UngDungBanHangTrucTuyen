import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String normalizeEmail(String email) => email.trim().toLowerCase();

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: normalizeEmail(email),
      password: password.trim(),
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: normalizeEmail(email),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: normalizeEmail(email));
  }

  Future<void> signOut() => _auth.signOut();
}
