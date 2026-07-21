// lib/features/invoice/presentation/pages/payment_page.dart
// ─────────────────────────────────────────────────────────────────────────────
//  Trang thanh toán hóa đơn (chỉ Admin/Owner mới được ghi nhận thanh toán)
//  - Hiển thị thông tin hóa đơn & QR VietQR
//  - Form ghi nhận thanh toán (Owner only)
//  - Lịch sử giao dịch từ bảng chitiethoadon
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment.dart';
import '../bloc/invoice_bloc.dart';
import '../../../../features/payment_settings/presentation/bloc/payment_settings_bloc.dart';
import '../../../../features/payment_settings/presentation/bloc/payment_settings_event.dart';
import '../../../../features/payment_settings/presentation/bloc/payment_settings_state.dart';
import '../../../../features/payment_settings/domain/entities/payment_settings.dart';

class PaymentPage extends StatefulWidget {
  final String invoiceId;
  const PaymentPage({super.key, required this.invoiceId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PaymentSettingsBloc>(
          create: (_) => getIt<PaymentSettingsBloc>(),
        ),
        BlocProvider<InvoiceBloc>(
          create: (_) => getIt<InvoiceBloc>()
            ..add(LoadInvoiceDetailEvent(widget.invoiceId))
            ..add(LoadPaymentsEvent(widget.invoiceId)),
        ),
      ],
      child: _PaymentPageContent(invoiceId: widget.invoiceId),
    );
  }
}

class _PaymentPageContent extends StatefulWidget {
  final String invoiceId;
  const _PaymentPageContent({required this.invoiceId});

  @override
  State<_PaymentPageContent> createState() => _PaymentPageContentState();
}

class _PaymentPageContentState extends State<_PaymentPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _transactionIdController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.bankTransfer;
  bool _showForm = false;
  Invoice? _invoice;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isOwner =
        authState is AuthAuthenticated && authState.user.isOwner;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Thanh toán hóa đơn'),
        backgroundColor: AppColors.surface,
        foregroundColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        elevation: 0,
      ),
      body: BlocConsumer<InvoiceBloc, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceDetailLoaded) {
            _invoice = state.invoice;
            
            // Tự động điền mã giao dịch cho chủ trọ nếu nó đang trống
            if (_transactionIdController.text.isEmpty) {
              final note = 'Phong ${_invoice!.roomNumber} thang ${_invoice!.month}/${_invoice!.year}';
              _transactionIdController.text = note;
            }
          } else if (state is InvoiceActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() => _showForm = false);
            _transactionIdController.clear();
          } else if (state is InvoiceError) {
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
          if (state is InvoiceDetailLoaded) {
            _invoice = state.invoice;
          }

          if (_invoice == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          final invoice = _invoice!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Banner tổng tiền ──────────────────────────────────
                _AmountBanner(invoice: invoice)
                    .animate()
                    .fadeIn(duration: 300.ms),

                const SizedBox(height: 16),

                // ── QR VietQR ─────────────────────────────────────────
                _PaymentMethodsSection(invoice: invoice)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms),

                const SizedBox(height: 16),

                // ── Form ghi nhận thanh toán (Owner only) ─────────────
                if (isOwner && !invoice.isPaid) ...[
                  _OwnerPaymentSection(
                    invoice: invoice,
                    showForm: _showForm,
                    onToggle: () => setState(() => _showForm = !_showForm),
                    formKey: _formKey,
                    transactionIdController: _transactionIdController,
                    selectedMethod: _selectedMethod,
                    onMethodChanged: (m) =>
                        setState(() => _selectedMethod = m!),
                    onSubmit: () => _submitPayment(invoice),
                    isLoading: state is PaymentCreating,
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 16),
                ],

                if (!isOwner && !invoice.isPaid) ...[
                  _TenantActionSection(invoice: invoice)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 16),
                ],

                // ── Lịch sử giao dịch ────────────────────────────────
                _PaymentHistorySection(invoiceId: widget.invoiceId)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitPayment(Invoice invoice) {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    final isOwner =
        authState is AuthAuthenticated && authState.user.isOwner;

    context.read<InvoiceBloc>().add(
          CreatePaymentEvent(
            invoiceId: invoice.id,
            amount: invoice.totalAmount,
            paymentMethod: _selectedMethod,
            transactionId: _transactionIdController.text.trim().isEmpty
                ? null
                : _transactionIdController.text.trim(),
            isOwner: isOwner,
          ),
        );
  }
}

