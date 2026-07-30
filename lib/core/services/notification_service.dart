import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  // Pattern Singleton để gọi từ mọi nơi
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    // 1. Xin quyền người dùng (Hiển thị popup hỏi quyền trên iOS / Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission for notifications');
      
      // 2. Lấy FCM Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        log('FCM Token: $token');
        await _saveTokenToSupabase(token);
      }

      // Lắng nghe khi token thay đổi (ví dụ cài lại app hoặc server firebase thay đổi token)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToSupabase(newToken);
      });
      
    } else {
      log('User declined or has not accepted permission');
    }
  }

  // 3. Hàm lưu Token lên Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase
            .from('users')
            .update({'fcm_token': token})
            .eq('iduser', user.id);
        log('Lưu FCM Token lên Supabase thành công!');
      } catch (e) {
        log('Lỗi lưu FCM Token lên Supabase: $e');
      }
    } else {
      log('User chưa đăng nhập, bỏ qua lưu token.');
    }
  }
}
