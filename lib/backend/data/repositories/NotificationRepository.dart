import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _col = 'NOTIFICATION';

  // Creates a new notification document.
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      await _db.collection(_col).doc(notification.notificationId).set(notification.toMap());
      dev.log("Notification saved: ${notification.notificationId}", name: "NotificationRepository");
    } catch (e, stack) {
      dev.log("Save notification failed", name: "NotificationRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Fetches all notifications targeted to a specific user.
  Future<List<NotificationModel>> getNotificationsByUser(String targetUid) async {
    try {
      var snap = await _db.collection(_col).where('targetUid', isEqualTo: targetUid).get();
      return snap.docs.map((d) => NotificationModel.fromMap(d.data())).toList();
    } catch (e, stack) {
      dev.log("Fetch notification failed", name: "NotificationRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Listens to real-time updates for unread notifications.

  Stream<List<NotificationModel>> watchUnreadNotifications(String targetUid) {
    return _db.collection(_col)
        .where('targetUid', isEqualTo: targetUid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) {
          dev.log("Real-time notification update received", name: "NotificationRepository");
          return snap.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList();
        });
  }
  // Updates specific fields
  Future<void> updateNotificationFields(String notificationId, Map<String, dynamic> data) async {
    try {
      await _db.collection(_col).doc(notificationId).update(data);
      dev.log("Notification updated: $notificationId", name: "NotificationRepository");
    } catch (e, stack) {
      dev.log("Update notification failed", name: "NotificationRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
}