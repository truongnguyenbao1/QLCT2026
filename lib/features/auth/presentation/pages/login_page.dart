// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/navigation/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthLoginEvent(
            email: _emailController.text,
            password: _passwordController.text,
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
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.darkHeaderGradient,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // ── Logo & Title ───────────────────────────────────────
                  _buildHeader(theme)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, curve: Curves.easeOut),

                  const SizedBox(height: 48),

                  // ── Login Card ─────────────────────────────────────────
                  _buildLoginCard(theme)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // ── Forgot Password ───────────────────────────────────
                  TextButton(
                    onPressed: () => _showForgotPasswordDialog(context),
                    child: Text(
                      'Quên mật khẩu?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.home_work_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Quản lý Nhà trọ',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Minh bạch • Tiện lợi • Đúng luật',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đăng nhập',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhập thông tin để tiếp tục',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 28),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Vui lòng nhập email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onLogin(),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                if (val.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Login button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    icon: state is AuthLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.login_rounded),
                    label: const Text('Đăng nhập'),
                    onPressed: state is AuthLoading ? null : _onLogin,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Nhập email của bạn để nhận link đặt lại mật khẩu.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Đã gửi link đặt lại mật khẩu!')),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }
}
