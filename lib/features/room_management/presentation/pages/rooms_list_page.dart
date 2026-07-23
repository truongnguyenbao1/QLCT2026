// lib/features/room_management/presentation/pages/rooms_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/room.dart';
import '../bloc/room_bloc.dart';
import '../../../tenant_management/presentation/widgets/tenant_search_dialog.dart';

class RoomsListPage extends StatelessWidget {
  const RoomsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoomBloc>(
      create: (_) {
        final authState = context.read<AuthBloc>().state;
        final propertyId = authState is AuthAuthenticated
            ? authState.user.propertyId ?? ''
            : '';
        return getIt<RoomBloc>()..add(LoadRoomsEvent(propertyId));
      },
      child: const _RoomsListView(),
    );
  }
}

class _RoomsListView extends StatefulWidget {
  const _RoomsListView();

  @override
  State<_RoomsListView> createState() => _RoomsListViewState();
}

class _RoomsListViewState extends State<_RoomsListView> {
  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    final authState = context.read<AuthBloc>().state;
    final propertyId = authState is AuthAuthenticated
        ? authState.user.propertyId ?? ''
        : '';
    final roomState = context.read<RoomBloc>().state;
    if (roomState is RoomInitial) {
      context.read<RoomBloc>().add(LoadRoomsEvent(propertyId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated && authState.user.isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {/* TODO: Search */},
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is AuthAuthenticated) {
            final propertyId = authState.user.propertyId ?? '';
            context.read<RoomBloc>().add(LoadRoomsEvent(propertyId));
          }
        },
        child: BlocConsumer<RoomBloc, RoomState>(
          listener: (context, state) {
            if (state is RoomError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
          } else if (state is RoomActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RoomsLoading || state is RoomInitial) {
            return const Center(child: CircularProgressIndicator());
          }
 
          if (state is RoomsLoaded || state is RoomActionSuccess) {
            final rooms = state is RoomsLoaded
                ? state.filteredRooms
                : (state as RoomActionSuccess).rooms;
            final allRooms = state is RoomsLoaded ? state.rooms : rooms;
            final activeFilter =
                state is RoomsLoaded ? state.activeFilter : null;
 
            return Column(
              children: [
                // ── Stats Row ──────────────────────────────────────────
                if (state is RoomsLoaded)
                  _StatsBar(
                    total: state.rooms.length,
                    empty: state.emptyCount,
                    occupied: state.occupiedCount,
                    maintenance: state.maintenanceCount,
                  ),
 
                // ── Filter Chips ───────────────────────────────────────
                _FilterRow(
                  activeFilter: activeFilter,
                  onFilter: (status) {
                    context.read<RoomBloc>().add(FilterRoomsEvent(status));
                  },
                ),
 
                // ── Room Grid ──────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final authState = context.read<AuthBloc>().state;
                      final propertyId = authState is AuthAuthenticated
                          ? authState.user.propertyId ?? ''
                          : '';
                      context.read<RoomBloc>().add(LoadRoomsEvent(propertyId));
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: rooms.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: _EmptyState(hasRooms: allRooms.isNotEmpty),
                              ),
                            ],
                          )
                        : GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.95,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: rooms.length,
                            itemBuilder: (context, index) {
                              return _RoomCard(room: rooms[index])
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(milliseconds: 50 * index),
                                    duration: 300.ms,
                                  )
                                  .slideY(begin: 0.1);
                            },
                          ),
                  ),
                ),
              ],
            );
          }
 
          return const Center(child: CircularProgressIndicator());
        },
      ),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/rooms/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm phòng'),
            )
          : null,
    );
  }
}

