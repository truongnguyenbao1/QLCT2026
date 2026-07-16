import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/tenant.dart';
import '../bloc/tenant_bloc.dart';
import '../../../../features/room_management/presentation/bloc/room_bloc.dart';
import '../../../../features/room_management/domain/entities/room.dart';

class TenantSearchDialog extends StatefulWidget {
  final String roomId;

  const TenantSearchDialog({super.key, required this.roomId});

  static Future<bool?> show(BuildContext context, String roomId) {
    final roomBloc = context.read<RoomBloc>();
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: roomBloc,
        child: TenantSearchDialog(roomId: roomId),
      ),
    );
  }

  @override
  State<TenantSearchDialog> createState() => _TenantSearchDialogState();
}

class _TenantSearchDialogState extends State<TenantSearchDialog> {
  final _cccdController = TextEditingController();
  late TenantBloc _tenantBloc;
  String? _propertyId;

  @override
  void initState() {
    super.initState();
    _tenantBloc = getIt<TenantBloc>();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _propertyId = authState.user.propertyId;
    }
  }

  @override
  void dispose() {
    _cccdController.dispose();
    _tenantBloc.close(); 
    super.dispose();
  }

  void _search() {
    final cccd = _cccdController.text.trim();
    if (cccd.isEmpty) return;
    _tenantBloc.add(FindTenantByCccdEvent(cccd, propertyId: _propertyId));
  }

  void _addToRoom(Tenant tenant) {
    // Update tenant with new roomId and isActive = true
    final updatedTenant = tenant.copyWith(roomId: widget.roomId, isActive: true);
    _tenantBloc.add(UpdateTenantEvent(updatedTenant));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider.value(
      value: _tenantBloc,
      child: BlocConsumer<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantOperationSuccess) {
            final roomState = context.read<RoomBloc>().state;
            if (roomState is RoomsLoaded) {
                 final selectedRoom = roomState.rooms.firstWhere((r) => r.id == widget.roomId);
                 if (selectedRoom.status != RoomStatus.occupied) {
                    final updatedRoom = selectedRoom.copyWith(status: RoomStatus.occupied);
                    context.read<RoomBloc>().add(UpdateRoomEvent(updatedRoom));
                 }
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thêm khách thuê vào phòng thành công')),
            );
            context.pop(true); // Close dialog and return true to indicate success
          } else if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return AlertDialog(
            title: const Text('Thêm khách thuê'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tìm khách thuê đã có trong hệ thống bằng CCCD:'),
                const SizedBox(height: 12),
                TextField(
                  controller: _cccdController,
                  decoration: InputDecoration(
                    labelText: 'Số CCCD',
                    hintText: 'Nhập số CCCD...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: state is TenantLoading ? null : _search,
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 16),
                if (state is TenantLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state is TenantSearchNotFound)
                  Column(
                    children: [
                      const Text('Không tìm thấy khách thuê này.', style: TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Thêm khách thuê mới'),
                        onPressed: () {
                          context.pop(); // Close dialog
                          context.push('/tenants/add?roomId=${widget.roomId}');
                        },
                      ),
                    ],
                  )
                else if (state is TenantSearchSuccess)
                  Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(state.tenant.fullName),
                      subtitle: Text(state.tenant.phoneNumber),
                      trailing: FilledButton(
                        onPressed: () => _addToRoom(state.tenant),
                        child: const Text('Thêm'),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Đóng'),
              ),
              if (state is! TenantSearchSuccess)
                TextButton(
                  onPressed: () {
                    context.pop();
                    context.push('/tenants/add?roomId=${widget.roomId}');
                  },
                  child: const Text('Thêm mới'),
                ),
            ],
          );
        },
      ),
    );
  }
}
