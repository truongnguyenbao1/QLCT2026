import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/invoice.dart';
import '../bloc/invoice_bloc.dart';

class InvoiceListPage extends StatelessWidget {
  const InvoiceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvoiceBloc>(
      create: (_) => getIt<InvoiceBloc>()..add(const LoadInvoicesEvent()),
      child: const _InvoiceListView(),
    );
  }
}

class _InvoiceListView extends StatefulWidget {
  const _InvoiceListView();

  @override
  State<_InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<_InvoiceListView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
               await context.push('/invoices/create');
               if (context.mounted) {
                 context.read<InvoiceBloc>().add(const LoadInvoicesEvent());
               }
            },
          ),
          PopupMenuButton<InvoiceStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              context.read<InvoiceBloc>().add(LoadInvoicesEvent(status: status));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tất cả'),
              ),
              ...InvoiceStatus.values.map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text(status.displayName),
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<InvoiceBloc, InvoiceState>(
        builder: (context, state) {
          if (state is InvoicesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InvoiceError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          }
          
          List<Invoice> invoices = [];
          if (state is InvoicesLoaded) {
            invoices = state.invoices;
          } else if (state is InvoiceActionSuccess && state.invoices != null) {
            invoices = state.invoices!;
          }

          if (invoices.isEmpty) {
            return const Center(child: Text('Không có hóa đơn nào.'));
          }

          return ListView.builder(
            itemCount: invoices.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _buildInvoiceCard(context, invoice);
            },
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    final theme = Theme.of(context);
    Color statusColor;
    
    switch (invoice.status) {
      case InvoiceStatus.paid:
        statusColor = Colors.green;
        break;
      case InvoiceStatus.overdue:
        statusColor = Colors.red;
        break;
      case InvoiceStatus.pending:
      case InvoiceStatus.confirmedByOwner:
      case InvoiceStatus.confirmedByTenant:
        statusColor = Colors.orange;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await context.push('/invoices/${invoice.id}');
          if (context.mounted) {
            context.read<InvoiceBloc>().add(const LoadInvoicesEvent());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phòng ${invoice.roomNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      invoice.status.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Kỳ hóa đơn: ${invoice.billingPeriod}', style: theme.textTheme.bodyMedium),
              if (invoice.tenantName != null) ...[
                const SizedBox(height: 4),
                Text('Người thuê: ${invoice.tenantName}', style: theme.textTheme.bodyMedium),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng cộng:', style: theme.textTheme.titleMedium),
                  Text(
                    AppFormatters.formatCurrency(invoice.totalAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
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
}
