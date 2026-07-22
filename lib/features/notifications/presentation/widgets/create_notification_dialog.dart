import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../room_management/presentation/bloc/room_bloc.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification.dart';
import '../bloc/notification_bloc.dart';

class CreateNotificationDialog extends StatefulWidget {
  const CreateNotificationDialog({super.key});

  @override
  State<CreateNotificationDialog> createState() => _CreateNotificationDialogState();
}

class _CreateNotificationDialogState extends State<CreateNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String? _selectedRoomId;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  late AuthAuthenticated _authState;
  
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _authState = authState;
      if (_authState.user.isOwner) {
        // Fetch rooms if owner
        context.read<RoomBloc>().add(LoadRoomsEvent(_authState.user.propertyId!));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isOwner = _authState.user.isOwner;
    final roomId = isOwner ? _selectedRoomId : _authState.user.roomId;
    // For owner, receiver is null (all tenants in the room/property)
    // For tenant, receiver is null (goes to owner of the room, or we just leave null and owner sees all)
    
    final type = isOwner ? AppNotificationType.announcement : AppNotificationType.issue;
    
    final notification = NotificationModel(
      id: const Uuid().v4(),
      roomId: roomId,
      senderId: _authState.user.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: type,
      status: AppNotificationStatus.unread,
      sentAt: DateTime.now(),
    );

    context.read<NotificationBloc>().add(SendNotificationEvent(notification, imageFile: _imageFile));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _authState.user.isOwner;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isOwner ? 'Tạo thông báo mới' : 'Báo cáo sự cố',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                if (isOwner) ...[
                  BlocBuilder<RoomBloc, RoomState>(
                    builder: (context, state) {
                      if (state is RoomsLoaded) {
                        return DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: 'Gửi đến phòng',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          value: _selectedRoomId,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Tất cả các phòng'),
                            ),
                            ...state.rooms.map((room) => DropdownMenuItem(
                                  value: room.id,
                                  child: Text('Phòng ${room.roomNumber}'),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedRoomId = val);
                          },
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Nội dung chi tiết',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập nội dung' : null,
                ),
                const SizedBox(height: 16),
                
                if (_imageFile != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFile!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        onPressed: () => setState(() => _imageFile = null),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_rounded),
                    label: const Text('Đính kèm hình ảnh (tùy chọn)'),
                  ),
                  
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Gửi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
