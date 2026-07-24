import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seo/seo.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/navigation/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../domain/entities/app_user.dart';

class RegisterPage extends StatefulWidget {
  final String? initialEmail;
  final String? initialFullName;

  const RegisterPage({super.key, this.initialEmail, this.initialFullName});

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
  final _cccdController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  UserRole _selectedRole = UserRole.tenant;
  int _selectedPlanIndex = 1; // Mặc định gói Tiêu chuẩn
  bool _showOwnerForm = false; // Hiện form sau khi chọn gói

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialFullName != null) {
      _fullNameController.text = widget.initialFullName!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cccdController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;
    
    String? selectedPlan;
    if (_selectedRole == UserRole.owner) {
      selectedPlan = _plans[_selectedPlanIndex].name;
    }

    context.read<AuthBloc>().add(
          AuthRegisterEvent(
            email: _emailController.text.trim(),
            password: widget.initialEmail != null ? 'google_oauth_dummy' : _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _selectedRole,
            cccd: _selectedRole == UserRole.tenant ? _cccdController.text.trim() : null,
            isOAuth: widget.initialEmail != null,
            plan: selectedPlan,
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
      child: Seo.head(
        tags: const [
          MetaTag(name: 'title', content: 'Tạo tài khoản | Quản lý Nhà trọ'),
          MetaTag(name: 'description', content: 'Đăng ký tài khoản Quản lý nhà trọ.'),
        ],
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
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
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
                          Seo.text(
                            text: 'Tạo tài khoản',
                            style: TextTagStyle.h1,
                            child: Text(
                              'Tạo tài khoản',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1A2E),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Seo.text(
                            text: 'Tham gia hệ thống quản lý nhà trọ',
                            style: TextTagStyle.p,
                            child: Text(
                              'Tham gia hệ thống quản lý nhà trọ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

                      const SizedBox(height: 28),

                      // ── Chọn Vai trò ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildRoleButton(
                                title: 'Khách thuê',
                                role: UserRole.tenant,
                              ),
                            ),
                            Expanded(
                              child: _buildRoleButton(
                                title: 'Chủ trọ',
                                role: UserRole.owner,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                      const SizedBox(height: 20),

                      // ── Nếu là Chủ trọ: hiện Pricing Cards ──────────────
                      if (_selectedRole == UserRole.owner && !_showOwnerForm)
                        _buildPricingSection()
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 400.ms)
                            .slideY(begin: 0.1)
                      else
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
                                enabled: widget.initialEmail == null, // Không cho sửa email nếu đăng nhập từ Google
                                decoration: _inputDecoration(
                                  hint: 'example@email.com',
                                  icon: Icons.email_outlined,
                                ).copyWith(
                                  filled: widget.initialEmail != null,
                                  fillColor: widget.initialEmail != null ? Colors.grey[200] : null,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
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

                              // CCCD (Only for Tenant)
                              if (_selectedRole == UserRole.tenant) ...[
                                _buildLabel('Căn cước công dân (Bắt buộc để liên kết phòng)'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _cccdController,
                                  style: const TextStyle(color: Color(0xFF111827)),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  decoration: _inputDecoration(
                                    hint: 'Nhập đủ 12 số CCCD',
                                    icon: Icons.badge_outlined,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số CCCD';
                                    if (v.trim().length != 12) return 'CCCD phải có đúng 12 số';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                              ],                                // Ẩn trường mật khẩu nếu đăng nhập từ Google
                                if (widget.initialEmail == null) ...[
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
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.length < 6)
                                        ? 'Mật khẩu phải có ít nhất 6 ký tự'
                                        : null,
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
                                      icon: Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.grey[500],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirm = !_obscureConfirm;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                                      if (v != _passwordController.text) return 'Mật khẩu không khớp';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                ],
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

  Widget _buildRoleButton({required String title, required UserRole role}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRole = role;
        _showOwnerForm = false; // Reset về pricing khi đổi tab
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  // ── Pricing Section ────────────────────────────────────────────────────
  List<_PlanData> get _plans => [
    _PlanData(
      name: 'Cơ bản',
      price: '49.000',
      maxRooms: 10,
      color: const Color(0xFF6366F1),
      features: [
        'Tối đa 10 phòng',
        'Quản lý hóa đơn hàng tháng',
        'Báo cáo thu chi cơ bản',
        'Hỗ trợ qua email',
      ],
      badge: null,
    ),
    _PlanData(
      name: 'Tiêu chuẩn',
      price: '99.000',
      maxRooms: 30,
      color: const Color(0xFF0EA5E9),
      features: [
        'Tối đa 30 phòng',
        'Tất cả tính năng Cơ bản',
        'Thông báo đến khách thuê',
        'QR thanh toán MoMo/VietQR',
        'Hỗ trợ qua Zalo',
      ],
      badge: 'PHỔ BIẾN',
    ),
    _PlanData(
      name: 'Chuyên nghiệp',
      price: '199.000',
      maxRooms: -1,
      color: const Color(0xFF8B5CF6),
      features: [
        'Không giới hạn phòng',
        'Tất cả tính năng Tiêu chuẩn',
        'Phân quyền nhân viên (Sắp ra mắt)',
        'Tùy chỉnh biểu mẫu hợp đồng',
        'Hỗ trợ ưu tiên 24/7',
      ],
      badge: null,
    ),
  ];

  Widget _buildPricingSection() {
    final plans = _plans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E40AF).withValues(alpha: 0.08),
                const Color(0xFF7C3AED).withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFF3B82F6), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎉 Dùng thử MIỄN PHÍ 7 ngày',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Không cần thẻ tín dụng. Hủy bất cứ lúc nào.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Plan Cards
        ...plans.asMap().entries.map((entry) {
          final i = entry.key;
          final plan = entry.value;
          final isSelected = _selectedPlanIndex == i;
          return _buildPlanCard(plan, i, isSelected);
        }),

        const SizedBox(height: 16),

        // CTA Button
        SizedBox(
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
                  color: const Color(0xFF4285F4).withValues(alpha: 0.3),
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
              onPressed: () => setState(() => _showOwnerForm = true),
              child: Text(
                'Bắt đầu với gói ${plans[_selectedPlanIndex].name} →',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(_PlanData plan, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? plan.color.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? plan.color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: plan.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.badge != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: plan.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan.badge!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: plan.color,
                            ),
                          ),
                        ),
                      Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? plan.color : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: plan.price,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? plan.color : const Color(0xFF111827),
                            ),
                          ),
                          const TextSpan(
                            text: ' đ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '/ tháng',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Radio
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? plan.color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? plan.color : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Features
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: plan.color.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _PlanData {
  final String name;
  final String price;
  final int maxRooms;
  final Color color;
  final List<String> features;
  final String? badge;

  const _PlanData({
    required this.name,
    required this.price,
    required this.maxRooms,
    required this.color,
    required this.features,
    this.badge,
  });
}

