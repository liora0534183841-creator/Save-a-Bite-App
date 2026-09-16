import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/notification_model.dart';

/// Service class responsible for managing user notifications within Firestore.
///
/// Provides capabilities to create new notification documents, fetch complete
/// notification histories for target users, and update individual read statuses.
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'notifications';

  /// Asynchronously creates a new notification document in Firestore.
  ///
  /// Automatically generates a unique document reference ID and pushes
  /// a structured payload using server timestamps.
  Future<void> triggerNotification({
    required String targetUid,
    required String title,
    required String body,
  }) async {
    try {
      dev.log("Creating new notification for user: $targetUid",
          name: "NotificationService");

      // Generate a new document reference to obtain a unique ID
      final docRef = _firestore.collection(_collectionPath).doc();

      // Write manually mapped payload to database
      await docRef.set({
        'notificationId': docRef.id,
        'targetUid': targetUid,
        'title': title,
        'body': body,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      dev.log("Firebase error creating notification: ${e.message}",
          name: "NotificationService");
      throw Exception("Server error creating notification");
    } catch (e, stack) {
      dev.log("Unknown error creating notification",
          name: "NotificationService", error: e, stackTrace: stack);
    }
  }

  /// Fetches all notification documents belonging to a specified user UID.
  ///
  /// Filters the 'notifications' collection by [targetUid] and sorts results
  /// descending by creation timestamp. Maps documents back to [NotificationModel] objects.
  Future<List<NotificationModel>> getUserNotifications(String uid) async {
    try {
      dev.log("Fetching notifications for user: $uid",
          name: "NotificationService");

      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('targetUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      // Parse Firestore documents into NotificationModel instances
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel(
          notificationId: data['notificationId'] ?? '',
          targetUid: data['targetUid'] ?? '',
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          isRead: data['isRead'] ?? false,
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();
    } on FirebaseException catch (e) {
      dev.log("Firebase error fetching notifications: ${e.message}",
          name: "NotificationService");
      throw Exception("Server error loading notifications");
    } catch (e, stack) {
      dev.log("Unknown error fetching notifications",
          name: "NotificationService", error: e, stackTrace: stack);
      return [];
    }
  }

  /// Updates the 'isRead' status attribute of a specified notification document to true.
  Future<void> markAsRead(String notificationId) async {
    try {
      dev.log("Marking notification as read: $notificationId",
          name: "NotificationService");

      await _firestore.collection(_collectionPath).doc(notificationId).update({
        'isRead': true,
      });
    } on FirebaseException catch (e) {
      dev.log("Firebase error updating notification: ${e.message}",
          name: "NotificationService");
      throw Exception("Server error updating notification status");
    } catch (e, stack) {
      dev.log("Unknown error marking notification as read",
          name: "NotificationService", error: e, stackTrace: stack);
    }
  }
}
