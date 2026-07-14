import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/room.dart';
import '../bloc/room_bloc.dart';

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
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Phòng ${room.roomNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
               context.go('/rooms/${room.id}/edit');
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
            _buildInfoCard(theme, room),
            const SizedBox(height: 16),
            _buildCostCard(theme, room),
            const SizedBox(height: 16),
            if (room.amenities.isNotEmpty) _buildAmenitiesCard(theme, room),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                   // Navigate to add tenant
                   context.go('/tenants/add?roomId=${room.id}');
                },
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Thêm người thuê'),
              ),
            ),
          ],
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
}
