import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/room_management/presentation/bloc/room_bloc.dart';
import '../bloc/tenant_bloc.dart';
import 'tenant_search_dialog.dart';

class RoomTenantsDialog extends StatefulWidget {
  final String roomId;
  final String roomNumber;

  const RoomTenantsDialog({
    super.key,
    required this.roomId,
    required this.roomNumber,
  });

  static Future<void> show(BuildContext context, String roomId, String roomNumber) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => RoomTenantsDialog(
        roomId: roomId,
        roomNumber: roomNumber,
      ),
    );
  }

  @override
  State<RoomTenantsDialog> createState() => _RoomTenantsDialogState();
}

class _RoomTenantsDialogState extends State<RoomTenantsDialog> {
  late TenantBloc _tenantBloc;
  String? _propertyId;

  @override
  void initState() {
    super.initState();
    _tenantBloc = getIt<TenantBloc>();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _propertyId = authState.user.propertyId;
      _loadTenants();
    }
  }

  void _loadTenants() {
    _tenantBloc.add(LoadTenantsEvent(
      roomId: widget.roomId,
      propertyId: _propertyId,
      isActive: true,
    ));
  }

  @override
  void dispose() {
    _tenantBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _tenantBloc,
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Thành viên phòng ${widget.roomNumber}'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
        contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
        content: SizedBox(
          width: double.maxFinite,
          child: BlocConsumer<TenantBloc, TenantState>(
            listener: (context, state) {
              if (state is TenantOperationSuccess) {
                _loadTenants();
              } else if (state is TenantError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is TenantLoading) {
                return const Center(
                  heightFactor: 3,
                  child: CircularProgressIndicator(),
                );
              }
              
              if (state is TenantLoaded) {
                final tenants = state.tenants;
                if (tenants.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Chưa có thông tin khách thuê',
                      style: TextStyle(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: tenants.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tenant = tenants[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          tenant.fullName.isNotEmpty ? tenant.fullName[0].toUpperCase() : '?',
                          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                      title: Text(
                        tenant.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'CCCD: ${tenant.cccdNumber}',
                                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(tenant.phoneNumber),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            context.pop(); // close dialog first to go to edit page
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
                              _tenantBloc.add(DeleteTenantEvent(tenant.id));
                              // RoomBloc check to set empty if it's the last tenant is complex from here without room reference
                              // but TenantBloc state update will reload list.
                              // For simplicity, we just reload tenants in this dialog.
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
                    );
                  },
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              context.push('/rooms/${widget.roomId}');
            },
            child: const Text('Chi tiết phòng'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final added = await TenantSearchDialog.show(context, widget.roomId);
              if (added == true && context.mounted) {
                _loadTenants();
                // We should also notify RoomBloc to reload in case status changed, 
                // but since it's already occupied, status likely won't change.
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                   context.read<RoomBloc>().add(LoadRoomsEvent(authState.user.propertyId ?? ''));
                }
              }
            },
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Thêm khách'),
          ),
        ],
      ),
    );
  }
}
