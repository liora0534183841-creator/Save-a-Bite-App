import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Authenticates a user with email and password.
  Future<UserCredential?> signInAuth(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e, stack) {
      dev.log("Auth signIn error", name: "AuthRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Creates a new user account.
  Future<UserCredential?> createUserAuth(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e, stack) {
      dev.log("Auth create user error", name: "AuthRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Sends a password reset link to the provided email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      dev.log("Reset email sent to $email", name: "AuthRepository");
    } catch (e, stack) {
      dev.log("Send reset email error", name: "AuthRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Signs out the currently logged-in user.
  Future<void> signOutAuth() async {
    try {
      await _auth.signOut();
      dev.log("User signed out", name: "AuthRepository");
    } catch (e, stack) {
      dev.log("Sign out error", name: "AuthRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;
  // Reauthenticates user (required before sensitive operations like delete/password change).
  Future<bool> reauthenticateUser(String email, String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      dev.log("User reauthenticated", name: "AuthRepository");
      return true;
    } catch (e, stack) {
      dev.log("Reauthentication error", name: "AuthRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Updates the current user's password.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      dev.log("Password updated successfully", name: "AuthRepository");
    } catch (e, stack) {
      dev.log("Update password error", name: "AuthRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Deletes the user's authentication account.
  Future<void> deleteUserAuth() async {
    try {
      await _auth.currentUser?.delete();
      dev.log("User Auth deleted", name: "AuthRepository");
    } catch (e, stack) {
      dev.log("Delete Auth user error", name: "AuthRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
}