import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final stream = ref.watch(firebaseAuthProvider).authStateChanges();
  // Add logging to the stream itself
  return stream.map((user) {
    print(
        ">>> authStateProvider Stream Emitting: User = ${user?.uid ?? 'null'}");
    return user;
  }).handleError((error) {
    print(">>> authStateProvider Stream Error: $error");
    // It's important to handle errors in the stream if possible
    // throw error; // Rethrow if you want the provider to be in error state
  });
});

class AuthService {
  final FirebaseAuth _auth;
  AuthService(this._auth);

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});
