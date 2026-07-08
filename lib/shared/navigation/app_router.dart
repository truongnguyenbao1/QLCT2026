// lib/shared/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/privacy_policy_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/room_management/presentation/pages/rooms_list_page.dart';
import '../../features/room_management/presentation/pages/add_edit_room_page.dart';
import '../../features/room_management/presentation/pages/room_detail_page.dart';
import '../../features/tenant_management/presentation/pages/tenant_list_page.dart';
import '../../features/tenant_management/presentation/pages/add_edit_tenant_page.dart';
import '../../features/invoice/presentation/pages/invoice_list_page.dart';
import '../../features/invoice/presentation/pages/create_invoice_page.dart';
import '../../features/invoice/presentation/pages/invoice_detail_page.dart';
import '../../features/invoice/presentation/pages/payment_page.dart';

// ── Route Name Constants ──────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String privacyPolicy = '/privacy-policy';
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
}

class AppRouter {
  static GoRouter router(AuthState authState) {
    return GoRouter(
      initialLocation: AppRoutes.dashboard,
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final isLoggedIn = authState is AuthAuthenticated;
        final isLoginPage = state.matchedLocation == AppRoutes.login;
        final isPrivacyPage =
            state.matchedLocation == AppRoutes.privacyPolicy;

        // Chưa đăng nhập → chuyển đến login
        if (!isLoggedIn && !isLoginPage && !isPrivacyPage) {
          return AppRoutes.login;
        }

        // Đã đăng nhập mà vào login → chuyển về dashboard
        if (isLoggedIn && isLoginPage) {
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
          path: AppRoutes.privacyPolicy,
          name: 'privacyPolicy',
          builder: (context, state) => const PrivacyPolicyPage(),
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
                  builder: (context, state) => const AddEditRoomPage(),
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
                        return AddEditRoomPage(roomId: roomId);
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
                    return CreateInvoicePage(roomId: roomId);
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
                        return PaymentPage(invoiceId: invoiceId);
                      },
                    ),
                  ],
                ),
              ],
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
      icon: Icons.receipt_long_rounded,
      label: 'Hóa đơn',
      route: AppRoutes.invoices,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getCurrentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(_navItems[index].route);
        },
        destinations: _navItems
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
    if (location.startsWith(AppRoutes.invoices)) return 3;
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
