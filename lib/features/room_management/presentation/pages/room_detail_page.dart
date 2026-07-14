import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/room.dart';
import '../bloc/room_bloc.dart';
import '../../../tenant_management/presentation/bloc/tenant_bloc.dart';
import '../../../tenant_management/domain/entities/tenant.dart';
import '../../../tenant_management/presentation/widgets/tenant_search_dialog.dart';

class RoomDetailPage extends StatelessWidget {
  final String roomId;

  const RoomDetailPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        if (state is RoomsLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is RoomsLoaded) {
          final room = state.rooms.firstWhere(
            (r) => r.id == roomId,
            orElse: () => throw Exception('Không tìm thấy phòng'),
          );
          return _buildRoomDetail(context, room);
        }
        
        // Handle cases where state might be action success but we still want to show UI
        if (state is RoomActionSuccess) {
           final room = state.rooms.firstWhere(
            (r) => r.id == roomId,
            orElse: () => throw Exception('Không tìm thấy phòng'),
          );
          return _buildRoomDetail(context, room);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Lỗi')),
          body: const Center(child: Text('Không thể tải dữ liệu phòng.')),
        );
      },
    );
  }

  Widget _buildRoomDetail(BuildContext context, Room room) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    final propertyId = authState is AuthAuthenticated ? authState.user.propertyId ?? '' : '';
    
    return BlocProvider(
      create: (context) => getIt<TenantBloc>()..add(LoadTenantsEvent(roomId: room.id, propertyId: propertyId, isActive: true)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Phòng ${room.roomNumber}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                 await context.push('/rooms/${room.id}/edit');
                 if (context.mounted) {
                   context.read<RoomBloc>().add(LoadRoomsEvent(propertyId));
                 }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(theme, room),
              const SizedBox(height: 16),
              if (room.status == RoomStatus.occupied) ...[
                _buildTenantsCard(theme, room),
                const SizedBox(height: 16),
              ],
              _buildInfoCard(theme, room),
              const SizedBox(height: 16),
              _buildCostCard(theme, room),
              const SizedBox(height: 16),
              if (room.amenities.isNotEmpty) _buildAmenitiesCard(theme, room),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                         await context.push('/rooms/${room.id}/edit');
                         if (context.mounted) {
                           context.read<RoomBloc>().add(LoadRoomsEvent(propertyId));
                         }
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Sửa phòng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final added = await TenantSearchDialog.show(context, room.id);
                        if (added == true && context.mounted) {
                          context.read<RoomBloc>().add(LoadRoomsEvent(propertyId));
                          context.read<TenantBloc>().add(LoadTenantsEvent(roomId: room.id, propertyId: propertyId, isActive: true));
                        }
                      },
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Thêm khách'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, Room room) {
    Color statusColor;
    IconData statusIcon;
    
    switch (room.status) {
      case RoomStatus.empty:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case RoomStatus.occupied:
        statusColor = Colors.orange;
        statusIcon = Icons.people_outline;
        break;
      case RoomStatus.maintenance:
        statusColor = Colors.red;
        statusIcon = Icons.build_circle_outlined;
        break;
    }

    return Card(
      elevation: 0,
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.status.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, Room room) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin cơ bản', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildDetailRow('Tầng', '${room.floor}'),
            const SizedBox(height: 12),
            _buildDetailRow('Diện tích', '${room.area} m²'),
            const SizedBox(height: 12),
            _buildDetailRow('Số người tối đa', room.maxOccupants != null ? '${room.maxOccupants} người' : 'Không giới hạn'),
            if (room.description != null && room.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Mô tả', room.description!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(ThemeData theme, Room room) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi phí', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildDetailRow('Giá thuê', '${AppFormatters.formatCurrency(room.rentPrice)}/tháng'),
            const SizedBox(height: 8),
            _buildDetailRow('Giá điện', '${AppFormatters.formatCurrency(room.electricPrice)}/kWh'),
            const SizedBox(height: 8),
            _buildDetailRow('Giá nước', '${AppFormatters.formatCurrency(room.waterPrice)}/m³'),
            const SizedBox(height: 8),
            _buildDetailRow('Phí dịch vụ', '${AppFormatters.formatCurrency(room.servicePrice)}/tháng'),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesCard(ThemeData theme, Room room) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiện ích', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: room.amenities.map((amenity) => Chip(
                label: Text(amenity),
                backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTenantsCard(ThemeData theme, Room room) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Khách thuê hiện tại', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary),
              ],
            ),
            const Divider(height: 24),
            BlocBuilder<TenantBloc, TenantState>(
              builder: (context, state) {
                if (state is TenantLoading) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (state is TenantError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                }
                if (state is TenantLoaded) {
                  final tenants = state.tenants;
                  if (tenants.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Chưa có thông tin khách thuê', style: TextStyle(fontStyle: FontStyle.italic)),
                    );
                  }
                  
                  return Column(
                    children: tenants.map((tenant) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(tenant.fullName.isNotEmpty ? tenant.fullName[0].toUpperCase() : '?', style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
                      ),
                      title: Text(tenant.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(tenant.phoneNumber),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            context.push('/tenants/${tenant.id}/edit');
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: Text('Bạn có chắc chắn muốn xóa khách thuê ${tenant.fullName} không?'),
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
                              context.read<TenantBloc>().add(DeleteTenantEvent(tenant.id));
                              // Also reload rooms to update counts/stats if needed
                              final authState = context.read<AuthBloc>().state;
                              if (authState is AuthAuthenticated) {
                                context.read<RoomBloc>().add(LoadRoomsEvent(authState.user.propertyId ?? ''));
                                // Since we are in RoomDetailPage, we should also reload tenants for this room after deletion
                                // TenantBloc will emit TenantOperationSuccess, but we need it to reload.
                                // Instead of a full BlocConsumer here, we can just fire LoadTenantsEvent
                                context.read<TenantBloc>().add(LoadTenantsEvent(roomId: room.id, propertyId: authState.user.propertyId, isActive: true));
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [Icon(Icons.edit_rounded, size: 20), SizedBox(width: 8), Text('Sửa')]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [Icon(Icons.delete_rounded, size: 20, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))]),
                          ),
                        ],
                      ),
                    )).toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
