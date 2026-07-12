// lib/features/tenant_management/presentation/pages/add_edit_tenant_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/room_management/presentation/bloc/room_bloc.dart';
import '../../../../features/room_management/domain/entities/room.dart';
import '../../domain/entities/tenant.dart';
import '../../data/models/tenant_model.dart';
import '../bloc/tenant_bloc.dart';

class AddEditTenantPage extends StatelessWidget {
  final String? tenantId;
  final String? roomId;

  const AddEditTenantPage({super.key, this.tenantId, this.roomId});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final propertyId = authState is AuthAuthenticated
        ? authState.user.propertyId ?? ''
        : '';

    return MultiBlocProvider(
      providers: [
        BlocProvider<TenantBloc>(
          create: (_) => getIt<TenantBloc>()..add(LoadTenantsEvent(propertyId: propertyId)),
        ),
        BlocProvider<RoomBloc>(
          create: (_) => getIt<RoomBloc>()..add(LoadRoomsEvent(propertyId)),
        ),
      ],
      child: _AddEditTenantForm(
        tenantId: tenantId,
        roomId: roomId,
        propertyId: propertyId,
      ),
    );
  }
}

class _AddEditTenantForm extends StatefulWidget {
  final String? tenantId;
  final String? roomId;
  final String propertyId;

  const _AddEditTenantForm({this.tenantId, this.roomId, required this.propertyId});

  @override
  State<_AddEditTenantForm> createState() => _AddEditTenantFormState();
}

class _AddEditTenantFormState extends State<_AddEditTenantForm> {
  final _formKey = GlobalKey<FormState>();

  final _cccdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _dob;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _selectedRoomId;

