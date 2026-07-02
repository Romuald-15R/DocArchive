class AppNotification {
  final int id;
  final String titre;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      titre: json['titre'],
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}