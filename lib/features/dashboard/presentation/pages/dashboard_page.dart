// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../shared/navigation/app_router.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../../features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../widgets/notification_bell.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) {
        return getIt<DashboardBloc>();
      },
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated ? authState.user.isOwner : false;
    final propertyId = authState is AuthAuthenticated ? authState.user.propertyId ?? '' : '';

    if (isOwner) {
      context.read<DashboardBloc>().add(LoadDashboardEvent(propertyId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated ? authState.user.isOwner : false;
    final userName = authState is AuthAuthenticated ? authState.user.fullName : '';

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated && state.user.isOwner) {
            final dashState = context.read<DashboardBloc>().state;
            if (dashState is DashboardInitial) {
              context.read<DashboardBloc>().add(
                LoadDashboardEvent(state.user.propertyId ?? ''),
              );
            }
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Tổng quan'),
              centerTitle: false,
              floating: true,
            actions: [
              if (authState is AuthAuthenticated)
                NotificationBell(userId: authState.user.id),

              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutEvent());
                },
                tooltip: 'Đăng xuất',
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: isOwner
                ? BlocBuilder<DashboardBloc, DashboardState>(
                    builder: (context, state) {
                      if (state is DashboardLoading ||
                          state is DashboardInitial) {
                        return const _DashboardSkeleton();
                      }
                      if (state is DashboardError) {
                        return _DashboardError(
                          message: state.message,
                          onRetry: () {
                            final authState = context.read<AuthBloc>().state;
                            final propertyId = authState is AuthAuthenticated
                                ? authState.user.propertyId ?? ''
                                : '';
                            context
                                .read<DashboardBloc>()
                                .add(LoadDashboardEvent(propertyId));
                          },
                        );
                      }
                      if (state is DashboardLoaded) {
                        return _DashboardContent(stats: state.stats);
                      }
                      return const _DashboardEmpty();
                    },
                  )
                : _TenantDashboardContent(user: authState is AuthAuthenticated ? authState.user : null),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Content khi có dữ liệu ───────────────────────────────────────────────
class _DashboardContent extends StatelessWidget {
  final dynamic stats;
  const _DashboardContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header greeting
          Text(
            'Xin chào, Chủ trọ!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đây là tóm tắt hoạt động của bạn hôm nay',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Stats cards
          _StatCard(
            icon: Icons.home_work_rounded,
            label: 'Tổng phòng',
            value: '${stats.totalRooms}',
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.meeting_room_rounded,
                  label: 'Đang thuê',
                  value: '${stats.occupiedRooms}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.door_front_door_rounded,
                  label: 'Còn trống',
                  value: '${stats.emptyRooms}',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.attach_money_rounded,
            label: 'Doanh thu tháng này',
            value: AppFormatters.formatCurrency(stats.monthlyRevenue),
            color: Colors.green,
            large: true,
          ),
          const SizedBox(height: 32),

          // Quick actions
          Text(
            'Thao tác nhanh',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickAction(
                icon: Icons.add_home_rounded,
                label: 'Thêm phòng',
                onTap: () => context.push(AppRoutes.addRoom),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.person_add_rounded,
                label: 'Thêm khách',
                onTap: () => context.push(AppRoutes.addTenant),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.receipt_long_rounded,
                label: 'Tạo hóa đơn',
                onTap: () => context.push(AppRoutes.createInvoice),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool large;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Text(
                  value,
                  style: large
                      ? theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)
                      : theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Chưa có dữ liệu'),
        ],
      ),
    );
  }
}

// ── Dashboard cho Khách Thuê (Tenant) ───────────────────────────────────
class _TenantDashboardContent extends StatefulWidget {
  final AppUser? user;
  const _TenantDashboardContent({required this.user});

  @override
  State<_TenantDashboardContent> createState() => _TenantDashboardContentState();
}

class _TenantDashboardContentState extends State<_TenantDashboardContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _propertyName = 'Đang tải...';
  String _roomName = 'Đang tải...';
  bool _isLoadingInfo = true;

  final List<Color> _bannerColors = [
    const Color(0xFF4285F4),
    const Color(0xFF34A853),
    const Color(0xFFFBBC05),
  ];

  @override
  void initState() {
    super.initState();
    // Tự động cuộn banner mỗi 3 giây
    Future.delayed(const Duration(seconds: 3), _autoScrollBanner);
    _loadTenantInfo();
  }

  Future<void> _loadTenantInfo() async {
    if (widget.user == null || widget.user!.roomId == null) {
      setState(() {
        _propertyName = 'Chưa xếp phòng';
        _roomName = 'Chưa có';
        _isLoadingInfo = false;
      });
      return;
    }

    try {
      final client = getIt<SupabaseClient>();
      
      // Fetch room and property info
      final roomData = await client
          .from('phong')
          .select('room_number, floor, property_id')
          .eq('id', widget.user!.roomId!)
          .maybeSingle();

      if (roomData != null) {
        final roomNumber = roomData['room_number'];
        final floor = roomData['floor'];
        _roomName = 'Phòng $roomNumber - T$floor';

        final propertyId = widget.user!.propertyId ?? roomData['property_id'];
        if (propertyId != null) {
          final propData = await client
              .from('nhatro')
              .select('name')
              .eq('id', propertyId)
              .maybeSingle();
          if (propData != null) {
            _propertyName = propData['name'] as String;
          } else {
            _propertyName = 'Nhà trọ không xác định';
          }
        }
      } else {
        _propertyName = 'Chưa rõ';
        _roomName = 'Không tìm thấy phòng';
      }
    } catch (e) {
      _propertyName = 'Lỗi tải dữ liệu';
      _roomName = 'Lỗi tải dữ liệu';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInfo = false;
        });
      }
    }
  }

  void _autoScrollBanner() {
    if (!mounted) return;
    if (_pageController.hasClients) {
      final nextPage = (_currentPage + 1) % _bannerColors.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    Future.delayed(const Duration(seconds: 3), _autoScrollBanner);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào, ${widget.user?.fullName ?? 'Khách thuê'} 👋',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chúc bạn một ngày tốt lành!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          
          // Card thông tin nhà trọ
          if (!_isLoadingInfo)
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.home_work_rounded, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _propertyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bạn đang ở: $_roomName',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Banner Carousel
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _bannerColors.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _bannerColors[index],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.campaign_rounded, color: Colors.white, size: 80),
                      ),
                    );
                  },
                ),
                // Indicators
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _bannerColors.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Phần thông báo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông báo quan trọng',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mock Notifications
          _NotificationCard(
            icon: Icons.receipt_long_rounded,
            iconColor: Colors.orange,
            title: 'Đã có hóa đơn tháng mới',
            time: '2 giờ trước',
            onTap: () {
              context.push(AppRoutes.invoices);
            },
          ),
          const SizedBox(height: 12),
          _NotificationCard(
            icon: Icons.cleaning_services_rounded,
            iconColor: Colors.blue,
            title: 'Lịch dọn dẹp vệ sinh chung',
            time: 'Hôm qua',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _NotificationCard(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.green,
            title: 'Quy định mới về giờ giấc',
            time: 'Tuần trước',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
