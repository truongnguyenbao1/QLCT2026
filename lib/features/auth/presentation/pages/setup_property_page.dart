// lib/features/auth/presentation/pages/setup_property_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SetupPropertyPage extends StatefulWidget {
  const SetupPropertyPage({super.key});

  @override
  State<SetupPropertyPage> createState() => _SetupPropertyPageState();
}

class _SetupPropertyPageState extends State<SetupPropertyPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthNeedPropertySetup) return;

    setState(() => _isLoading = true);

    try {
      final client = getIt<SupabaseClient>();
      final userId = authState.user.id;

      // 1. Tạo row nhà trọ trong bảng nhatro
      final result = await client
          .from('nhatro')
          .insert({
            'name': _nameController.text.trim(),
            'address': _addressController.text.trim(),
            'iduser': userId,
          })
          .select()
          .single();

      final propertyId = result['id'] as String;

      // 2. Gán property_id vào bảng users
      await client
          .from('users')
          .update({'property_id': propertyId})
          .eq('iduser', userId);

      // 3. Thông báo BLoC để chuyển sang Authenticated
      if (mounted) {
        final updatedUser = authState.user.copyWith(propertyId: propertyId);
        context.read<AuthBloc>().add(AuthPropertySetupCompletedEvent(updatedUser));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo nhà trọ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF0288D1), Color(0xFF00897B)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Icon Header ───────────────────────────────────
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 2),
                        ),
                        child: const Icon(
                          Icons.home_work_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Đăng ký Nhà Trọ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy điền thông tin dãy trọ của bạn để bắt đầu quản lý phòng.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Card Form ─────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tên nhà trọ
                                const Text(
                                  'Tên nhà trọ / dãy trọ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Color(0xFF111827)),
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: 'VD: Nhà trọ Phúc Hưng',
                                    prefixIcon: const Icon(Icons.apartment_rounded),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Vui lòng nhập tên nhà trọ'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Địa chỉ
                                const Text(
                                  'Địa chỉ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _addressController,
                                  style: const TextStyle(color: Color(0xFF111827)),
                                  textInputAction: TextInputAction.done,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'VD: 123 Đường Lê Lợi, Q.1, TP.HCM',
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 20),
                                      child: Icon(Icons.location_on_rounded),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Vui lòng nhập địa chỉ'
                                      : null,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: 28),

                                // Nút xác nhận
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: FilledButton.icon(
                                    onPressed: _isLoading ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.check_circle_outline_rounded),
                                    label: Text(
                                      _isLoading
                                          ? 'Đang tạo nhà trọ...'
                                          : 'Hoàn tất đăng ký',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      // Thoát / đăng xuất
                      TextButton.icon(
                        onPressed: () =>
                            context.read<AuthBloc>().add(const AuthLogoutEvent()),
                        icon: const Icon(Icons.logout, color: Colors.white70, size: 16),
                        label: const Text(
                          'Đăng xuất',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
