// lib/features/auth/presentation/pages/privacy_policy_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/navigation/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _hasScrolledToBottom = false;
  bool _agreed = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() => _hasScrolledToBottom = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Chính sách Bảo mật', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutEvent());
              context.go(AppRoutes.login);
            },
          ),
        ),
        body: Column(
          children: [
            // Warning banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.infoContainer,
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng đọc kỹ và cuộn xuống cuối để đồng ý tiếp tục.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.info,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Policy content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: _buildPolicyContent(theme),
              ),
            ),

            // Agreement footer
            _buildAgreementFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          theme,
          '📋 MỤC ĐÍCH THU THẬP DỮ LIỆU',
          'Ứng dụng Quản lý Nhà trọ thu thập các thông tin sau để phục vụ quản lý hợp đồng thuê nhà:\n\n'
              '• Số Căn cước công dân (CCCD/CMND) và ảnh chụp: Dùng cho mục đích khai báo tạm trú theo quy định pháp luật và xác minh danh tính khi ký hợp đồng.\n\n'
              '• Số điện thoại: Dùng để liên lạc và xác nhận thanh toán.\n\n'
              '• Thông tin thanh toán: Ghi lại lịch sử thu chi phục vụ kê khai thuế theo quy định.',
        ),
        _policySection(
          theme,
          '🔐 BIỆN PHÁP BẢO VỆ DỮ LIỆU',
          'Chúng tôi áp dụng các biện pháp kỹ thuật tiên tiến để bảo vệ thông tin của bạn:\n\n'
              '• Mã hóa AES-256: Số CCCD và SĐT được mã hóa trước khi lưu vào cơ sở dữ liệu.\n\n'
              '• HTTPS/TLS: Toàn bộ dữ liệu truyền tải đều được mã hóa.\n\n'
              '• Kiểm soát truy cập: Chỉ Chủ trọ được phép xem ảnh CCCD. Nhân viên không có quyền này.',
        ),
        _policySection(
          theme,
          '🗑️ QUYỀN XÓA DỮ LIỆU',
          'Theo Nghị định 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân và GDPR:\n\n'
              '• Sau khi chấm dứt hợp đồng và hết thời hạn lưu trữ bắt buộc (5 năm theo quy định thuế), thông tin CCCD sẽ được ẩn danh hóa hoàn toàn (Anonymize), không thể khôi phục.\n\n'
              '• Bạn có quyền yêu cầu Chủ trọ xóa dữ liệu của mình bất kỳ lúc nào sau khi hết thời hạn lưu trữ bắt buộc.',
        ),
        _policySection(
          theme,
          '📊 CHIA SẺ DỮ LIỆU',
          'Chúng tôi CAM KẾT:\n\n'
              '• Không bán, cho thuê, hoặc chia sẻ thông tin cá nhân của bạn cho bên thứ ba vì mục đích thương mại.\n\n'
              '• Chỉ chia sẻ với cơ quan nhà nước (công an, thuế) khi có yêu cầu hợp pháp theo quy định pháp luật Việt Nam.',
        ),
        _policySection(
          theme,
          '📞 LIÊN HỆ',
          'Nếu có thắc mắc về chính sách bảo mật, vui lòng liên hệ:\n\n'
              '• Email: support@nhatro.app\n'
              '• Điện thoại: 1900 xxxx\n\n'
              'Chúng tôi sẽ phản hồi trong vòng 72 giờ làm việc.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '⚖️ Chính sách này tuân thủ Nghị định 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân và Thông tư 40/2021/TT-BTC về kê khai thuế hộ kinh doanh.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.warning,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _policySection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.black87,
              height: 1.6,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Checkbox
          InkWell(
            onTap: _hasScrolledToBottom
                ? () => setState(() => _agreed = !_agreed)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: _hasScrolledToBottom
                        ? (val) => setState(() => _agreed = val!)
                        : null,
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: Text(
                      'Tôi đã đọc và đồng ý với Chính sách Bảo mật. Thông tin CCCD của tôi chỉ dùng cho mục đích khai báo tạm trú và quản lý hợp đồng.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _hasScrolledToBottom
                            ? Colors.black
                            : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_hasScrolledToBottom) ...[
            const SizedBox(height: 4),
            Text(
              '↓ Cuộn xuống để đọc hết chính sách',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
                fontStyle: FontStyle.italic,
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Confirm button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  child: state is AuthLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Xác nhận & Tiếp tục'),
                  onPressed: (_agreed && state is! AuthLoading)
                      ? () => context.read<AuthBloc>().add(
                            const AuthAcceptPrivacyPolicyEvent(),
                          )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