// ── Banner tổng tiền ──────────────────────────────────────────────────────
class _AmountBanner extends StatelessWidget {
  final Invoice invoice;
  const _AmountBanner({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: invoice.isPaid
            ? LinearGradient(
                colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (invoice.isPaid ? AppColors.success : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phòng ${invoice.roomNumber}',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    invoice.billingPeriod,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  invoice.status.displayName,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppFormatters.formatCurrency(invoice.totalAmount),
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            invoice.isPaid
                ? 'Đã thanh toán'
                : 'Hạn: ${AppFormatters.formatDate(invoice.dueDate)}',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
// ── Phương thức thanh toán ───────────────────────────────────────────────
class _PaymentMethodsSection extends StatefulWidget {
  final Invoice invoice;
  const _PaymentMethodsSection({required this.invoice});

  @override
  State<_PaymentMethodsSection> createState() => _PaymentMethodsSectionState();
}

class _PaymentMethodsSectionState extends State<_PaymentMethodsSection> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    String ownerId = widget.invoice.createdBy;
    if (ownerId.isEmpty) {
      try {
        final client = Supabase.instance.client;
        final res = await client
            .from('phong')
            .select('nhatro(owner_id)')
            .eq('id', widget.invoice.roomId)
            .single();
        ownerId = res['nhatro']['owner_id'] as String? ?? '';
      } catch (_) {}
    }
    if (mounted) {
      context.read<PaymentSettingsBloc>().add(LoadPaymentSettingsEvent(ownerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentSettingsBloc, PaymentSettingsState>(
      builder: (context, state) {
        if (state is PaymentSettingsLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        bool hasBank = false;
        bool hasMomo = false;
        PaymentSettings? settings;

        if (state is PaymentSettingsLoaded && state.settings != null) {
          settings = state.settings;
          hasBank = settings!.hasBankInfo;
          hasMomo = settings.hasMomo;
        }

        final noteRaw = settings?.transferNoteTemplate ?? 'Phong {room} thang {month}/{year}';
        final noteProcessed = noteRaw
            .replaceAll('{room}', widget.invoice.roomNumber)
            .replaceAll('{month}', widget.invoice.month.toString())
            .replaceAll('{year}', widget.invoice.year.toString());
        final amount = widget.invoice.totalAmount.toInt();

        // 1. Chỉ có Momo
        if (hasMomo && !hasBank) {
          return _MomoCard(
            invoice: widget.invoice, 
            phone: settings!.momoPhone ?? '', 
            momoQrUrl: settings.momoQrUrl, 
            amount: amount, 
            note: noteProcessed
          );
        }
        
        // 2. Chỉ có Bank hoặc không có gì (Fallback)
        if (!hasMomo && hasBank) {
          final accountName = settings!.accountName ?? '';
          final vietQrUrl = 'https://img.vietqr.io/image/${settings.bankCode!}-${settings.accountNumber!}-qr_only.png?accountName=${Uri.encodeComponent(accountName)}&addInfo=${Uri.encodeComponent(noteProcessed)}&amount=$amount';
          return _VietQrCard(invoice: widget.invoice, qrContent: vietQrUrl, isVietQrNetwork: true, noteProcessed: noteProcessed);
        }

        // 3. Có cả hai
        if (hasBank && hasMomo) {
          final accountName = settings!.accountName ?? '';
          final vietQrUrl = 'https://img.vietqr.io/image/${settings!.bankCode!}-${settings!.accountNumber!}-qr_only.png?accountName=${Uri.encodeComponent(accountName)}&addInfo=${Uri.encodeComponent(noteProcessed)}&amount=$amount';
          return DefaultTabController(
            length: 2,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: 'Ngân hàng', icon: Icon(Icons.account_balance_rounded, size: 18)),
                      Tab(text: 'Ví MoMo', icon: Icon(Icons.phone_android_rounded, size: 18)),
                    ],
                  ),
                  SizedBox(
                    height: 380, // Fixed height for tab view to prevent layout jump
                    child: TabBarView(
                      children: [
                        _VietQrCard(invoice: widget.invoice, qrContent: vietQrUrl, isVietQrNetwork: true, noteProcessed: noteProcessed, insideTab: true),
                        _MomoCard(
                          invoice: widget.invoice, 
                          phone: settings!.momoPhone ?? '', 
                          momoQrUrl: settings!.momoQrUrl, 
                          amount: amount, 
                          note: noteProcessed, 
                          insideTab: true
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 4. Fallback khi chưa cài đặt gì
        final qrContent = 'PAYMENT:${widget.invoice.id}:${widget.invoice.totalAmount}:${widget.invoice.roomNumber}';
        return _VietQrCard(invoice: widget.invoice, qrContent: qrContent, isVietQrNetwork: false, noteProcessed: noteProcessed);
      },
    );
  }
}

class _VietQrCard extends StatelessWidget {
  final Invoice invoice;
  final String qrContent;
  final bool isVietQrNetwork;
  final String noteProcessed;
  final bool insideTab;

  const _VietQrCard({
    required this.invoice,
    required this.qrContent,
    required this.isVietQrNetwork,
    required this.noteProcessed,
    this.insideTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.qr_code_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isVietQrNetwork 
                    ? 'Quét mã VietQR để chuyển khoản' 
                    : 'Chủ trọ chưa cài đặt thẻ ngân hàng',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: isVietQrNetwork
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      qrContent,
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.qr_code_2_rounded,
                              size: 100, color: Colors.grey),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 180,
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  )
                : QrImageView(
                    data: qrContent,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Nội dung CK: $noteProcessed',
                  style: TextStyle(
                      color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: noteProcessed));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép nội dung!')),
                  );
                },
                child: Icon(Icons.copy_rounded,
                    size: 14, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );

    if (insideTab) return content;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: content,
    );
  }
}

class _MomoCard extends StatelessWidget {
  final Invoice invoice;
  final String phone;
  final String? momoQrUrl;
  final int amount;
  final String note;
  final bool insideTab;

  const _MomoCard({
    required this.invoice,
    required this.phone,
    this.momoQrUrl,
    required this.amount,
    required this.note,
    this.insideTab = false,
  });

  @override
  Widget build(BuildContext context) {
    // Định dạng QR MoMo cá nhân: 2|99|SĐT|||0|0|SOTIEN|NOIDUNG
    final momoQrString = '2|99|$phone|||0|0|$amount|$note';
    
    final bool isCustomQr = momoQrUrl != null && momoQrUrl!.isNotEmpty;
    
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.phone_android_rounded,
                    color: Color(0xFFD81B60), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Quét mã qua ứng dụng MoMo',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isCustomQr)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Text(
                'Lưu ý: Bạn phải tự nhập số tiền thanh toán là ${AppFormatters.formatCurrency(amount.toDouble())}',
                style: TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: isCustomQr
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      momoQrUrl!,
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.qr_code_2_rounded,
                              size: 100, color: Colors.grey),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 180,
                          height: 180,
                          child: Center(child: CircularProgressIndicator(color: Color(0xFFD81B60))),
                        );
                      },
                    ),
                  )
                : QrImageView(
                    data: momoQrString,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFFD81B60),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFFD81B60),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          if (phone.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SĐT: ',
                  style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary), fontSize: 13),
                ),
              Text(
                phone,
                style: TextStyle(
                  color: Color(0xFFD81B60),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép SĐT MoMo!')),
                  );
                },
                child: Icon(Icons.copy_rounded,
                    size: 14, color: Color(0xFFD81B60)),
              ),
            ],
          ),
        ],
      ),
    );

    if (insideTab) return content;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: content,
    );
  }
}


