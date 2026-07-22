// lib/features/notifications/domain/repositories/notification_repository.dart
import 'dart:typed_data';
import '../../data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({String? receiverId, String? roomId});
  Future<NotificationModel> sendNotification(NotificationModel notification, {Uint8List? imageBytes, String? imageExt});
  Future<void> markAsRead(String notificationId);
  Future<void> resolveIssue(String notificationId);
}
