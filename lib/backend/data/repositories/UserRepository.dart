import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _col = 'USER';
  // Creates or overwrites a user profile document in Firestore.
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.collection(_col).doc(user.uid).set(user.toMap());
      dev.log("User saved: ${user.uid}", name: "UserRepository");
    } catch (e, stack) {
      dev.log("Save user failed", name: "UserRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Retrieves user profile data by UID.
  Future<UserModel?> getUserById(String uid) async {
    try {
      var doc = await _db.collection(_col).doc(uid).get();
      return doc.exists ? UserModel.fromMap(doc.data()!) : null;
    } catch (e, stack) {
      dev.log("Fetch user failed for $uid", name: "UserRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Updates specific fields in a user's document.
  Future<void> updateUserFields(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection(_col).doc(uid).update(data);
      dev.log("User fields updated for $uid", name: "UserRepository");
    } catch (e, stack) {
      dev.log("Update user fields failed", name: "UserRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Deletes a user profile document from Firestore.
  Future<void> deleteUserDoc(String uid) async {
    try {
      await _db.collection(_col).doc(uid).delete();
      dev.log("User document deleted: $uid", name: "UserRepository");
    } catch (e, stack) {
      dev.log("Delete user doc failed", name: "UserRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
}