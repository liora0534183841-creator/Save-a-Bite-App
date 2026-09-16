/// A data model class representing an individual user notification.
///
/// Encapsulates notification metadata including identification numbers,
/// target user UIDs, textual content, read status, and creation timestamps.
class NotificationModel {
  final String notificationId;
  final String targetUid;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.targetUid,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });
}
