// lib/features/tenant_management/presentation/pages/tenant_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/navigation/app_router.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/tenant.dart';
import '../bloc/tenant_bloc.dart';

class TenantListPage extends StatelessWidget {
  const TenantListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.user.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Truy cập bị từ chối')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gpp_bad_rounded, size: 72, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Quyền truy cập bị từ chối',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Chức năng này chỉ dành cho chủ trọ/admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => getIt<TenantBloc>()
        ..add(LoadTenantsEvent(propertyId: authState.user.propertyId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Khách thuê'),
          centerTitle: true,
        ),
        body: BlocConsumer<TenantBloc, TenantState>(
          listener: (context, state) {
            if (state is TenantOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<TenantBloc>().add(LoadTenantsEvent(propertyId: authState.user.propertyId));
              }
            } else if (state is TenantError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is TenantLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TenantError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<TenantBloc>().add(const LoadTenantsEvent()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            if (state is TenantLoaded && state.tenants.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có khách thuê nào',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.addTenant),
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Thêm khách thuê'),
                    ),
                  ],
                ),
              );
            }
            if (state is TenantLoaded || state is TenantOperationSuccess && context.read<TenantBloc>().state is TenantLoaded) {
              // Retrieve tenants from the previous state if needed, but BlocConsumer will rebuild if we emit loaded soon.
              // Wait, since we are doing a LoadTenantsEvent, it will go to TenantLoading soon. But just in case:
              final currentState = context.read<TenantBloc>().state;
              List<Tenant> tenants = [];
              if (state is TenantLoaded) {
                tenants = state.tenants;
              } else if (currentState is TenantLoaded) {
                tenants = currentState.tenants;
              }

              if (tenants.isEmpty) return const SizedBox.shrink();

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tenants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tenant = tenants[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(tenant.fullName.isNotEmpty ? tenant.fullName[0].toUpperCase() : '?'),
                      ),
                      title: Text(tenant.fullName),
                      subtitle: Text('Phòng: ${tenant.roomId}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(tenant.isActive ? 'Đang thuê' : 'Đã rời'),
                            backgroundColor: tenant.isActive
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: tenant.isActive ? Colors.green : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                context.push(
                                  AppRoutes.editTenant.replaceFirst(':tenantId', tenant.id),
                                );
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
                        ],
                      ),
                      onTap: () => context.push(
                        AppRoutes.editTenant.replaceFirst(':tenantId', tenant.id),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.addTenant),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Thêm khách thuê'),
        ),
      ),
    );
  }
}
