import 'dart:developer';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
}

class NotificationService {
  // Pattern Singleton để gọi từ mọi nơi
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }

      // 1. Xin quyền người dùng (Hiển thị popup hỏi quyền trên iOS / Android 13+)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (!kIsWeb) {
        // Khởi tạo Local Notifications
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings iosSettings =
            DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        await _localNotifications.initialize(
          const InitializationSettings(
            android: androidSettings,
            iOS: iosSettings,
          ),
        );

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // name
          description: 'This channel is used for important notifications.', // description
          importance: Importance.high,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          log('Got a message whilst in the foreground!');
          if (message.notification != null) {
            _showNotification(message, channel);
          }
        });
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('User granted permission for notifications');
        
        // 2. Lấy FCM Token
        try {
          String? token;
          if (kIsWeb) {
            token = await _firebaseMessaging.getToken(
                vapidKey: 'BAupebeapkVf7NrWtKB-FVfk6z9r65D_PkSJecPMJ-6LkM6xhlhNM6FCKSj3sNUuRDeYM0tYlJasIo45d8v0Vjg');
          } else {
            token = await _firebaseMessaging.getToken();
          }

          if (token != null) {
            log('FCM Token: $token');
            await _saveTokenToSupabase(token);
          }
        } catch (e) {
          log('Lỗi khi lấy FCM Token: $e');
        }

        // Lắng nghe khi token thay đổi
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _saveTokenToSupabase(newToken);
        }).onError((e) {
          log('Lỗi khi refresh FCM Token: $e');
        });
        
      } else {
        log('User declined or has not accepted permission');
      }
    } catch (e) {
      log('Lỗi khi khởi tạo NotificationService: $e');
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

  void _showNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}

