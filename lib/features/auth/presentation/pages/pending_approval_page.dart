import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  static const String _adminPhone = '0901234567'; // ← Thay SĐT của bạn
  static const String _adminZalo = '0901234567';  // ← Thay SĐT Zalo của bạn

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthPendingApproval
        ? authState.user.fullName
        : '';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // ── Animated Icon ────────────────────────────────────────
                _buildAnimatedIcon(),
                const SizedBox(height: 32),

                // ── Tiêu đề ─────────────────────────────────────────────
                _buildTitle(userName).animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 32),

                // ── Timeline trạng thái ──────────────────────────────────
                _buildTimeline().animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 32),

                // ── Card liên hệ ─────────────────────────────────────────
                _buildContactCard().animate()
                    .fadeIn(delay: 700.ms, duration: 600.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 24),

                // ── Nút đăng xuất ────────────────────────────────────────
                _buildLogoutButton(context).animate()
                    .fadeIn(delay: 900.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.hourglass_top_rounded,
        size: 60,
        color: Colors.white,
      ),
    )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.08,
          duration: 1500.ms,
          curve: Curves.easeInOut,
        )
        .animate()
        .fadeIn(duration: 500.ms);
  }

  Widget _buildTitle(String userName) {
    return Column(
      children: [
        Text(
          userName.isNotEmpty ? 'Xin chào, $userName!' : 'Tài khoản đang chờ duyệt',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Text(
            'Yêu cầu đăng ký của bạn đã được ghi nhận.\n'
            'Chúng tôi sẽ xét duyệt và liên hệ lại trong vòng 24 giờ.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final steps = [
      _TimelineStep(
        icon: Icons.check_circle_rounded,
        title: 'Đăng ký thành công',
        subtitle: 'Thông tin của bạn đã được lưu',
        isDone: true,
      ),
      _TimelineStep(
        icon: Icons.manage_search_rounded,
        title: 'Đang xét duyệt',
        subtitle: 'Admin đang kiểm tra thông tin',
        isDone: false,
        isActive: true,
      ),
      _TimelineStep(
        icon: Icons.rocket_launch_rounded,
        title: 'Kích hoạt tài khoản',
        subtitle: 'Bắt đầu quản lý nhà trọ',
        isDone: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quy trình kích hoạt',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final isLast = e.key == steps.length - 1;
            return _buildTimelineItem(e.value, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(_TimelineStep step, bool isLast) {
    final Color iconColor = step.isDone
        ? const Color(0xFF10B981)
        : step.isActive
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6B7280);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.15),
                border: Border.all(color: iconColor, width: 2),
              ),
              child: Icon(step.icon, color: iconColor, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: Colors.white.withValues(alpha: 0.1),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    color: step.isActive ? const Color(0xFFF59E0B) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.2),
            const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: Color(0xFF60A5FA), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cần hỗ trợ nhanh hơn?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactButton(
            icon: Icons.phone_rounded,
            label: 'Gọi ngay: $_adminPhone',
            color: const Color(0xFF10B981),
            onTap: () => launchUrl(Uri.parse('tel:$_adminPhone')),
          ),
          const SizedBox(height: 10),
          _buildContactButton(
            icon: Icons.chat_bubble_rounded,
            label: 'Nhắn Zalo: $_adminZalo',
            color: const Color(0xFF3B82F6),
            onTap: () => launchUrl(
              Uri.parse('https://zalo.me/$_adminZalo'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        context.read<AuthBloc>().add(const AuthLogoutEvent());
      },
      icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF9CA3AF)),
      label: const Text(
        'Đăng xuất',
        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      ),
    );
  }
}

class _TimelineStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDone = false,
    this.isActive = false,
  });
}