// ── Stats Bar Widget ──────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final int total, empty, occupied, maintenance;
  const _StatsBar({
    required this.total,
    required this.empty,
    required this.occupied,
    required this.maintenance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          _StatChip(count: total, label: 'Tổng', color: AppColors.primary),
          const SizedBox(width: 8),
          _StatChip(
              count: empty, label: 'Trống', color: AppColors.roomEmpty),
          const SizedBox(width: 8),
          _StatChip(
              count: occupied,
              label: 'Đang thuê',
              color: AppColors.roomOccupied),
          const SizedBox(width: 8),
          _StatChip(
              count: maintenance,
              label: 'Bảo trì',
              color: AppColors.roomMaintenance),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatChip(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Row Widget ─────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final RoomStatus? activeFilter;
  final Function(RoomStatus?) onFilter;
  const _FilterRow({required this.activeFilter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
              label: 'Tất cả',
              isActive: activeFilter == null,
              onTap: () => onFilter(null)),
          const SizedBox(width: 8),
          _FilterChip(
              label: '🟢 Còn trống',
              isActive: activeFilter == RoomStatus.empty,
              onTap: () => onFilter(RoomStatus.empty)),
          const SizedBox(width: 8),
          _FilterChip(
              label: '🔵 Đang thuê',
              isActive: activeFilter == RoomStatus.occupied,
              onTap: () => onFilter(RoomStatus.occupied)),
          const SizedBox(width: 8),
          _FilterChip(
              label: '🟠 Bảo trì',
              isActive: activeFilter == RoomStatus.maintenance,
              onTap: () => onFilter(RoomStatus.maintenance)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Room Card Widget ──────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final Room room;
  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(room.status);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () async {
        final authState = context.read<AuthBloc>().state;
        final propertyId = authState is AuthAuthenticated ? authState.user.propertyId ?? '' : '';
        
        if (room.status == RoomStatus.empty) {
          final added = await TenantSearchDialog.show(context, room.id);
          if (added == true && context.mounted) {
            context.read<RoomBloc>().add(LoadRoomsEvent(propertyId));
          }
        } else {
          await context.push('/rooms/${room.id}');
          if (context.mounted) {
            context.read<RoomBloc>().add(LoadRoomsEvent(propertyId));
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status indicator
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.meeting_room_rounded,
                      size: 32,
                      color: statusColor,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        room.status.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onSelected: (value) async {
                        final authState = context.read<AuthBloc>().state;
                        final propertyId = authState is AuthAuthenticated ? authState.user.propertyId ?? '' : '';

                        if (value == 'edit') {
                          await context.push('/rooms/${room.id}/edit');
                          if (context.mounted) {
                            context.read<RoomBloc>().add(LoadRoomsEvent(propertyId));
                          }
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: Text('Bạn có chắc chắn muốn xóa phòng ${room.roomNumber} không?'),
                              actions: [
                                TextButton(onPressed: () => context.pop(false), child: const Text('Hủy')),
                                FilledButton(
                                  onPressed: () => context.pop(true),
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            context.read<RoomBloc>().add(DeleteRoomEvent(room.id));
                          }
                        } else if (value == 'checkout') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận trả phòng'),
                              content: const Text('Bạn có chắc chắn muốn trả phòng này? Trạng thái phòng sẽ thành "Còn trống" và tất cả khách thuê hiện tại sẽ được đánh dấu là "Đã trả phòng".'),
                              actions: [
                                TextButton(onPressed: () => context.pop(false), child: const Text('Hủy')),
                                FilledButton(
                                  onPressed: () => context.pop(true),
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Trả phòng'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            // Update room status to empty
                            final updatedRoom = room.copyWith(status: RoomStatus.empty);
                            context.read<RoomBloc>().add(UpdateRoomEvent(updatedRoom));
                            
                            // Set all tenants in this room to inactive directly via SupabaseClient
                            try {
                               await getIt<SupabaseClient>()
                                  .from('khachthue')
                                  .update({'is_active': false, 'room_id': null})
                                  .eq('room_id', room.id);
                                  
                               // Cập nhật hợp đồng (thuephong) thành đã kết thúc
                               await getIt<SupabaseClient>()
                                  .from('thuephong')
                                  .update({
                                    'status': 'TERMINATED',
                                    'end_date': DateTime.now().toIso8601String(),
                                  })
                                  .eq('room_id', room.id)
                                  .eq('status', 'ACTIVE');
                            } catch (_) {}
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit_rounded, size: 20), SizedBox(width: 8), Text('Sửa')]),
                        ),
                        const PopupMenuItem(
                          value: 'checkout',
                          child: Row(children: [Icon(Icons.logout_rounded, size: 20, color: Colors.orange), SizedBox(width: 8), Text('Trả phòng', style: TextStyle(color: Colors.orange))]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete_rounded, size: 20, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phòng ${room.roomNumber}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatCurrency(room.rentPrice),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.straighten, size: 11,
                          color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          AppFormatters.formatArea(room.area),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.layers_rounded, size: 11,
                          color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        room.floor != null ? 'T${room.floor}' : 'Trệt',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.empty:
        return AppColors.roomEmpty;
      case RoomStatus.occupied:
        return AppColors.roomOccupied;
      case RoomStatus.maintenance:
        return AppColors.roomMaintenance;
    }
  }
}

// ── Empty State Widget ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasRooms;
  const _EmptyState({required this.hasRooms});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasRooms
                ? Icons.filter_alt_off_rounded
                : Icons.home_work_outlined,
            size: 72,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            hasRooms ? 'Không có phòng nào với bộ lọc này' : 'Chưa có phòng nào',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (!hasRooms) ...[
            const SizedBox(height: 8),
            Text(
              'Nhấn nút + để thêm phòng đầu tiên',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
