// lib/features/notifications/data/models/notification_model.dart
import '../../domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    super.roomId,
    super.roomNumber,
    required super.senderId,
    super.senderName,
    super.receiverId,
    required super.title,
    required super.content,
    required super.type,
    required super.status,
    super.imageUrl,
    required super.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String?,
      roomNumber: json['room_number'] as String?, // Mapped from query
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String?, // Mapped from query
      receiverId: json['receiver_id'] as String?,
      title: json['title'] as String? ?? 'Không có tiêu đề',
      content: json['content'] as String? ?? '',
      type: AppNotificationType.fromCode(json['type'] as String? ?? 'ANNOUNCEMENT'),
      status: AppNotificationStatus.fromCode(json['status'] as String? ?? 'UNREAD'),
      imageUrl: json['image_url'] as String?,
      sentAt: json['sent_at'] != null 
          ? DateTime.parse(json['sent_at'] as String) 
          : (json['created_at'] != null 
              ? DateTime.parse(json['created_at'] as String) 
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'title': title,
      'content': content,
      'type': type.code,
      'status': status.code,
      'image_url': imageUrl,
      'sent_at': sentAt.toIso8601String(),
    };
  }
}
