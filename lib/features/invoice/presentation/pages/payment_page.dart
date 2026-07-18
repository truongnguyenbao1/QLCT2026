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

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment.dart';
import '../bloc/invoice_bloc.dart';

class PaymentPage extends StatefulWidget {
  final String invoiceId;
  const PaymentPage({super.key, required this.invoiceId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _transactionIdController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.bankTransfer;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    // Load lịch sử giao dịch
    context.read<InvoiceBloc>().add(LoadPaymentsEvent(widget.invoiceId));
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
        title: const Text('Thanh toán hóa đơn'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocConsumer<InvoiceBloc, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceActionSuccess) {
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
          // Tìm hóa đơn từ state
          Invoice? invoice;
          if (state is InvoiceDetailLoaded) {
            invoice = state.invoice;
          }

          if (invoice == null) {
            return const Center(child: CircularProgressIndicator());
          }

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
                _VietQrCard(invoice: invoice)
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
                    onSubmit: () => _submitPayment(invoice!),
                    isLoading: state is PaymentCreating,
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 16),
                ],

                if (!isOwner && !invoice.isPaid) ...[
                  const _TenantInfoCard()
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
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    invoice.billingPeriod,
                    style: const TextStyle(
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
                  style: const TextStyle(
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
            style: const TextStyle(
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
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── VietQR Card ───────────────────────────────────────────────────────────
class _VietQrCard extends StatelessWidget {
  final Invoice invoice;
  const _VietQrCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    // VietQR placeholder QR - encode invoice info
    final qrContent =
        'PAYMENT:${invoice.id}:${invoice.totalAmount}:${invoice.roomNumber}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Quét mã VietQR để chuyển khoản',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
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
              child: QrImageView(
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
                const Icon(Icons.info_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Nội dung CK: Phong ${invoice.roomNumber} T${invoice.month}/${invoice.year}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            'Phong ${invoice.roomNumber} T${invoice.month}/${invoice.year}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép!')),
                    );
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 14, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
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
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ghi nhận thanh toán',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary),
                      ),
                      Text(
                        'Chỉ dành cho chủ trọ',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
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
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
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
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          avatar: Icon(
                            _methodIcon(method),
                            size: 16,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
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
                        prefixIcon: const Icon(Icons.tag_rounded),
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
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(
                          isLoading
                              ? 'Đang xử lý...'
                              : '✅ Xác nhận đã nhận tiền',
                          style: const TextStyle(
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

// ── Thông tin cho tenant ──────────────────────────────────────────────────
class _TenantInfoCard extends StatelessWidget {
  const _TenantInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_rounded, color: AppColors.info, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sau khi chuyển khoản, bấm "Tôi đã chuyển tiền" ở trang chi tiết hóa đơn để thông báo chủ trọ.',
              style: TextStyle(color: AppColors.info, fontSize: 13),
            ),
          ),
        ],
      ),
    );
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
                  child: const Icon(Icons.history_rounded,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Lịch sử giao dịch',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary),
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
                    return const _EmptyPayments();
                  }
                  return Column(
                    children: state.payments
                        .map((p) => _PaymentTile(payment: p))
                        .toList(),
                  );
                }
                if (state is InvoicesLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const _EmptyPayments();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  const _EmptyPayments();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 40, color: AppColors.textTertiary),
            SizedBox(height: 8),
            Text(
              'Chưa có giao dịch nào',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.paymentMethod.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary),
                ),
                if (payment.transactionId != null)
                  Text(
                    'Mã GD: ${payment.transactionId}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                Text(
                  AppFormatters.formatDateTime(payment.paidAt),
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.formatCurrency(payment.amount),
            style: const TextStyle(
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
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
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
