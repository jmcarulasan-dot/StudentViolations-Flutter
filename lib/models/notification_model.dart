class NotificationModel {
  final int id;
  final String? targetUsername;
  final String? targetRole;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    this.targetUsername,
    this.targetRole,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['Id'] ?? map['id'] ?? 0,
      targetUsername: map['TargetUsername'] ?? map['targetUsername'],
      targetRole: map['TargetRole'] ?? map['targetRole'],
      title: map['Title'] ?? map['title'] ?? '',
      message: map['Message'] ?? map['message'] ?? '',
      isRead:
          (map['IsRead'] ?? map['isRead'] ?? false) == true ||
          (map['IsRead'] ?? map['isRead']) == 1,
      createdAt: map['CreatedAt'] != null
          ? DateTime.tryParse(map['CreatedAt'].toString())
          : map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }
}
