// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/navigation/app_router.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) {
        final authState = context.read<AuthBloc>().state;
        final propertyId = authState is AuthAuthenticated
            ? authState.user.propertyId ?? ''
            : '';
        return getIt<DashboardBloc>()..add(LoadDashboardEvent(propertyId));
      },
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Tổng quan'),
            centerTitle: false,
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                tooltip: 'Thông báo',
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading || state is DashboardInitial) {
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
            ),
          ),
        ],
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
            'Xin chào, Chủ trọ 👋',
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
