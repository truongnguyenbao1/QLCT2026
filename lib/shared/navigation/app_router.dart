// lib/shared/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/privacy_policy_page.dart';
import '../../features/auth/presentation/pages/setup_property_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'dart:async';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/room_management/presentation/pages/rooms_list_page.dart';
import '../../features/room_management/presentation/pages/add_edit_room_page.dart';
import '../../features/room_management/presentation/pages/room_detail_page.dart';
import '../../features/room_management/presentation/bloc/room_bloc.dart';
import '../../features/tenant_management/presentation/pages/tenant_list_page.dart';
import '../../features/tenant_management/presentation/pages/add_edit_tenant_page.dart';
import '../../features/invoice/presentation/pages/invoice_list_page.dart';
import '../../features/invoice/domain/entities/invoice.dart';
import '../../features/invoice/presentation/pages/add_edit_invoice_page.dart';
import '../../features/invoice/presentation/pages/invoice_detail_page.dart';
import '../../features/invoice/presentation/pages/payment_page.dart';
import '../../features/invoice/presentation/pages/utility_management_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/edit_profile_page.dart';
import '../../features/payment_settings/presentation/pages/payment_settings_page.dart';
import '../../features/payment_settings/presentation/bloc/payment_settings_bloc.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';

// ── Route Name Constants ──────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String privacyPolicy = '/privacy-policy';
  static const String setupProperty = '/setup-property';
  static const String dashboard = '/dashboard';
  static const String rooms = '/rooms';
  static const String addRoom = '/rooms/add';
  static const String editRoom = '/rooms/:roomId/edit';
  static const String roomDetail = '/rooms/:roomId';
  static const String tenants = '/tenants';
  static const String addTenant = '/tenants/add';
  static const String editTenant = '/tenants/:tenantId/edit';
  static const String invoices = '/invoices';
  static const String createInvoice = '/invoices/create';
  static const String invoiceDetail = '/invoices/:invoiceId';
  static const String payment = '/invoices/:invoiceId/payment';
  static const String utilities = '/utilities';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String paymentSettings = '/profile/payment-settings';
  static const String notifications = '/notifications';
}

// ── GoRouter Refresh Stream ───────────────────────────────────────────────
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: AppRoutes.dashboard,
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isLoggedIn = authState is AuthAuthenticated;
        final isLoginPage = state.matchedLocation == AppRoutes.login;
        final isRegisterPage = state.matchedLocation == AppRoutes.register;
        final isPrivacyPage =
            state.matchedLocation == AppRoutes.privacyPolicy;

        // Nếu đang kiểm tra phiên đăng nhập thì không redirect vội
        if (authState is AuthInitial || authState is AuthLoading) {
          return null;
        }

        final isSetupPage = state.matchedLocation == AppRoutes.setupProperty;

        // Cần đồng ý điều khoản nhưng lại chưa ở trang privacy
        if (authState is AuthNeedPrivacyAcceptance && !isPrivacyPage) {
          return AppRoutes.privacyPolicy;
        }

        // Cần hoàn thiện profile (đăng nhập Google lần đầu)
        if (authState is AuthNeedProfileCompletion && !isRegisterPage) {
          return '${AppRoutes.register}?email=${Uri.encodeComponent(authState.email)}&fullName=${Uri.encodeComponent(authState.fullName)}';
        }

        // Chủ trọ chưa đăng ký dãy trọ
        if (authState is AuthNeedPropertySetup && !isSetupPage) {
          return AppRoutes.setupProperty;
        }

        // Chưa đăng nhập → chuyển đến login (trừ trang register)
        if (!isLoggedIn && !isLoginPage && !isRegisterPage && authState is! AuthNeedPrivacyAcceptance && authState is! AuthNeedPropertySetup && authState is! AuthNeedProfileCompletion) {
          return AppRoutes.login;
        }

        // Đã đăng nhập mà vào login, register hoặc privacy → chuyển về dashboard
        if (isLoggedIn && (isLoginPage || isRegisterPage || isPrivacyPage || isSetupPage)) {
          return AppRoutes.dashboard;
        }

        return null;
      },
      routes: [
        // ── Auth Routes ─────────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'];
            final fullName = state.uri.queryParameters['fullName'];
            return RegisterPage(
              initialEmail: email,
              initialFullName: fullName,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.privacyPolicy,
          name: 'privacyPolicy',
          builder: (context, state) => const PrivacyPolicyPage(),
        ),
        GoRoute(
          path: AppRoutes.setupProperty,
          name: 'setupProperty',
          builder: (context, state) => const SetupPropertyPage(),
        ),

        // ── Main Shell (Bottom Nav) ──────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            // Dashboard
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              builder: (context, state) => const DashboardPage(),
            ),

