// ============================================================
//  main.dart — Entry point của ứng dụng Quản lý Nhà trọ
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/observers/app_bloc_observer.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'shared/navigation/app_router.dart';
import 'shared/theme/app_theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khóa xoay màn hình (portrait only trên mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Khởi tạo Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );



  // Khởi tạo Hive (local cache)
  await Hive.initFlutter();

  // Khởi tạo Local Notifications
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ),
  );

  // Khởi tạo Dependency Injection
  await configureDependencies();

  // Khởi tạo locale data cho intl (DateFormat vi_VN)
  await initializeDateFormatting('vi_VN', null);

  // BLoC Observer để debug
  Bloc.observer = AppBlocObserver();

  runApp(const QuanLyNhaTroApp());
}

class QuanLyNhaTroApp extends StatefulWidget {
  const QuanLyNhaTroApp({super.key});

  @override
  State<QuanLyNhaTroApp> createState() => _QuanLyNhaTroAppState();
}

class _QuanLyNhaTroAppState extends State<QuanLyNhaTroApp> with WidgetsBindingObserver {
  late final _authBloc = getIt<AuthBloc>()..add(const AuthCheckSessionEvent());
  late final _router = AppRouter.createRouter(_authBloc);
  Timer? _inactivityTimer;
  DateTime _lastInteraction = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInactivityTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (DateTime.now().difference(_lastInteraction) >= const Duration(minutes: 5)) {
        final authState = _authBloc.state;
        if (authState is AuthAuthenticated) {
          _authBloc.add(const AuthLogoutEvent());
        }
      }
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    // Kiểm tra mỗi phút thay vì tạo lại Timer liên tục mỗi khi chạm màn hình
    _inactivityTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (DateTime.now().difference(_lastInteraction) >= const Duration(minutes: 5)) {
        final state = _authBloc.state;
        if (state is AuthAuthenticated) {
          _authBloc.add(const AuthLogoutEvent());
        }
      }
    });
  }

  void _handleInteraction([_]) {
    _lastInteraction = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handleInteraction,
        onPointerMove: _handleInteraction,
        onPointerUp: _handleInteraction,
        child: MaterialApp.router(
        title: 'Quản lý Nhà trọ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        builder: (context, child) {
          return MediaQuery(
            // Tắt text scaling để UI không bị vỡ layout
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
      ),
      ),
    );
  }
}
