// lib/features/invoice/presentation/pages/invoice_detail_page.dart
// ─────────────────────────────────────────────────────────────────────────────
//  Trang chi tiết hóa đơn: hiển thị breakdown đầy đủ, nút xác nhận thanh toán
//  song phương, và liên kết đến trang thanh toán QR
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/print_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/invoice.dart';
import '../bloc/invoice_bloc.dart';

class InvoiceDetailPage extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvoiceBloc>(
      create: (_) => getIt<InvoiceBloc>()
        ..add(LoadInvoiceDetailEvent(invoiceId)),
      child: const _InvoiceDetailView(),
    );
  }
}

class _InvoiceDetailView extends StatelessWidget {
  const _InvoiceDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is InvoiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is InvoiceDetailLoaded) {
          return _InvoiceDetailContent(invoice: state.invoice);
        }
        if (state is InvoicesLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const Scaffold(
          body: Center(child: Text('Không tìm thấy hóa đơn')),
        );
      },
    );
  }
}

class _InvoiceDetailContent extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceDetailContent({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated &&
        authState.user.isOwner;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hóa đơn ${invoice.billingPeriod}'),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () async {
                await PrintInvoiceDialog.show(context, invoice);
              },
              tooltip: 'In / Chia sẻ hóa đơn',
            ),
            IconButton(
              icon: const Icon(Icons.print_rounded),
              onPressed: () => PrintInvoiceDialog.show(context, invoice),
              tooltip: 'In hóa đơn',
              color: AppColors.primary,
            ),
          ],
          if (!invoice.isPaid && isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showPasswordConfirmationDialog(context, 'Sửa hóa đơn', () {
                    context.push('/invoices/${invoice.id}/edit', extra: invoice);
                  });
                } else if (value == 'delete') {
                  _showPasswordConfirmationDialog(context, 'Xóa hóa đơn', () {
                    context.read<InvoiceBloc>().add(DeleteInvoiceEvent(invoice.id));
                    context.pop(); // Quay lại trang danh sách
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Sửa hóa đơn'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Xóa hóa đơn', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Status Banner ──────────────────────────────────────────
            _StatusBanner(invoice: invoice)
                .animate()
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // ── Invoice Header Card ────────────────────────────────────
            _InvoiceHeaderCard(invoice: invoice)
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // ── Breakdown Card ─────────────────────────────────────────
            _BreakdownCard(invoice: invoice)
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // ── Total Card ─────────────────────────────────────────────
            _TotalCard(invoice: invoice)
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // ── Action Buttons ─────────────────────────────────────────
            if (!invoice.isPaid) ...[
              _ActionButtons(invoice: invoice, isOwner: isOwner)
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 300.ms)
                  .slideY(begin: 0.2),
            ] else ...[
              _PaidConfirmation(invoice: invoice, isOwner: isOwner)
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 300.ms),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showPasswordConfirmationDialog(BuildContext context, String actionName, VoidCallback onSuccess) {
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
                  Text(
                    'Vui lòng nhập mật khẩu của bạn để xác nhận $actionName.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                            await getIt<SupabaseClient>().auth.signInWithPassword(
                              email: adminEmail,
                              password: password,
                            );

                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              onSuccess();
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
}

// ── Status Banner ─────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final Invoice invoice;
  const _StatusBanner({required this.invoice});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    if (invoice.isPaid) {
      bgColor = AppColors.successContainer;
      textColor = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (invoice.isOverdue) {
      bgColor = AppColors.errorContainer;
      textColor = AppColors.error;
      icon = Icons.warning_rounded;
    } else if (invoice.status == InvoiceStatus.confirmedByTenant) {
      bgColor = AppColors.infoContainer;
      textColor = AppColors.info;
      icon = Icons.pending_actions_rounded;
    } else {
      bgColor = AppColors.warningContainer;
      textColor = AppColors.warning;
      icon = Icons.access_time_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.status.displayName,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (!invoice.isPaid)
                Text(
                  'Hạn thanh toán: ${AppFormatters.formatDate(invoice.dueDate)} (${AppFormatters.formatDaysUntil(invoice.dueDate)})',
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              if (invoice.isPaid && invoice.paidAt != null)
                Text(
                  'Đã thanh toán: ${AppFormatters.formatDateTime(invoice.paidAt!)}',
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Invoice Header Card ───────────────────────────────────────────────────
class _InvoiceHeaderCard extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceHeaderCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hóa đơn ${invoice.billingPeriod}',
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      'Phòng ${invoice.roomNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Khách thuê',
              value: invoice.tenantName ?? 'Chưa có khách thuê',
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Kỳ thanh toán',
              value: invoice.billingPeriod,
            ),
            _InfoRow(
              icon: Icons.numbers_rounded,
              label: 'Mã hóa đơn',
              value: invoice.id.substring(0, 8).toUpperCase(),
              onCopy: () {
                Clipboard.setData(ClipboardData(text: invoice.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép mã hóa đơn!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Breakdown Card ────────────────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final Invoice invoice;
  const _BreakdownCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiết hóa đơn', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),

            // Tiền thuê phòng
            _LineItem(
              icon: Icons.home_outlined,
              label: 'Tiền phòng',
              value: AppFormatters.formatCurrency(invoice.rentAmount),
              iconColor: AppColors.primary,
            ),

            const Divider(height: 24),

            // Điện
            Text(
              '⚡ Điện',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _MeterRow(
              label: 'Chỉ số cũ',
              value: AppFormatters.formatElectric(invoice.electricPrevReading),
            ),
            _MeterRow(
              label: 'Chỉ số mới',
              value: AppFormatters.formatElectric(invoice.electricCurrReading),
            ),
            _MeterRow(
              label: 'Tiêu thụ',
              value: AppFormatters.formatElectric(invoice.electricUnitsUsed),
              bold: true,
            ),
            _MeterRow(
              label: 'Đơn giá',
              value:
                  '${AppFormatters.formatCurrency(invoice.electricUnitPrice)}/kWh',
            ),
            _LineItem(
              icon: Icons.bolt_rounded,
              label: 'Thành tiền điện',
              value: AppFormatters.formatCurrency(invoice.electricAmount),
              iconColor: AppColors.warning,
            ),

            const Divider(height: 24),

            // Nước
            Text(
              '💧 Nước',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _MeterRow(
              label: 'Chỉ số cũ',
              value: AppFormatters.formatWater(invoice.waterPrevReading),
            ),
            _MeterRow(
              label: 'Chỉ số mới',
              value: AppFormatters.formatWater(invoice.waterCurrReading),
            ),
            _MeterRow(
              label: 'Tiêu thụ',
              value: AppFormatters.formatWater(invoice.waterUnitsUsed),
              bold: true,
            ),
            _MeterRow(
              label: 'Đơn giá',
              value:
                  '${AppFormatters.formatCurrency(invoice.waterUnitPrice)}/m³',
            ),
            _LineItem(
              icon: Icons.water_drop_outlined,
              label: 'Thành tiền nước',
              value: AppFormatters.formatCurrency(invoice.waterAmount),
              iconColor: AppColors.info,
            ),

            if (invoice.serviceAmount > 0) ...[
              const Divider(height: 24),
              _LineItem(
                icon: Icons.miscellaneous_services_rounded,
                label: 'Phí dịch vụ',
                value: AppFormatters.formatCurrency(invoice.serviceAmount),
                iconColor: AppColors.secondary,
              ),
            ],

            if (invoice.otherAmount != null && invoice.otherAmount! > 0) ...[
              const Divider(height: 24),
              _LineItem(
                icon: Icons.add_circle_outline,
                label: invoice.otherDescription ?? 'Phí khác',
                value: AppFormatters.formatCurrency(invoice.otherAmount!),
                iconColor: AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Total Card ────────────────────────────────────────────────────────────
class _TotalCard extends StatelessWidget {
  final Invoice invoice;
  const _TotalCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TỔNG CỘNG',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Số tiền phải thanh toán',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          Text(
            AppFormatters.formatCurrency(invoice.totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final Invoice invoice;
  final bool isOwner;
  const _ActionButtons({required this.invoice, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceBloc, InvoiceState>(
      builder: (context, state) {
        final isLoading = state is InvoicesLoading;

        return Column(
          children: [


            if (isOwner &&
                invoice.status == InvoiceStatus.confirmedByTenant) ...[
              // Owner xác nhận đã nhận tiền
              Text(
                '💬 Khách thuê đã xác nhận chuyển tiền. Vui lòng kiểm tra và xác nhận đã nhận.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (invoice.paymentImageUrl != null && invoice.paymentImageUrl!.isNotEmpty) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.image_search_rounded),
                  label: const Text('Xem biên lai đính kèm'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.network(invoice.paymentImageUrl!),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.verified_rounded),
                label: const Text('✅ Xác nhận đã nhận tiền'),
                onPressed: isLoading ? null : () {
                  _showConfirmDialog(
                    context,
                    title: 'Xác nhận đã nhận tiền',
                    message:
                        'Bạn xác nhận đã nhận đủ ${AppFormatters.formatCurrency(invoice.totalAmount)}?',
                    onConfirm: () {
                      context.read<InvoiceBloc>().add(
                            MarkInvoicePaidEvent(invoiceId: invoice.id),
                          );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
            ],

            // Nút thanh toán QR - luôn hiển thị khi chưa paid
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/invoices/${invoice.id}/payment',
              ),
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Thanh toán qua QR / Chuyển khoản'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

// ── Paid Confirmation Banner ──────────────────────────────────────────────
class _PaidConfirmation extends StatelessWidget {
  final Invoice invoice;
  final bool isOwner;
  const _PaidConfirmation({required this.invoice, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Hóa đơn đã được thanh toán đầy đủ',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          if (invoice.paidAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ngày thanh toán: ${AppFormatters.formatDateTime(invoice.paidAt!)}',
              style: const TextStyle(color: AppColors.success, fontSize: 13),
            ),
          ],
          if (invoice.paymentMethod != null) ...[
            const SizedBox(height: 4),
            Text(
              'Phương thức: ${invoice.paymentMethod}',
              style: const TextStyle(color: AppColors.success, fontSize: 13),
            ),
          ],
          if (invoice.paymentImageUrl != null && invoice.paymentImageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.image_search_rounded),
              label: const Text('Xem biên lai đính kèm'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.network(invoice.paymentImageUrl!),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: Colors.black54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          if (isOwner) ...[
            const SizedBox(height: 16),
            // Nút in biên lai thanh toán
            OutlinedButton.icon(
              onPressed: () => PrintInvoiceDialog.show(context, invoice),
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('In biên lai'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ── Helper Widgets ────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}

class _MeterRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _MeterRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  const _LineItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
