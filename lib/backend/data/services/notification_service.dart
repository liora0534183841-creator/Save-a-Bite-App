import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

import '../models/notification_model.dart';
import '../repositories/NotificationRepository.dart';

class NotificationService {
  final NotificationRepository _notificationRepo = NotificationRepository();
  // Generates and saves a new in-app notification for a specific user.
  Future<bool> createInAppNotification(String targetUid, String title, String body) async {
    try {
      dev.log("Creating new notification for user: $targetUid", name: "NotificationService");
      String newNotificationId = FirebaseFirestore.instance.collection('NOTIFICATION').doc().id;

      NotificationModel newNotification = NotificationModel(
        notificationId: newNotificationId, targetUid: targetUid, title: title, body: body, isRead: false,
      );

      await _notificationRepo.saveNotification(newNotification);
      return true;
    } catch (e, stack) {
      dev.log("Error creating notification", name: "NotificationService", error: e, stackTrace: stack);
      throw Exception("Failed to create system notification: $e");
    }
  }
  // Retrieves a user's notification history and marks unread notifications as read.
  Future<List<NotificationModel>> getUserNotificationHistory(String uid) async {
    try {
      dev.log("Fetching notification history for: $uid", name: "NotificationService");
      List<NotificationModel> notifications = await _notificationRepo.getNotificationsByUser(uid);

      for (var notif in notifications) {
        if (!notif.isRead) {
          await _notificationRepo.updateNotificationFields(notif.notificationId, {'isRead': true});
        }
      }
      return notifications;
    } catch (e, stack) {
      dev.log("Error fetching notification history", name: "NotificationService", error: e, stackTrace: stack);
      throw Exception("Failed to fetch notifications: $e");
    }
  }

  Stream<List<NotificationModel>> setupInAppNotificationListener(String uid) {
    dev.log("Starting real-time notification listener for: $uid", name: "NotificationService");
    return _notificationRepo.watchUnreadNotifications(uid);
  }
}