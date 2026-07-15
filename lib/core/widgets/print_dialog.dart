// lib/core/widgets/print_dialog.dart
// ─────────────────────────────────────────────────────────────────────────────
//  Dialog in hóa đơn — xử lý đúng cả Flutter Web và Desktop
//
//  🌐 Flutter Web:  Printing.listPrinters() KHÔNG hỗ trợ. In qua trình duyệt.
//  🖥 Flutter Desktop (Windows): listPrinters() hoạt động → in trực tiếp.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart' show kIsWeb;
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
  // Web chỉ hỗ trợ in qua trình duyệt nên luôn dùng mode browser
  _PrintSize _printSize = _PrintSize.thermal;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Trên web không cần load máy in
      setState(() => _isLoading = false);
    } else {
      _loadPrinters();
    }
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
                p.name.toLowerCase().contains('xp80') ||
                p.name.toLowerCase().contains('xp 80'),
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
      // Tạo PDF theo kích thước đã chọn
      final pdfBytes = _printSize == _PrintSize.thermal
          ? await PrinterService.generateReceiptPdf(widget.invoice)
          : await PrinterService.generateA4Pdf(widget.invoice);

      bool ok;

      if (kIsWeb || _selectedPrinter == null) {
        // 🌐 Web hoặc không có máy in: in qua dialog trình duyệt
        ok = await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name:
              'HoaDon_P${widget.invoice.roomNumber}_T${widget.invoice.month}_${widget.invoice.year}',
          format: _printSize == _PrintSize.thermal
              ? const PdfPageFormat(
                  80 * PdfPageFormat.mm,
                  double.infinity,
                  marginAll: 4 * PdfPageFormat.mm,
                )
              : PdfPageFormat.a5,
        );
      } else {
        // 🖥 Desktop: in trực tiếp tới máy in đã chọn
        ok = await PrinterService.printDirectly(
          printer: _selectedPrinter!,
          pdfBytes: pdfBytes,
          jobName:
              'HoaDon_P${widget.invoice.roomNumber}_T${widget.invoice.month}',
        );
      }

      _showResult(ok);
    } catch (e) {
      _showResult(false);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showResult(bool success) {
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Đã gửi lệnh in thành công!'
              : '❌ In thất bại. Kiểm tra máy in.',
        ),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                child: const Icon(
                  Icons.print_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('In hóa đơn', style: theme.textTheme.titleLarge),
                    Text(
                      'Phòng ${widget.invoice.roomNumber} • Tháng ${widget.invoice.month}/${widget.invoice.year}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Banner thông báo khi chạy Web ──────────────────────────────
          if (kIsWeb)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ứng dụng đang chạy trên trình duyệt.\n'
                      'Nhấn "In ngay" → chọn máy in XP-80C trong hộp thoại của trình duyệt.',
                      style: TextStyle(color: Colors.blue, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),

          // ── Kích thước giấy ────────────────────────────────────────────
          Text('Kích thước giấy', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              _SizeChip(
                icon: '🖨',
                title: 'Biên lai',
                subtitle: '80mm nhiệt',
                selected: _printSize == _PrintSize.thermal,
                onTap: () => setState(() => _printSize = _PrintSize.thermal),
              ),
              const SizedBox(width: 10),
              _SizeChip(
                icon: '📄',
                title: 'A4 / A5',
                subtitle: 'Đầy đủ',
                selected: _printSize == _PrintSize.a4,
                onTap: () => setState(() => _printSize = _PrintSize.a4),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Chọn máy in (chỉ hiện trên Desktop) ──────────────────────
          if (!kIsWeb) ...[
            Text('Máy in', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_printers.isEmpty)
              _NoPrinterBanner(
                onRetry: () {
                  setState(() => _isLoading = true);
                  _loadPrinters();
                },
              )
            else
              _PrinterDropdown(
                printers: _printers,
                selected: _selectedPrinter,
                onChanged: (p) => setState(() => _selectedPrinter = p),
              ),
            const SizedBox(height: 20),
          ],

          // ── Nút In ─────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _isPrinting ? null : _print,
              icon: _isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print_rounded),
              label: Text(
                _isPrinting
                    ? 'Đang xử lý...'
                    : kIsWeb
                        ? 'In (qua trình duyệt)'
                        : _selectedPrinter != null
                            ? 'In ngay — ${_selectedPrinter!.name}'
                            : 'In (chọn máy in)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Nút Chia sẻ ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _isPrinting ? null : _shareAsPdf,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Chia sẻ / Lưu PDF'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
        ],
      ),
    );
  }
}

// ── Enums ─────────────────────────────────────────────────────────────────────
enum _PrintSize { thermal, a4 }

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _SizeChip extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoPrinterBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoPrinterBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.print_disabled_rounded,
              color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Không tìm thấy máy in',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Kiểm tra máy in XP-80C đã bật và kết nối với máy tính chưa.',
                  style: TextStyle(color: Colors.orange, fontSize: 11.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _PrinterDropdown extends StatelessWidget {
  final List<Printer> printers;
  final Printer? selected;
  final ValueChanged<Printer?> onChanged;

  const _PrinterDropdown({
    required this.printers,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Printer>(
          value: selected,
          isExpanded: true,
          hint: const Text('Chọn máy in'),
          items: printers.map((p) {
            final isXP80 = p.name.toLowerCase().contains('xp-80') ||
                p.name.toLowerCase().contains('xp80') ||
                p.name.toLowerCase().contains('xp 80');
            return DropdownMenuItem(
              value: p,
              child: Row(
                children: [
                  Icon(
                    Icons.print_rounded,
                    size: 18,
                    color: isXP80 ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  ),
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
                        style:
                            TextStyle(fontSize: 10, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
