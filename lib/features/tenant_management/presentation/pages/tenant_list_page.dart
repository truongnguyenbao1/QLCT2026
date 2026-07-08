// lib/features/tenant_management/presentation/pages/tenant_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/navigation/app_router.dart';
import '../bloc/tenant_bloc.dart';

class TenantListPage extends StatelessWidget {
  const TenantListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TenantBloc>()..add(const LoadTenantsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Khách thuê'),
          centerTitle: true,
        ),
        body: BlocBuilder<TenantBloc, TenantState>(
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
            if (state is TenantLoaded) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.tenants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tenant = state.tenants[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(tenant.fullName[0].toUpperCase()),
                      ),
                      title: Text(tenant.fullName),
                      subtitle: Text('Phòng: ${tenant.roomId}'),
                      trailing: Chip(
                        label: Text(tenant.isActive ? 'Đang thuê' : 'Đã rời'),
                        backgroundColor: tenant.isActive
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: tenant.isActive ? Colors.green : Colors.grey,
                          fontSize: 12,
                        ),
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
