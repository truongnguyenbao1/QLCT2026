import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/navigation/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../room_management/domain/entities/room.dart';
import '../../../room_management/presentation/bloc/room_bloc.dart';
import '../../domain/entities/invoice.dart';
import '../bloc/invoice_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';

class UtilityManagementPage extends StatelessWidget {
  const UtilityManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final propertyId = authState is AuthAuthenticated
        ? authState.user.propertyId ?? ''
        : '';
        
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoomBloc>(
          create: (_) => getIt<RoomBloc>()..add(LoadRoomsEvent(propertyId)),
        ),
        BlocProvider<InvoiceBloc>(
          create: (_) => getIt<InvoiceBloc>(),
        ),
      ],
      child: const _UtilityManagementView(),
    );
  }
}

class _UtilityManagementView extends StatefulWidget {
  const _UtilityManagementView();

  @override
  State<_UtilityManagementView> createState() => _UtilityManagementViewState();
}

class _UtilityManagementViewState extends State<_UtilityManagementView> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    context.read<InvoiceBloc>().add(LoadInvoicesEvent(month: _selectedMonth, year: _selectedYear));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Điện Nước'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.grey),
                const SizedBox(width: 16),
                const Text('Tháng:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMonth = val);
                      _fetchData();
                    }
                  },
                ),
                const SizedBox(width: 16),
                const Text('Năm:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - 2 + index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text('$year'),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                      _fetchData();
                    }
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: BlocBuilder<RoomBloc, RoomState>(
              builder: (context, roomState) {
                if (roomState is RoomsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (roomState is RoomsLoaded) {
                  final occupiedRooms = roomState.rooms.where((r) => r.status == RoomStatus.occupied).toList();
                  
                  if (occupiedRooms.isEmpty) {
                    return const Center(child: Text('Không có phòng nào đang được thuê.'));
                  }

                  return BlocBuilder<InvoiceBloc, InvoiceState>(
                    builder: (context, invoiceState) {
                      List<Invoice> currentMonthInvoices = [];
                      if (invoiceState is InvoicesLoaded) {
                        currentMonthInvoices = invoiceState.invoices.where((i) => i.month == _selectedMonth && i.year == _selectedYear).toList();
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: occupiedRooms.length,
                        itemBuilder: (context, index) {
                          final room = occupiedRooms[index];
                          final invoice = currentMonthInvoices.where((i) => i.roomId == room.id).firstOrNull;
                          final hasInvoice = invoice != null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasInvoice ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                child: Icon(
                                  hasInvoice ? Icons.check_circle : Icons.warning_amber_rounded,
                                  color: hasInvoice ? Colors.green : Colors.orange,
                                ),
                              ),
                              title: Text('Phòng ${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Phòng đang thuê'),
                              trailing: hasInvoice
                                  ? Text(
                                      AppFormatters.formatCurrency(invoice.totalAmount),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                                    )
                                  : FilledButton.tonal(
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                        minimumSize: const Size(80, 36),
                                      ),
                                      onPressed: () {
                                        context.push('${AppRoutes.createInvoice}?roomId=${room.id}');
                                      },
                                      child: const Text('Chốt sổ'),
                                    ),
                              onTap: hasInvoice ? () {
                                context.push('${AppRoutes.invoiceDetail}/${invoice.id}');
                              } : null,
                            ),
                          );
                        },
                      );
                    },
                  );
                }
                return const Center(child: Text('Lỗi tải danh sách phòng'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