  bool _isEditing = false;
  Tenant? _existingTenant;
  List<Tenant> _allTenants = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.tenantId != null;
    _selectedRoomId = widget.roomId;
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 180)); // Mặc định 6 tháng

    _cccdController.addListener(_onCccdChanged);
  }

  @override
  void dispose() {
    _cccdController.removeListener(_onCccdChanged);
    _cccdController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onCccdChanged() {
    final cccd = _cccdController.text.trim();
    if (cccd.length == 12 && !_isEditing && _allTenants.isNotEmpty) {
      // Tìm kiếm xem số CCCD đã tồn tại trong danh sách khách thuê chưa
      try {
        final existing = _allTenants.firstWhere(
          (t) => t.cccdNumber == cccd,
        );
        
        setState(() {
          _fullNameController.text = existing.fullName;
          _phoneController.text = existing.phoneNumber;
          _emailController.text = existing.email ?? '';
          _dob = existing.dateOfBirth;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tìm thấy khách thuê cũ. Đã tự động điền thông tin!'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (_) {
        // Không tìm thấy, tiếp tục cho nhập mới bình thường
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDob, {bool isStartDate = false}) async {
    final initialDate = isDob
        ? (_dob ?? DateTime(2000, 1, 1))
        : (isStartDate ? _startDate : _endDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isDob) {
          _dob = picked;
        } else if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedRoomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn phòng thuê'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      _formKey.currentState!.save();
      _showPasswordConfirmationDialog();
    }
  }

  // Yêu cầu nhập mật khẩu admin để xác thực trước khi lưu
  void _showPasswordConfirmationDialog() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    
    final adminEmail = authState.user.email;
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Xác thực bảo mật'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CCCD là thông tin bảo mật quan trọng. Vui lòng nhập mật khẩu đăng nhập của bạn để xác nhận lưu thông tin khách thuê.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu của bạn',
                      errorText: errorMessage,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final password = passwordController.text.trim();
                          if (password.isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Vui lòng nhập mật khẩu';
                            });
                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            // Xác thực với Supabase
                            await getIt<SupabaseClient>().auth.signInWithPassword(
                              email: adminEmail,
                              password: password,
                            );

                            // Đóng dialog xác nhận mật khẩu
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              _saveTenant();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = 'Mật khẩu không chính xác';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveTenant() {
    final tenant = Tenant(
      id: _isEditing ? _existingTenant!.id : const Uuid().v4(),
      propertyId: widget.propertyId,
      roomId: _selectedRoomId!,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      cccdNumber: _cccdController.text.trim(),
      dateOfBirth: _dob,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      contractStartDate: _startDate,
      contractEndDate: _endDate,
      isActive: _existingTenant?.isActive ?? true,
      createdAt: _isEditing ? _existingTenant!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_isEditing) {
      context.read<TenantBloc>().add(UpdateTenantEvent(tenant));
    } else {
      context.read<TenantBloc>().add(CreateTenantEvent(tenant));
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

    return MultiBlocListener(
      listeners: [
        BlocListener<TenantBloc, TenantState>(
          listener: (context, state) {
            if (state is TenantLoaded) {
              setState(() {
                _allTenants = state.tenants;
                if (_isEditing) {
                  _existingTenant = state.tenants.firstWhere(
                    (t) => t.id == widget.tenantId,
                    orElse: () => throw Exception('Không tìm thấy khách thuê'),
                  );

                  _cccdController.text = _existingTenant!.cccdNumber;
                  _fullNameController.text = _existingTenant!.fullName;
                  _phoneController.text = _existingTenant!.phoneNumber;
                  _emailController.text = _existingTenant!.email ?? '';
                  _dob = _existingTenant!.dateOfBirth;
                  _startDate = _existingTenant!.contractStartDate;
                  _endDate = _existingTenant!.contractEndDate;
                  _selectedRoomId = _existingTenant!.roomId;
                }
              });
            } else if (state is TenantOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
              context.pop();
            } else if (state is TenantError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Sửa thông tin khách thuê' : 'Thêm khách thuê'),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Thông tin pháp lý (CCCD)
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_outlined, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin định danh (Bảo mật)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cccdController,
                        decoration: const InputDecoration(
                          labelText: 'Số CCCD (12 chữ số) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số CCCD';
                          }
                          if (!RegExp(AppConstants.cccdRegex).hasMatch(value)) {
                            return 'Số CCCD không hợp lệ (đủ 12 chữ số)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Thông tin cá nhân
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_outline, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin cá nhân',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên khách thuê *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại liên hệ *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          if (!RegExp(AppConstants.phoneRegex).hasMatch(value)) {
                            return 'Số điện thoại không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email (không bắt buộc)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.cake_outlined, color: AppColors.textSecondary),
                        title: const Text('Ngày sinh'),
                        subtitle: Text(_dob == null
                            ? 'Chưa chọn'
                            : '${_dob!.day}/${_dob!.month}/${_dob!.year}'),
                        trailing: OutlinedButton(
                          onPressed: () => _selectDate(context, true),
                          child: const Text('Chọn'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Thông tin thuê phòng
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.home_work_outlined, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin phòng & Hợp đồng',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<RoomBloc, RoomState>(
                        builder: (context, state) {
                          List<Room> availableRooms = [];
                          if (state is RoomsLoaded) {
                            // Lọc các phòng còn trống hoặc chính phòng hiện tại đang được chọn (khi edit)
                            availableRooms = state.rooms.where((r) {
                              return r.status == RoomStatus.empty || r.id == _selectedRoomId;
                            }).toList();
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedRoomId,
                            decoration: const InputDecoration(
                              labelText: 'Chọn phòng thuê *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.meeting_room),
                            ),
                            items: availableRooms.map((room) {
                              return DropdownMenuItem(
                                value: room.id,
                                child: Text('Phòng ${room.roomNumber} - T${room.floor}'),
                              );
                            }).toList(),
                            onChanged: _isEditing ? null : (value) {
                              setState(() {
                                _selectedRoomId = value;
                              });
                            },
                            validator: (value) => value == null ? 'Vui lòng chọn phòng' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
                        title: const Text('Ngày bắt đầu hợp đồng'),
                        subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                        trailing: OutlinedButton(
                          onPressed: () => _selectDate(context, false, isStartDate: true),
                          child: const Text('Chọn'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_busy_outlined, color: AppColors.textSecondary),
                        title: const Text('Ngày kết thúc hợp đồng'),
                        subtitle: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                        trailing: OutlinedButton(
                          onPressed: () => _selectDate(context, false, isStartDate: false),
                          child: const Text('Chọn'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Nút Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.security_rounded),
                  label: Text(_isEditing ? 'Lưu thay đổi' : 'Xác thực & Lưu thông tin'),
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
