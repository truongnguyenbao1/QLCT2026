// lib/features/payment_settings/presentation/pages/payment_settings_page.dart
// ─────────────────────────────────────────────────────────────────────────────
//  Trang cài đặt mã thanh toán dành cho chủ trọ
//  - Nhập thông tin tài khoản ngân hàng
//  - Nhập SĐT Momo (tùy chọn)
//  - Xem trước QR VietQR
//  - Thiết lập mẫu nội dung chuyển khoản
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/payment_settings.dart';
import '../bloc/payment_settings_bloc.dart';
import '../bloc/payment_settings_event.dart';
import '../bloc/payment_settings_state.dart';
import '../../data/datasources/bank_lookup_service.dart';

// ── Trạng thái tra cứu tên tài khoản ─────────────────────────────────────
enum _LookupStatus { idle, loading, success, error }

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({super.key});

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _momoPhoneCtrl = TextEditingController();
  final _noteTemplateCtrl = TextEditingController();

  BankInfo? _selectedBank;
  bool _showQrPreview = false;
  late TabController _tabController;

  // ── Trạng thái tra cứu tên tài khoản ──────────────────────────────────
  _LookupStatus _lookupStatus = _LookupStatus.idle;
  String _lookupMessage = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load cài đặt hiện tại
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<PaymentSettingsBloc>()
          .add(LoadPaymentSettingsEvent(authState.user.id));
    }
    // Tự động tra cứu khi số TK thay đổi
    _accountNumberCtrl.addListener(_scheduleLookup);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _accountNumberCtrl.removeListener(_scheduleLookup);
    _tabController.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    _momoPhoneCtrl.dispose();
    _noteTemplateCtrl.dispose();
    super.dispose();
  }

  void _populateFields(PaymentSettings settings) {
    _accountNumberCtrl.text = settings.accountNumber ?? '';
    _accountNameCtrl.text = settings.accountName ?? '';
    _momoPhoneCtrl.text = settings.momoPhone ?? '';
    _noteTemplateCtrl.text =
        settings.transferNoteTemplate ?? 'Phong {room} thang {month}/{year}';
    if (settings.bankCode != null) {
      _selectedBank = VietnamBanks.findByCode(settings.bankCode!);
    }
    // Reset trạng thái khi load dữ liệu từ server (đã có tên sẵn)
    _lookupStatus = _LookupStatus.idle;
    _lookupMessage = '';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    context.read<PaymentSettingsBloc>().add(
          SavePaymentSettingsEvent(
            userId: authState.user.id,
            bankCode: _selectedBank?.code,
            bankName: _selectedBank?.name,
            accountNumber: _accountNumberCtrl.text.trim(),
            accountName: _accountNameCtrl.text.trim().toUpperCase(),
            transferNoteTemplate: _noteTemplateCtrl.text.trim().isEmpty
                ? 'Phong {room} thang {month}/{year}'
                : _noteTemplateCtrl.text.trim(),
            momoPhone: _momoPhoneCtrl.text.trim(),
          ),
        );
  }

  /// Tạo URL VietQR để xem trước QR
  String _buildVietQrUrl() {
    if (_selectedBank == null || _accountNumberCtrl.text.trim().isEmpty) {
      return '';
    }
    final bank = _selectedBank!.code;
    final acc = _accountNumberCtrl.text.trim();
    final name = Uri.encodeComponent(_accountNameCtrl.text.trim());
    final note = Uri.encodeComponent(
        _noteTemplateCtrl.text.trim().replaceAll('{room}', 'P101').replaceAll(
            '{month}', '7').replaceAll('{year}', '2026'));
    return 'https://img.vietqr.io/image/$bank-$acc-qr_only.png?accountName=$name&addInfo=$note&amount=0';
  }

  /// Tạo string encode QR (dùng qr_flutter)
  String _buildQrString() {
    if (_selectedBank == null || _accountNumberCtrl.text.trim().isEmpty) {
      return '';
    }
    return 'BANK:${_selectedBank!.code}:${_accountNumberCtrl.text.trim()}:${_accountNameCtrl.text.trim()}';
  }

  /// Debounce 1.5s rồi gọi API tra cứu
  void _scheduleLookup() {
    _debounceTimer?.cancel();
    final accountNumber = _accountNumberCtrl.text.trim();

    if (accountNumber.length < 6 || _selectedBank == null) {
      if (_lookupStatus != _LookupStatus.idle) {
        setState(() {
          _lookupStatus = _LookupStatus.idle;
          _lookupMessage = '';
        });
      }
      return;
    }

    setState(() {
      _lookupStatus = _LookupStatus.loading;
      _lookupMessage = '';
    });

    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _performLookup(accountNumber, _selectedBank!);
    });
  }

  /// Gọi VietQR Napas 247 để lấy tên tài khoản
  Future<void> _performLookup(String accountNumber, BankInfo bank) async {
    try {
      final name = await BankLookupService().lookupAccountName(
        bin: bank.bin,
        accountNumber: accountNumber,
      );
      if (!mounted) return;
      if (name != null && name.isNotEmpty) {
        setState(() {
          _accountNameCtrl.text = name;
          _lookupStatus = _LookupStatus.success;
          _lookupMessage = 'Đã xác minh qua Napas 247';
        });
      } else {
        setState(() {
          _lookupStatus = _LookupStatus.error;
          _lookupMessage = 'Không tìm thấy tài khoản – vui lòng nhập thủ công';
        });
      }
    } on BankLookupNotFoundException catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupStatus = _LookupStatus.error;
        _lookupMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupStatus = _LookupStatus.error;
        _lookupMessage = e.toString().replaceAll('BankLookupException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cài đặt thanh toán',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '🏦 Tài khoản NH', icon: Icon(Icons.account_balance_rounded, size: 18)),
            Tab(text: '📱 Ví điện tử', icon: Icon(Icons.phone_android_rounded, size: 18)),
          ],
        ),
      ),
      body: BlocConsumer<PaymentSettingsBloc, PaymentSettingsState>(
        listener: (context, state) {
          if (state is PaymentSettingsLoaded && state.settings != null) {
            _populateFields(state.settings!);
          } else if (state is PaymentSettingsSaved) {
            _populateFields(state.settings);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Đã lưu cài đặt thanh toán!'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else if (state is PaymentSettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PaymentSettingsLoading;
          final isSaving = state is PaymentSettingsSaving;

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Trạng thái cấu hình ────────────────────────────────
                _StatusBanner(state: state).animate().fadeIn(duration: 300.ms),

                // ── Tab content ────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Ngân hàng
                      _BankTab(
                        selectedBank: _selectedBank,
                        accountNumberCtrl: _accountNumberCtrl,
                        accountNameCtrl: _accountNameCtrl,
                        noteTemplateCtrl: _noteTemplateCtrl,
                        onBankSelected: (bank) {
                          setState(() => _selectedBank = bank);
                          _scheduleLookup();
                        },
                        showQrPreview: _showQrPreview,
                        onToggleQr: () =>
                            setState(() => _showQrPreview = !_showQrPreview),
                        qrString: _buildQrString(),
                        vietQrUrl: _buildVietQrUrl(),
                        lookupStatus: _lookupStatus,
                        lookupMessage: _lookupMessage,
                      ),

                      // Tab 2: Ví điện tử
                      _WalletTab(momoPhoneCtrl: _momoPhoneCtrl),
                    ],
                  ),
                ),

                // ── Nút lưu ───────────────────────────────────────────
                _SaveButton(
                  isSaving: isSaving,
                  onSave: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Banner trạng thái ─────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final PaymentSettingsState state;
  const _StatusBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    bool isConfigured = false;
    if (state is PaymentSettingsLoaded) {
      isConfigured = (state as PaymentSettingsLoaded).settings?.hasBankInfo ?? false;
    } else if (state is PaymentSettingsSaved) {
      isConfigured = (state as PaymentSettingsSaved).settings.hasBankInfo;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isConfigured
            ? const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              )
            : const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFF57F17)],
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isConfigured ? AppColors.success : AppColors.warning)
                .withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConfigured
                  ? Icons.verified_rounded
                  : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConfigured
                      ? 'Đã cấu hình thanh toán'
                      : 'Chưa cấu hình thanh toán',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isConfigured
                      ? 'Hóa đơn sẽ hiển thị QR chuyển khoản tự động'
                      : 'Thiết lập để khách thuê có thể quét QR thanh toán',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Ngân hàng ──────────────────────────────────────────────────────────
