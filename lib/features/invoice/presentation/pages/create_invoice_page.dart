import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/invoice.dart';
import '../bloc/invoice_bloc.dart';
import '../../../room_management/domain/entities/room.dart';
import '../../../room_management/presentation/bloc/room_bloc.dart';

class CreateInvoicePage extends StatefulWidget {
  final String? roomId;

  const CreateInvoicePage({super.key, this.roomId});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedRoomId;
  Room? _selectedRoom;

  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  double _electricPrev = 0;
  double _electricCurr = 0;
  double _waterPrev = 0;
  double _waterCurr = 0;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.roomId;
    _loadRoomDetails();
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
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedRoom != null) {
      _formKey.currentState!.save();
      
      final invoice = Invoice(
        id: const Uuid().v4(),
        roomId: _selectedRoom!.id,
        roomNumber: _selectedRoom!.roomNumber,
        month: _month,
        year: _year,
        electricPrevReading: _electricPrev,
        electricCurrReading: _electricCurr,
        electricUnitPrice: _selectedRoom!.electricPrice,
        waterPrevReading: _waterPrev,
        waterCurrReading: _waterCurr,
        waterUnitPrice: _selectedRoom!.waterPrice,
        rentAmount: _selectedRoom!.rentPrice,
        serviceAmount: _selectedRoom!.servicePrice,
        status: InvoiceStatus.pending,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
        createdBy: 'admin_user', // from Auth context
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
        if (state is InvoiceActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
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
                      // Dropdown for Room Selection
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
                        Text('Chỉ số điện (Giá: ${_selectedRoom!.electricPrice}/kWh)', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Số cũ', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _electricPrev = double.tryParse(value ?? '0') ?? 0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Số mới', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (value) => value == null || value.isEmpty ? 'Nhập số mới' : null,
                                onSaved: (value) => _electricCurr = double.tryParse(value ?? '0') ?? 0,
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
                        Text('Chỉ số nước (Giá: ${_selectedRoom!.waterPrice}/m³)', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Số cũ', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _waterPrev = double.tryParse(value ?? '0') ?? 0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Số mới', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (value) => value == null || value.isEmpty ? 'Nhập số mới' : null,
                                onSaved: (value) => _waterCurr = double.tryParse(value ?? '0') ?? 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Tạo hóa đơn'),
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
