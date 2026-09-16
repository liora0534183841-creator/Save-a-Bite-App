class NotificationModel {
  final String notificationId; 
  final String targetUid;     
  final String title;          
  final String body;          
  final bool isRead;           

  NotificationModel({
    required this.notificationId,
    required this.targetUid,
    required this.title,
    required this.body,
    required this.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notificationId'] ?? '',
      targetUid: map['targetUid'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'targetUid': targetUid,
      'title': title,
      'body': body,
      'isRead': isRead,
    };
  }
}