// Rooms
            GoRoute(
              path: AppRoutes.rooms,
              name: 'rooms',
              builder: (context, state) => const RoomsListPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'addRoom',
                  builder: (context, state) {
                    final authState = context.read<AuthBloc>().state;
                    final propertyId = authState is AuthAuthenticated
                        ? authState.user.propertyId ?? ''
                        : '';
                    return BlocProvider<RoomBloc>(
                      create: (_) => getIt<RoomBloc>()..add(LoadRoomsEvent(propertyId)),
                      child: const AddEditRoomPage(),
                    );
                  },
                ),
                GoRoute(
                  path: ':roomId',
                  name: 'roomDetail',
                  builder: (context, state) {
                    final roomId = state.pathParameters['roomId']!;
                    return RoomDetailPage(roomId: roomId);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'editRoom',
                      builder: (context, state) {
                        final roomId = state.pathParameters['roomId']!;
                        final authState = context.read<AuthBloc>().state;
                        final propertyId = authState is AuthAuthenticated
                            ? authState.user.propertyId ?? ''
                            : '';
                        return BlocProvider<RoomBloc>(
                          create: (_) => getIt<RoomBloc>()..add(LoadRoomsEvent(propertyId)),
                          child: AddEditRoomPage(roomId: roomId),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Tenants
            GoRoute(
              path: AppRoutes.tenants,
              name: 'tenants',
              builder: (context, state) => const TenantListPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'addTenant',
                  builder: (context, state) {
                    final roomId = state.uri.queryParameters['roomId'];
                    return AddEditTenantPage(roomId: roomId);
                  },
                ),
                GoRoute(
                  path: ':tenantId/edit',
                  name: 'editTenant',
                  builder: (context, state) {
                    final tenantId = state.pathParameters['tenantId']!;
                    return AddEditTenantPage(tenantId: tenantId);
                  },
                ),
              ],
            ),

            // Invoices
            GoRoute(
              path: AppRoutes.invoices,
              name: 'invoices',
              builder: (context, state) => const InvoiceListPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: 'createInvoice',
                  builder: (context, state) {
                    final roomId = state.uri.queryParameters['roomId'];
                    return AddEditInvoicePage(roomId: roomId);
                  },
                ),
                GoRoute(
                  path: ':invoiceId',
                  name: 'invoiceDetail',
                  builder: (context, state) {
                    final invoiceId = state.pathParameters['invoiceId']!;
                    return InvoiceDetailPage(invoiceId: invoiceId);
                  },
                  routes: [
                    GoRoute(
                      path: 'payment',
                      name: 'payment',
                      builder: (context, state) {
                        final invoiceId = state.pathParameters['invoiceId']!;
                        return BlocProvider<PaymentSettingsBloc>(
                          create: (_) => getIt<PaymentSettingsBloc>(),
                          child: PaymentPage(invoiceId: invoiceId),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'edit',
                      name: 'editInvoice',
                      builder: (context, state) {
                        final invoice = state.extra as Invoice?;
                        return AddEditInvoicePage(invoice: invoice);
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Utilities
            GoRoute(
              path: AppRoutes.utilities,
              name: 'utilities',
              builder: (context, state) => const UtilityManagementPage(),
            ),

            // Profile
            GoRoute(
              path: AppRoutes.profile,
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'editProfile',
                  builder: (context, state) => const EditProfilePage(),
                ),
                GoRoute(
                  path: 'payment-settings',
                  name: 'paymentSettings',
                  builder: (context, state) => BlocProvider<PaymentSettingsBloc>(
                    create: (_) => getIt<PaymentSettingsBloc>(),
                    child: const PaymentSettingsPage(),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.notifications,
              builder: (context, state) => const NotificationsPage(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Trang không tìm thấy: ${state.error}'),
              TextButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main Shell với Bottom Navigation Bar ──────────────────────────────────
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Tổng quan',
      route: AppRoutes.dashboard,
    ),
    _NavItem(
      icon: Icons.meeting_room_rounded,
      label: 'Phòng',
      route: AppRoutes.rooms,
    ),
    _NavItem(
      icon: Icons.people_rounded,
      label: 'Khách thuê',
      route: AppRoutes.tenants,
    ),
    _NavItem(
      icon: Icons.electric_bolt_rounded,
      label: 'Điện nước',
      route: AppRoutes.utilities,
    ),
    _NavItem(
      icon: Icons.receipt_long_rounded,
      label: 'Hóa đơn',
      route: AppRoutes.invoices,
    ),
    _NavItem(
      icon: Icons.person_rounded,
      label: 'Cá nhân',
      route: AppRoutes.profile,
    ),
    _NavItem(
      icon: Icons.notifications_rounded,
      label: 'Thông báo',
      route: AppRoutes.notifications,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final authState = context.watch<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated ? authState.user.isOwner : false;

    // Filter items based on role
    final navItems = _navItems.where((item) {
      if (!isOwner) {
        // Tenants only see Dashboard, Invoices and Profile
        return item.route == AppRoutes.dashboard ||
               item.route == AppRoutes.invoices ||
               item.route == AppRoutes.profile;
      }
      return true;
    }).toList();

    final currentIndex = navItems.indexWhere((item) => location.startsWith(item.route));
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          context.go(navItems[index].route);
        },
        destinations: navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  int _getCurrentIndex(String location) {
    if (location.startsWith(AppRoutes.rooms)) return 1;
    if (location.startsWith(AppRoutes.tenants)) return 2;
    if (location.startsWith(AppRoutes.utilities)) return 3;
    if (location.startsWith(AppRoutes.invoices)) return 4;
    return 0;
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
