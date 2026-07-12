import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/room.dart';
import '../bloc/room_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class AddEditRoomPage extends StatefulWidget {
  final String? roomId;

  const AddEditRoomPage({super.key, this.roomId});

  @override
  State<AddEditRoomPage> createState() => _AddEditRoomPageState();
}

class _AddEditRoomPageState extends State<AddEditRoomPage> {
  final _formKey = GlobalKey<FormState>();
  
  late String _roomNumber;
  late int _floor;
  late double _area;
  late double _rentPrice;
  late double _electricPrice;
  late double _waterPrice;
  late double _servicePrice;
  late RoomStatus _status;
  late int? _maxOccupants;
  late String? _description;

  bool _isEditing = false;
  Room? _existingRoom;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.roomId != null;
    
    if (_isEditing) {
      final state = context.read<RoomBloc>().state;
      if (state is RoomsLoaded) {
        _existingRoom = state.rooms.firstWhere(
          (r) => r.id == widget.roomId,
          orElse: () => throw Exception('Không tìm thấy phòng'),
        );
      } else if (state is RoomActionSuccess) {
         _existingRoom = state.rooms.firstWhere(
          (r) => r.id == widget.roomId,
          orElse: () => throw Exception('Không tìm thấy phòng'),
        );
      }
      
      _roomNumber = _existingRoom?.roomNumber ?? '';
      _floor = _existingRoom?.floor ?? 1;
      _area = _existingRoom?.area ?? 20.0;
      _rentPrice = _existingRoom?.rentPrice ?? 0;
      _electricPrice = _existingRoom?.electricPrice ?? 3500;
      _waterPrice = _existingRoom?.waterPrice ?? 20000;
      _servicePrice = _existingRoom?.servicePrice ?? 100000;
      _status = _existingRoom?.status ?? RoomStatus.empty;
      _maxOccupants = _existingRoom?.maxOccupants;
      _description = _existingRoom?.description;
    } else {
      _roomNumber = '';
      _floor = 1;
      _area = 20.0;
      _rentPrice = 0;
      _electricPrice = 3500;
      _waterPrice = 20000;
      _servicePrice = 100000;
      _status = RoomStatus.empty;
      _maxOccupants = null;
      _description = null;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final authState = context.read<AuthBloc>().state;
      final propertyId = authState is AuthAuthenticated
          ? authState.user.propertyId ?? 'default_property'
          : 'default_property';
      
      final room = Room(
        id: _isEditing ? _existingRoom!.id : const Uuid().v4(),
        propertyId: _isEditing ? _existingRoom!.propertyId : propertyId,
        roomNumber: _roomNumber,
        floor: _floor,
        area: _area,
        rentPrice: _rentPrice,
        electricPrice: _electricPrice,
        waterPrice: _waterPrice,
        servicePrice: _servicePrice,
        status: _status,
        maxOccupants: _maxOccupants,
        description: _description,
        createdAt: _isEditing ? _existingRoom!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        context.read<RoomBloc>().add(UpdateRoomEvent(room));
      } else {
        context.read<RoomBloc>().add(CreateRoomEvent(room));
      }
    }
  }

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

    return BlocListener<RoomBloc, RoomState>(
      listener: (context, state) {
        if (state is RoomActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.pop();
        } else if (state is RoomError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Sửa thông tin phòng' : 'Thêm phòng mới'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông tin cơ bản', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _roomNumber,
                        decoration: const InputDecoration(
                          labelText: 'Số phòng / Tên phòng *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên phòng' : null,
                        onSaved: (value) => _roomNumber = value!,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _floor.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Tầng',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _floor = int.tryParse(value ?? '1') ?? 1,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _area.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Diện tích (m²)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onSaved: (value) => _area = double.tryParse(value ?? '20') ?? 20.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<RoomStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(),
                        ),
                        items: RoomStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chi phí mặc định', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _rentPrice.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Giá thuê /tháng (VNĐ) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập giá thuê' : null,
                        onSaved: (value) => _rentPrice = double.tryParse(value ?? '0') ?? 0,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _electricPrice.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Giá điện /kWh',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _electricPrice = double.tryParse(value ?? '3500') ?? 3500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _waterPrice.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Giá nước /m³',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _waterPrice = double.tryParse(value ?? '20000') ?? 20000,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _servicePrice.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Phí dịch vụ /tháng',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _servicePrice = double.tryParse(value ?? '100000') ?? 100000,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Khác', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _maxOccupants?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Số người ở tối đa (Để trống nếu không giới hạn)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _maxOccupants = value != null && value.isNotEmpty ? int.tryParse(value) : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _description ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Mô tả thêm',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onSaved: (value) => _description = value,
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
                  child: Text(_isEditing ? 'Lưu thay đổi' : 'Thêm phòng'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
