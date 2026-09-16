import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import '../data/models/notification_model.dart';
import '../data/services/notification_service.dart';

// Manages state and logic for in-app notifications.
class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  // Indicates whether an asynchronous operation is in progress.
  bool get isLoading => _isLoading;

  List<NotificationModel> _notifications = [];
  // The list of fetched notifications for the user.
  List<NotificationModel> get notifications => _notifications;

  String? _errorMessage;
  // Holds the latest error message, or `null` if no error exists.
  String? get errorMessage => _errorMessage;

  // Updates the loading status and notifies about it.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clears the current error message and reports it.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Triggers a new in-app notification for a specific user.
  Future<bool> triggerNotification(
    String targetUid,
    String title,
    String body,
  ) async {
    clearError();
    try {
      dev.log("Request to the Controller: Create Notification for $targetUid", name: "NotificationController");
      return await _notificationService.createInAppNotification(targetUid, title, body);
    } catch (e, stack) {
      dev.log("Error creating notification", name: "NotificationController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

 // Loads the complete notification history for a user.
  Future<void> loadNotificationHistory(String uid) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to the Controller: Load Notification History", name: "NotificationController");
      _notifications = await _notificationService.getUserNotificationHistory(uid);
    } catch (e, stack) {
      dev.log("Error loading notifications", name: "NotificationController", error: e, stackTrace: stack);
      _notifications = [];
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

 // Returns a stream of real-time incoming notifications for a user.
  Stream<List<NotificationModel>> listenToRealTimeNotifications(String uid) {
    dev.log("Request to the Controller: Listen to Real-Time Notifications", name: "NotificationController");
    return _notificationService.setupInAppNotificationListener(uid);
  }
}