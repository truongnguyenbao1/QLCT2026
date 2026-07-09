// ============================================================
//  main.dart — Entry point của ứng dụng Quản lý Nhà trọ
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // BLoC Observer để debug
  Bloc.observer = AppBlocObserver();

  runApp(const QuanLyNhaTroApp());
}

class QuanLyNhaTroApp extends StatefulWidget {
  const QuanLyNhaTroApp({super.key});

  @override
  State<QuanLyNhaTroApp> createState() => _QuanLyNhaTroAppState();
}

class _QuanLyNhaTroAppState extends State<QuanLyNhaTroApp> {
  late final _authBloc = getIt<AuthBloc>()..add(const AuthCheckSessionEvent());
  late final _router = AppRouter.createRouter(_authBloc);

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
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
    );
  }
}
