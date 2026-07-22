// lib/features/notifications/data/repositories/notification_repository_impl.dart
import 'dart:io';

import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<NotificationModel>> getNotifications({String? receiverId, String? roomId}) {
    return remoteDataSource.getNotifications(receiverId: receiverId, roomId: roomId);
  }

  @override
  Future<NotificationModel> sendNotification(NotificationModel notification, {File? imageFile}) {
    return remoteDataSource.sendNotification(notification, imageFile: imageFile);
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<void> resolveIssue(String notificationId) {
    return remoteDataSource.resolveIssue(notificationId);
  }
}
