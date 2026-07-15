// lib/core/widgets/print_dialog.dart
// ─────────────────────────────────────────────────────────────────────────────
//  Dialog chọn máy in và kiểu in (biên lai nhiệt 80mm hoặc A4)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../features/invoice/domain/entities/invoice.dart';
import '../constants/app_colors.dart';
import '../services/printer_service.dart';

class PrintInvoiceDialog extends StatefulWidget {
  final Invoice invoice;

  const PrintInvoiceDialog({super.key, required this.invoice});

  static Future<void> show(BuildContext context, Invoice invoice) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrintInvoiceDialog(invoice: invoice),
    );
  }

  @override
  State<PrintInvoiceDialog> createState() => _PrintInvoiceDialogState();
}

class _PrintInvoiceDialogState extends State<PrintInvoiceDialog> {
  List<Printer> _printers = [];
  Printer? _selectedPrinter;
  bool _isLoading = true;
  bool _isPrinting = false;
  _PrintMode _printMode = _PrintMode.thermal;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    final printers = await PrinterService.listPrinters();
    if (mounted) {
      setState(() {
        _printers = printers;
        _isLoading = false;
        // Tự động chọn XP-80C nếu có
        try {
          _selectedPrinter = printers.firstWhere(
            (p) =>
                p.name.toLowerCase().contains('xp-80') ||
                p.name.toLowerCase().contains('xp80'),
          );
        } catch (_) {
          _selectedPrinter = printers.isNotEmpty ? printers.first : null;
        }
      });
    }
  }

  Future<void> _print() async {
    setState(() => _isPrinting = true);
    try {
      if (_printMode == _PrintMode.dialog) {
        // In với dialog chọn máy in của hệ thống
        final ok = await PrinterService.printInvoiceWithDialog(widget.invoice);
        _showResult(ok);
      } else if (_selectedPrinter != null) {
        // In trực tiếp không qua dialog
        final pdfBytes = _printMode == _PrintMode.thermal
            ? await PrinterService.generateReceiptPdf(widget.invoice)
            : await PrinterService.generateA4Pdf(widget.invoice);

        final ok = await PrinterService.printDirectly(
          printer: _selectedPrinter!,
          pdfBytes: pdfBytes,
          jobName:
              'HoaDon_P${widget.invoice.roomNumber}_T${widget.invoice.month}',
        );
        _showResult(ok);
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showResult(bool success) {
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ Đã gửi lệnh in thành công!' : '❌ In thất bại. Kiểm tra máy in.'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _shareAsPdf() async {
    Navigator.pop(context);
    await PrinterService.shareInvoice(widget.invoice);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ─────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.print_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('In hóa đơn', style: theme.textTheme.titleLarge),
                  Text(
                    'Phòng ${widget.invoice.roomNumber} • Tháng ${widget.invoice.month}/${widget.invoice.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Kiểu in ────────────────────────────────────────────────────
          Text('Kiểu in', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              _ModeChip(
                label: '🖨 Biên lai\n80mm',
                selected: _printMode == _PrintMode.thermal,
                onTap: () => setState(() => _printMode = _PrintMode.thermal),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: '📄 A4/A5\nĐầy đủ',
                selected: _printMode == _PrintMode.a4,
                onTap: () => setState(() => _printMode = _PrintMode.a4),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: '🔍 Chọn\nmáy in',
                selected: _printMode == _PrintMode.dialog,
                onTap: () => setState(() => _printMode = _PrintMode.dialog),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Chọn máy in ────────────────────────────────────────────────
          if (_printMode != _PrintMode.dialog) ...[
            Text('Máy in', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_printers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Không tìm thấy máy in.\nKiểm tra máy in XP-80C đã kết nối chưa.',
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Printer>(
                    value: _selectedPrinter,
                    isExpanded: true,
                    hint: const Text('Chọn máy in'),
                    items: _printers.map((p) {
                      final isXP80 = p.name.toLowerCase().contains('xp-80') ||
                          p.name.toLowerCase().contains('xp80');
                      return DropdownMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Icon(
                              Icons.print_rounded,
                              size: 18,
                              color: isXP80
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis)),
                            if (isXP80)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Khuyên dùng',
                                  style: TextStyle(
                                      fontSize: 10, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (p) => setState(() => _selectedPrinter = p),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // ── Nút in ─────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: (_isPrinting ||
                      (_printMode != _PrintMode.dialog &&
                          _selectedPrinter == null))
                  ? null
                  : _print,
              icon: _isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.print_rounded),
              label: Text(_isPrinting ? 'Đang in...' : 'In ngay'),
            ),
          ),
          const SizedBox(height: 12),

          // ── Nút chia sẻ ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _isPrinting ? null : _shareAsPdf,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Chia sẻ / Lưu PDF'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

enum _PrintMode { thermal, a4, dialog }

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
