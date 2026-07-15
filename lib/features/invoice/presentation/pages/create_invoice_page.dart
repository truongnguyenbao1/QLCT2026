import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/invoice.dart';
import '../bloc/invoice_bloc.dart';
import '../../../room_management/domain/entities/room.dart';
import '../../../room_management/presentation/bloc/room_bloc.dart';
import '../../../../core/utils/formatters.dart';

import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';

class CreateInvoicePage extends StatelessWidget {
  final String? roomId;

  const CreateInvoicePage({super.key, this.roomId});

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
      child: _CreateInvoiceView(roomId: roomId),
    );
  }
}

class _CreateInvoiceView extends StatefulWidget {
  final String? roomId;

  const _CreateInvoiceView({this.roomId});

  @override
  State<_CreateInvoiceView> createState() => _CreateInvoiceViewState();
}

class _CreateInvoiceViewState extends State<_CreateInvoiceView> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedRoomId;
  Room? _selectedRoom;

  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  final _elecPrevCtrl = TextEditingController(text: '0');
  final _elecCurrCtrl = TextEditingController(text: '0');
  final _waterPrevCtrl = TextEditingController(text: '0');
  final _waterCurrCtrl = TextEditingController(text: '0');
  final _otherAmountCtrl = TextEditingController(text: '0');
  final _otherDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.roomId;
    _loadRoomDetails();
    if (_selectedRoomId != null) {
      context.read<InvoiceBloc>().add(FetchPreviousReadingsEvent(_selectedRoomId!));
    }

    _elecPrevCtrl.addListener(_updateTotal);
    _elecCurrCtrl.addListener(_updateTotal);
    _waterPrevCtrl.addListener(_updateTotal);
    _waterCurrCtrl.addListener(_updateTotal);
    _otherAmountCtrl.addListener(_updateTotal);
  }

  @override
  void dispose() {
    _elecPrevCtrl.dispose();
    _elecCurrCtrl.dispose();
    _waterPrevCtrl.dispose();
    _waterCurrCtrl.dispose();
    _otherAmountCtrl.dispose();
    _otherDescCtrl.dispose();
    super.dispose();
  }

  void _loadRoomDetails() {
    if (_selectedRoomId != null) {
      final roomState = context.read<RoomBloc>().state;
      if (roomState is RoomsLoaded) {
        try {
          _selectedRoom = roomState.rooms.firstWhere((r) => r.id == _selectedRoomId);
        } catch (e) {
          _selectedRoom = null;
        }
      }
    }
    _updateTotal();
  }

  void _updateTotal() {
    setState(() {});
  }

  double get _totalAmount {
    if (_selectedRoom == null) return 0;
    final elecPrev = double.tryParse(_elecPrevCtrl.text) ?? 0;
    final elecCurr = double.tryParse(_elecCurrCtrl.text) ?? 0;
    final waterPrev = double.tryParse(_waterPrevCtrl.text) ?? 0;
    final waterCurr = double.tryParse(_waterCurrCtrl.text) ?? 0;
    final otherAmount = double.tryParse(_otherAmountCtrl.text) ?? 0;

    final elecCost = (elecCurr - elecPrev > 0 ? (elecCurr - elecPrev) : 0) * _selectedRoom!.electricPrice;
    final waterCost = (waterCurr - waterPrev > 0 ? (waterCurr - waterPrev) : 0) * _selectedRoom!.waterPrice;

    return _selectedRoom!.rentPrice + _selectedRoom!.servicePrice + elecCost + waterCost + otherAmount;
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedRoom != null) {
      _formKey.currentState!.save();
      final elecPrev = double.tryParse(_elecPrevCtrl.text) ?? 0;
      final elecCurr = double.tryParse(_elecCurrCtrl.text) ?? 0;
      final waterPrev = double.tryParse(_waterPrevCtrl.text) ?? 0;
      final waterCurr = double.tryParse(_waterCurrCtrl.text) ?? 0;
      final otherAmount = double.tryParse(_otherAmountCtrl.text) ?? 0;

      // Lấy userId thật từ AuthBloc
      final authState = context.read<AuthBloc>().state;
      final userId = authState is AuthAuthenticated
          ? authState.user.id
          : '';

      final invoice = Invoice(
        id: const Uuid().v4(),
        roomId: _selectedRoom!.id,
        roomNumber: _selectedRoom!.roomNumber,
        tenantId: null,
        tenantName: null,
        month: _month,
        year: _year,
        electricPrevReading: elecPrev,
        electricCurrReading: elecCurr,
        electricUnitPrice: _selectedRoom!.electricPrice,
        waterPrevReading: waterPrev,
        waterCurrReading: waterCurr,
        waterUnitPrice: _selectedRoom!.waterPrice,
        rentAmount: _selectedRoom!.rentPrice,
        serviceAmount: _selectedRoom!.servicePrice,
        otherAmount: otherAmount > 0 ? otherAmount : null,
        otherDescription: _otherDescCtrl.text.trim().isEmpty ? null : _otherDescCtrl.text.trim(),
        status: InvoiceStatus.pending,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
        createdBy: userId,
      );

      context.read<InvoiceBloc>().add(CreateInvoiceEvent(invoice));
    } else if (_selectedRoom == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is InvoicePreviousReadingsLoaded) {
          _elecPrevCtrl.text = state.electricPrev.toStringAsFixed(0);
          _waterPrevCtrl.text = state.waterPrev.toStringAsFixed(0);
        } else if (state is InvoiceActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          // Redirect to invoice list or detail (we can pop for now)
          context.pop();
        } else if (state is InvoiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tạo hóa đơn'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông tin chung', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      BlocBuilder<RoomBloc, RoomState>(
                        builder: (context, state) {
                          List<Room> rooms = [];
                          if (state is RoomsLoaded) {
                            rooms = state.rooms.where((r) => r.isOccupied).toList();
                          }
                          return DropdownButtonFormField<String>(
                            value: _selectedRoomId,
                            decoration: const InputDecoration(
                              labelText: 'Chọn phòng đang thuê',
                              border: OutlineInputBorder(),
                            ),
                            items: rooms.map((room) {
                              return DropdownMenuItem(
                                value: room.id,
                                child: Text('Phòng ${room.roomNumber}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRoomId = value;
                                _loadRoomDetails();
                              });
                              if (value != null) {
                                context.read<InvoiceBloc>().add(FetchPreviousReadingsEvent(value));
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _month.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Tháng',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _month = int.tryParse(value ?? '$_month') ?? _month,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _year.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Năm',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _year = int.tryParse(value ?? '$_year') ?? _year,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedRoom != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chỉ số điện (Giá: ${AppFormatters.formatCurrency(_selectedRoom!.electricPrice)}/kWh)', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _elecPrevCtrl,
                                decoration: const InputDecoration(labelText: 'Số cũ', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _elecCurrCtrl,
                                decoration: const InputDecoration(labelText: 'Số mới', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  final prev = double.tryParse(_elecPrevCtrl.text) ?? 0;
                                  final curr = double.tryParse(val) ?? 0;
                                  if (curr < prev) return 'Phải >= số cũ';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chỉ số nước (Giá: ${AppFormatters.formatCurrency(_selectedRoom!.waterPrice)}/m³)', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _waterPrevCtrl,
                                decoration: const InputDecoration(labelText: 'Số cũ', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _waterCurrCtrl,
                                decoration: const InputDecoration(labelText: 'Số mới', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  final prev = double.tryParse(_waterPrevCtrl.text) ?? 0;
                                  final curr = double.tryParse(val) ?? 0;
                                  if (curr < prev) return 'Phải >= số cũ';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Các khoản khác (Nợ cũ, vệ sinh...)', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _otherDescCtrl,
                                decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _otherAmountCtrl,
                                decoration: const InputDecoration(labelText: 'Số tiền', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Live Preview Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tiền phòng & Dịch vụ:', style: TextStyle(fontSize: 16)),
                          Text(AppFormatters.formatCurrency(_selectedRoom!.rentPrice + _selectedRoom!.servicePrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng ước tính:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            AppFormatters.formatCurrency(_totalAmount),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Tạo hóa đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
