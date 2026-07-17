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
  
  String _roomNumber = '';
  int? _floor;
  double _area = 20.0;
  double _rentPrice = 0;
  double _electricPrice = 3500;
  double _waterPrice = 20000;
  double _servicePrice = 100000;
  RoomStatus _status = RoomStatus.empty;
  int? _maxOccupants;
  String? _description;

  bool _isEditing = false;
  Room? _existingRoom;
  bool _formInitialized = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.roomId != null;
    
    if (!_isEditing) {
      _formInitialized = true;
    }
  }
  
  void _initFormValues(Room room) {
    _existingRoom = room;
    _roomNumber = room.roomNumber;
    _floor = room.floor;
    _area = room.area;
    _rentPrice = room.rentPrice;
    _electricPrice = room.electricPrice;
    _waterPrice = room.waterPrice;
    _servicePrice = room.servicePrice;
    _status = room.status;
    _maxOccupants = room.maxOccupants;
    _description = room.description;
    _formInitialized = true;
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

    return BlocConsumer<RoomBloc, RoomState>(
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
      builder: (context, state) {
        if (_isEditing && !_formInitialized) {
          if (state is RoomsLoading || state is RoomInitial) {
            return Scaffold(
              appBar: AppBar(title: const Text('Sửa thông tin phòng')),
              body: const Center(child: CircularProgressIndicator()),
            );
          } else if (state is RoomsLoaded) {
            try {
              final room = state.rooms.firstWhere((r) => r.id == widget.roomId);
              _initFormValues(room);
            } catch (e) {
              return Scaffold(
                appBar: AppBar(title: const Text('Lỗi')),
                body: const Center(child: Text('Không tìm thấy phòng')),
              );
            }
          } else if (state is RoomActionSuccess) {
            try {
              final room = state.rooms.firstWhere((r) => r.id == widget.roomId);
              _initFormValues(room);
            } catch (e) {
              return Scaffold(
                appBar: AppBar(title: const Text('Lỗi')),
                body: const Center(child: Text('Không tìm thấy phòng')),
              );
            }
          }
        }

        return Scaffold(
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
                                initialValue: _floor?.toString() ?? '',
                                decoration: const InputDecoration(
                                  labelText: 'Tầng (Tùy chọn)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _floor = value != null && value.isNotEmpty ? int.tryParse(value) : null,
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
                        // Đã bỏ chọn trạng thái thủ công theo yêu cầu, trạng thái sẽ tự động cập nhật
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
        );
      },
    );
  }
}
