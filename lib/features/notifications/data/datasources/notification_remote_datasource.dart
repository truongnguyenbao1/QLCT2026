// lib/features/notifications/data/datasources/notification_remote_datasource.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/notification_model.dart';
import '../../domain/entities/notification.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({String? receiverId, String? roomId});
  Future<NotificationModel> sendNotification(NotificationModel notification, {File? imageFile});
  Future<void> markAsRead(String notificationId);
  Future<void> resolveIssue(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient _client;

  NotificationRemoteDataSourceImpl(this._client);

  @override
  Future<List<NotificationModel>> getNotifications({String? receiverId, String? roomId}) async {
    try {
      var query = _client.from(AppConstants.tableNotifications).select('''
        *,
        phong(room_number),
        khachthue!thongbao_sender_id_fkey(full_name)
      ''');

      if (receiverId != null) {
        // Có thể là thông báo gửi riêng hoặc gửi chung (receiverId is null)
        query = query.or('receiver_id.eq.$receiverId,receiver_id.is.null');
      }
      
      if (roomId != null) {
        query = query.or('room_id.eq.$roomId,room_id.is.null');
      }

      final data = await query.order('sent_at', ascending: false);
      
      return (data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        map['room_number'] = e['phong']?['room_number'];
        // Sender có thể là tenant hoặc owner, ở đây giả sử khachthue table nếu là tenant
        map['sender_name'] = e['khachthue']?['full_name'];
        return NotificationModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw ServerFailure(message: 'Lỗi tải danh sách thông báo: $e');
    }
  }

  @override
  Future<NotificationModel> sendNotification(NotificationModel notification, {File? imageFile}) async {
    try {
      String? imageUrl;
      
      if (imageFile != null) {
        final ext = imageFile.path.split('.').last;
        final fileName = '${const Uuid().v4()}.$ext';
        
        await _client.storage.from(AppConstants.bucketAttachments).upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        
        imageUrl = _client.storage.from(AppConstants.bucketAttachments).getPublicUrl(fileName);
      }

      final insertData = notification.toJson();
      if (imageUrl != null) {
        insertData['image_url'] = imageUrl;
      }

      final data = await _client
          .from(AppConstants.tableNotifications)
          .insert(insertData)
          .select()
          .single();

      return NotificationModel.fromJson(data);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi gửi thông báo/sự cố: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from(AppConstants.tableNotifications)
          .update({'status': AppNotificationStatus.read.code})
          .eq('id', notificationId)
          .eq('status', AppNotificationStatus.unread.code); // Only update if unread
    } catch (e) {
      throw ServerFailure(message: 'Lỗi cập nhật trạng thái: $e');
    }
  }

  @override
  Future<void> resolveIssue(String notificationId) async {
    try {
      await _client
          .from(AppConstants.tableNotifications)
          .update({'status': AppNotificationStatus.resolved.code})
          .eq('id', notificationId);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi giải quyết sự cố: $e');
    }
  }
}
