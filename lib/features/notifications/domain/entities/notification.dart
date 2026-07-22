// lib/features/notifications/domain/entities/notification.dart
import 'package:equatable/equatable.dart';

enum AppNotificationType {
  announcement('ANNOUNCEMENT'),
  issue('ISSUE'),
  system('SYSTEM');

  final String code;
  const AppNotificationType(this.code);

  static AppNotificationType fromCode(String code) {
    return values.firstWhere(
      (e) => e.code == code,
      orElse: () => AppNotificationType.announcement,
    );
  }
}

enum AppNotificationStatus {
  unread('UNREAD'),
  read('READ'),
  resolved('RESOLVED');

  final String code;
  const AppNotificationStatus(this.code);

  static AppNotificationStatus fromCode(String code) {
    return values.firstWhere(
      (e) => e.code == code,
      orElse: () => AppNotificationStatus.unread,
    );
  }
}

class AppNotification extends Equatable {
  final String id;
  final String? roomId;
  final String? roomNumber;
  final String senderId;
  final String? senderName;
  final String? receiverId;
  final String title;
  final String content;
  final AppNotificationType type;
  final AppNotificationStatus status;
  final String? imageUrl;
  final DateTime sentAt;

  const AppNotification({
    required this.id,
    this.roomId,
    this.roomNumber,
    required this.senderId,
    this.senderName,
    this.receiverId,
    required this.title,
    required this.content,
    required this.type,
    required this.status,
    this.imageUrl,
    required this.sentAt,
  });

  @override
  List<Object?> get props => [
        id,
        roomId,
        roomNumber,
        senderId,
        senderName,
        receiverId,
        title,
        content,
        type,
        status,
        imageUrl,
        sentAt,
      ];
}
