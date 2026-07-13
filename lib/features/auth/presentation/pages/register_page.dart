import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/navigation/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthRegisterEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            // Không truyền role — mặc định TENANT
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthNeedPrivacyAcceptance) {
          context.go(AppRoutes.privacyPolicy);
        } else if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        // Nền gradient sáng từ xanh nhạt → trắng
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F0FE),
                Color(0xFFF0F7FF),
                Color(0xFFFFFFFF),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Header ──────────────────────────────────────────
                      Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4285F4).withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              size: 38,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Tạo tài khoản',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A2E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tham gia hệ thống quản lý nhà trọ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

                      const SizedBox(height: 28),

                      // ── Info chip: vai trò mặc định ──────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: Color(0xFF3B82F6), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tài khoản mới sẽ có vai trò Khách thuê. Chủ trọ vui lòng liên hệ quản trị viên để nâng quyền.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF1D4ED8),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                      const SizedBox(height: 20),

                      // ── Registration card ─────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4285F4).withValues(alpha: 0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fullname
                              _buildLabel('Họ và tên'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _fullNameController,
                                style: const TextStyle(color: Color(0xFF111827)),
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  hint: 'Nguyễn Văn A',
                                  icon: Icons.person_outline_rounded,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Vui lòng nhập họ và tên'
                                    : null,
                              ),
                              const SizedBox(height: 18),

                              // Email
                              _buildLabel('Email'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Color(0xFF111827)),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  hint: 'example@email.com',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                    return 'Email không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Phone
                              _buildLabel('Số điện thoại'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _phoneController,
                                style: const TextStyle(color: Color(0xFF111827)),
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  hint: '09x xxx xxxx',
                                  icon: Icons.phone_outlined,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Vui lòng nhập số điện thoại'
                                    : null,
                              ),
                              const SizedBox(height: 18),

                              // Password
                              _buildLabel('Mật khẩu'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                style: const TextStyle(color: Color(0xFF111827)),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  hint: 'Tối thiểu 6 ký tự',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey[500],
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                                  if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Confirm Password
                              _buildLabel('Xác nhận mật khẩu'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _confirmPasswordController,
                                style: const TextStyle(color: Color(0xFF111827)),
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _onRegister(),
                                decoration: _inputDecoration(
                                  hint: 'Nhập lại mật khẩu',
                                  icon: Icons.lock_reset_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey[500],
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Vui lòng xác nhận mật khẩu';
                                  }
                                  if (v != _passwordController.text) {
                                    return 'Mật khẩu không khớp';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              // Submit Button
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF4285F4)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: state is AuthLoading ? null : _onRegister,
                                        child: state is AuthLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                    color: Colors.white, strokeWidth: 2.5),
                                              )
                                            : const Text(
                                                'Tạo tài khoản',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1),

                      const SizedBox(height: 20),

                      // Back to login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: const Text(
                              'Đăng nhập ngay',
                              style: TextStyle(
                                color: Color(0xFF1A73E8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4285F4), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