// ── Section ghi nhận thanh toán (Owner only) ─────────────────────────────
class _OwnerPaymentSection extends StatelessWidget {
  final Invoice invoice;
  final bool showForm;
  final VoidCallback onToggle;
  final GlobalKey<FormState> formKey;
  final TextEditingController transactionIdController;
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod?> onMethodChanged;
  final VoidCallback onSubmit;
  final bool isLoading;

  const _OwnerPaymentSection({
    required this.invoice,
    required this.showForm,
    required this.onToggle,
    required this.formKey,
    required this.transactionIdController,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ghi nhận thanh toán',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                      ),
                      Text(
                        'Chỉ dành cho chủ trọ',
                        style: TextStyle(
                            fontSize: 11, color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(showForm
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                  label: Text(showForm ? 'Thu gọn' : 'Mở form'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            if (showForm) ...[
              const Divider(height: 24),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Số tiền (readonly = tổng hóa đơn)
                    _ReadonlyField(
                      label: 'Số tiền',
                      value: AppFormatters.formatCurrency(invoice.totalAmount),
                      icon: Icons.payments_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Phương thức thanh toán
                    Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PaymentMethod.values.map((method) {
                        final selected = method == selectedMethod;
                        return ChoiceChip(
                          label: Text(method.displayName),
                          selected: selected,
                          onSelected: (_) => onMethodChanged(method),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            fontWeight: FontWeight.w500,
                          ),
                          avatar: Icon(
                            _methodIcon(method),
                            size: 16,
                            color: selected
                                ? Colors.white
                                : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Mã giao dịch (tùy chọn)
                    TextFormField(
                      controller: transactionIdController,
                      decoration: InputDecoration(
                        labelText: 'Mã giao dịch (tùy chọn)',
                        hintText: 'VD: FT26199...',
                        prefixIcon: Icon(Icons.tag_rounded),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nút xác nhận
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: isLoading ? null : onSubmit,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.check_circle_rounded),
                        label: Text(
                          isLoading
                              ? 'Đang xử lý...'
                              : '✅ Xác nhận đã nhận tiền',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _methodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.momo:
        return Icons.phone_android_rounded;
      case PaymentMethod.vnpay:
        return Icons.credit_card_rounded;
    }
  }
}



// ── Lịch sử giao dịch ────────────────────────────────────────────────────
class _PaymentHistorySection extends StatelessWidget {
  final String invoiceId;
  const _PaymentHistorySection({required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.history_rounded,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Lịch sử giao dịch',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<InvoiceBloc, InvoiceState>(
              buildWhen: (prev, curr) =>
                  curr is PaymentsLoaded ||
                  curr is InvoiceActionSuccess ||
                  curr is InvoicesLoading,
              builder: (context, state) {
                if (state is PaymentsLoaded) {
                  if (state.payments.isEmpty) {
                    return _EmptyPayments();
                  }
                  return Column(
                    children: state.payments
                        .map((p) => _PaymentTile(payment: p))
                        .toList(),
                  );
                }
                if (state is InvoicesLoading) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _EmptyPayments();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  _EmptyPayments();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 40, color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textTertiary)),
            SizedBox(height: 8),
            Text(
              'Chưa có giao dịch nào',
              style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFC8E6C9), // successContainer 50%
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.paymentMethod.displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                ),
                if (payment.transactionId != null)
                  Text(
                    'Mã GD: ${payment.transactionId}',
                    style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary), fontSize: 11),
                  ),
                Text(
                  AppFormatters.formatDateTime(payment.paidAt),
                  style: TextStyle(
                      color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textTertiary), fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.formatCurrency(payment.amount),
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────
class _ReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReadonlyField(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Thông tin cho tenant ──────────────────────────────────────────────────
class _TenantActionSection extends StatefulWidget {
  final Invoice invoice;
  const _TenantActionSection({required this.invoice});

  @override
  State<_TenantActionSection> createState() => _TenantActionSectionState();
}

class _TenantActionSectionState extends State<_TenantActionSection> {
  bool _isConfirming = false;

  void _confirmPayment() {
    setState(() => _isConfirming = true);
    final updatedInvoice = widget.invoice.copyWith(status: InvoiceStatus.confirmedByTenant);
    context.read<InvoiceBloc>().add(UpdateInvoiceEvent(updatedInvoice));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.invoice.status == InvoiceStatus.confirmedByTenant) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_empty_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bạn đã xác nhận chuyển khoản. Vui lòng chờ chủ trọ kiểm tra và cập nhật trạng thái hóa đơn.',
                style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.info_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sau khi hoàn tất chuyển khoản, hãy nhấn nút bên dưới để thông báo cho chủ trọ.',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _isConfirming ? null : _confirmPayment,
              icon: _isConfirming
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isConfirming ? 'Đang xử lý...' : 'Xác nhận đã chuyển khoản',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