class _BankTab extends StatelessWidget {
  final BankInfo? selectedBank;
  final TextEditingController accountNumberCtrl;
  final TextEditingController accountNameCtrl;
  final TextEditingController noteTemplateCtrl;
  final ValueChanged<BankInfo?> onBankSelected;
  final bool showQrPreview;
  final VoidCallback onToggleQr;
  final String qrString;
  final String vietQrUrl;
  final _LookupStatus lookupStatus;
  final String lookupMessage;

  const _BankTab({
    required this.selectedBank,
    required this.accountNumberCtrl,
    required this.accountNameCtrl,
    required this.noteTemplateCtrl,
    required this.onBankSelected,
    required this.showQrPreview,
    required this.onToggleQr,
    required this.qrString,
    required this.vietQrUrl,
    required this.lookupStatus,
    required this.lookupMessage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Chọn ngân hàng ─────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.account_balance_rounded,
            title: 'Thông tin ngân hàng',
            subtitle: 'Chọn ngân hàng và nhập số tài khoản',
          ),
          const SizedBox(height: 12),

          // Dropdown ngân hàng
          _BankDropdown(
            selectedBank: selectedBank,
            onChanged: onBankSelected,
          ),
          const SizedBox(height: 12),

          // Số tài khoản
          _StyledField(
            controller: accountNumberCtrl,
            label: 'Số tài khoản *',
            hint: 'VD: 9876543210',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập số tài khoản';
              }
              if (v.trim().length < 6) {
                return 'Số tài khoản phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Tên chủ tài khoản – tự động tra cứu qua Napas 247
          _AccountNameLookupField(
            controller: accountNameCtrl,
            lookupStatus: lookupStatus,
            lookupMessage: lookupMessage,
          ),
          const SizedBox(height: 20),

          // ── Nội dung chuyển khoản ──────────────────────────────────
          const _SectionHeader(
            icon: Icons.edit_note_rounded,
            title: 'Mẫu nội dung chuyển khoản',
            subtitle: 'Tự động điền vào nội dung CK của QR',
          ),
          const SizedBox(height: 12),

          _StyledField(
            controller: noteTemplateCtrl,
            label: 'Mẫu nội dung CK',
            hint: 'VD: Phong {room} thang {month}/{year}',
            icon: Icons.text_fields_rounded,
            helperText: 'Biến: {room} = phòng, {month}/{year} = tháng/năm',
          ),
          const SizedBox(height: 8),

          // Chip gợi ý placeholder
          Wrap(
            spacing: 6,
            children: [
              _PlaceholderChip(text: '{room}', ctrl: noteTemplateCtrl),
              _PlaceholderChip(text: '{month}', ctrl: noteTemplateCtrl),
              _PlaceholderChip(text: '{year}', ctrl: noteTemplateCtrl),
              _PlaceholderChip(text: '{amount}', ctrl: noteTemplateCtrl),
            ],
          ),
          const SizedBox(height: 20),

          // ── Preview QR ─────────────────────────────────────────────
          _QrPreviewCard(
            showQrPreview: showQrPreview,
            onToggle: onToggleQr,
            qrString: qrString,
            vietQrUrl: vietQrUrl,
            selectedBank: selectedBank,
            accountNumber: accountNumberCtrl.text,
            accountName: accountNameCtrl.text,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Tab Ví điện tử ─────────────────────────────────────────────────────────
class _WalletTab extends StatelessWidget {
  final TextEditingController momoPhoneCtrl;

  const _WalletTab({required this.momoPhoneCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Momo ──────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.phone_android_rounded,
            title: 'MoMo',
            subtitle: 'Khách thuê quét QR để chuyển tiền qua Momo',
          ),
          const SizedBox(height: 12),

          // Logo Momo card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFAD1457), Color(0xFFD81B60)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD81B60).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        color: Color(0xFFD81B60),
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MoMo E-Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Nhập SĐT đã đăng ký MoMo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _StyledField(
            controller: momoPhoneCtrl,
            label: 'Số điện thoại MoMo',
            hint: 'VD: 0901234567',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),

          // ── Thông tin ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_rounded, color: AppColors.info, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Tích hợp sắp ra mắt',
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'QR MoMo sẽ được hiển thị tự động trên trang thanh toán hóa đơn. Hiện tại SĐT được lưu lại để tích hợp sau.',
                  style: TextStyle(color: AppColors.info, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── QR Preview Card ───────────────────────────────────────────────────────
class _QrPreviewCard extends StatelessWidget {
  final bool showQrPreview;
  final VoidCallback onToggle;
  final String qrString;
  final String vietQrUrl;
  final BankInfo? selectedBank;
  final String accountNumber;
  final String accountName;

  const _QrPreviewCard({
    required this.showQrPreview,
    required this.onToggle,
    required this.qrString,
    required this.vietQrUrl,
    required this.selectedBank,
    required this.accountNumber,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final canPreview = selectedBank != null && accountNumber.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: canPreview
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: canPreview ? onToggle : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: canPreview
                          ? AppColors.primaryContainer
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      color: canPreview
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xem trước mã QR',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          canPreview
                              ? 'Nhấn để xem QR chuyển khoản mẫu'
                              : 'Nhập thông tin ngân hàng trước',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canPreview)
                    Icon(
                      showQrPreview
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),

          // QR Content
          if (showQrPreview && canPreview)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            vietQrUrl,
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.qr_code_2_rounded,
                                    size: 100, color: Colors.grey),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                width: 180,
                                height: 180,
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                selectedBank?.name ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                accountNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                accountName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Nút copy số tài khoản
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: accountNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép số tài khoản!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: Text('Sao chép: $accountNumber'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ QR này là mẫu để kiểm tra. QR thực tế trên hóa đơn sẽ có số tiền và nội dung tự động.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.1, end: 0),
        ],
      ),
    );
  }
}

// ── Bank Dropdown ─────────────────────────────────────────────────────────
class _BankDropdown extends StatelessWidget {
  final BankInfo? selectedBank;
  final ValueChanged<BankInfo?> onChanged;

  const _BankDropdown({
    required this.selectedBank,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<BankInfo>(
      value: selectedBank,
      decoration: InputDecoration(
        labelText: 'Chọn ngân hàng *',
        prefixIcon: const Icon(Icons.account_balance_rounded),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      hint: const Text('-- Chọn ngân hàng --', style: TextStyle(color: Colors.black54)),
      isExpanded: true,
      style: const TextStyle(color: Colors.black),
      items: VietnamBanks.list.map((bank) {
        return DropdownMenuItem<BankInfo>(
          value: bank,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bank.code,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(bank.name,
                  style: const TextStyle(fontSize: 14, color: Colors.black)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Vui lòng chọn ngân hàng' : null,
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Styled Text Field ─────────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final String? helperText;
  final TextCapitalization textCapitalization;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.helperText,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Account Name Lookup Field ────────────────────────────────────────────
/// Field tên tài khoản có tích hợp tra cứu tự động qua Napas 247.
/// - Hiển thị spinner khi đang tra cứu
/// - Chip xanh khi xác minh thành công
/// - Cảnh báo cam khi lỗi (vẫn cho nhập tay)
class _AccountNameLookupField extends StatelessWidget {
  final TextEditingController controller;
  final _LookupStatus lookupStatus;
  final String lookupMessage;

  const _AccountNameLookupField({
    required this.controller,
    required this.lookupStatus,
    required this.lookupMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = lookupStatus == _LookupStatus.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.black),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Vui lòng nhập tên chủ tài khoản';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Tên chủ tài khoản *',
            hintText: 'VD: NGUYEN VAN A',
            prefixIcon: const Icon(Icons.person_rounded),
            suffixIcon: _buildSuffixIcon(),
            filled: true,
            fillColor: isSuccess
                ? const Color(0xFFE8F5E9)
                : AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isSuccess
                  ? const BorderSide(color: Color(0xFF4CAF50), width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isSuccess
                    ? const Color(0xFF2E7D32)
                    : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        // ── Chip trạng thái ──────────────────────────────────────────────
        if (lookupStatus != _LookupStatus.idle) ...[const SizedBox(height: 6), _buildStatusRow()],
      ],
    );
  }

  Widget _buildSuffixIcon() {
    switch (lookupStatus) {
      case _LookupStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _LookupStatus.success:
        return const Icon(
          Icons.verified_rounded,
          color: Color(0xFF43A047),
          size: 22,
        );
      case _LookupStatus.error:
        return const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFF57C00),
          size: 22,
        );
      case _LookupStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusRow() {
    switch (lookupStatus) {
      case _LookupStatus.loading:
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '🔍 Đang tra cứu qua Napas 247...',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primary.withValues(alpha: 0.85),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      case _LookupStatus.success:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4CAF50)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF43A047), size: 14),
              SizedBox(width: 5),
              Text(
                'Đã xác minh qua Napas 247',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case _LookupStatus.error:
        return Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFF57C00),
              size: 13,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                lookupMessage,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          ],
        );
      case _LookupStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

// ── Placeholder Chip ──────────────────────────────────────────────────────
class _PlaceholderChip extends StatelessWidget {
  final String text;
  final TextEditingController ctrl;

  const _PlaceholderChip({required this.text, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppColors.primary),
      ),
      backgroundColor: AppColors.primaryContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        final current = ctrl.text;
        ctrl.text = current.isEmpty ? text : '$current $text';
        ctrl.selection = TextSelection.fromPosition(
          TextPosition(offset: ctrl.text.length),
        );
      },
    );
  }
}

// ── Save Button ───────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveButton({required this.isSaving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: isSaving ? null : onSave,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded),
          label: Text(
            isSaving ? 'Đang lưu...' : 'Lưu cài đặt thanh toán',
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
