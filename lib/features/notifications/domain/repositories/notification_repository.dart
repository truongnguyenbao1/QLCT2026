// lib/features/notifications/domain/repositories/notification_repository.dart
import 'dart:io';
import '../../data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({String? receiverId, String? roomId});
  Future<NotificationModel> sendNotification(NotificationModel notification, {File? imageFile});
  Future<void> markAsRead(String notificationId);
  Future<void> resolveIssue(String notificationId);
}
