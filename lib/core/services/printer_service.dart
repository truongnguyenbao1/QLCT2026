// lib/core/services/printer_service.dart
// ─────────────────────────────────────────────────────────────────────────────
//  Dịch vụ in hóa đơn: hỗ trợ máy in nhiệt (80mm như XP-80C) và in PDF
//  Sử dụng package `printing` để in trực tiếp mà không cần dialog
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/invoice/domain/entities/invoice.dart';
import '../utils/formatters.dart';

class PrinterService {
  /// Tên máy in nhiệt mặc định (XP-80C)
  static const String defaultThermalPrinter = 'XP-80C';

  // ── Danh sách máy in ────────────────────────────────────────────────────
  /// Lấy danh sách tất cả máy in đang kết nối
  static Future<List<Printer>> listPrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (e) {
      debugPrint('Lỗi lấy danh sách máy in: $e');
      return [];
    }
  }

  /// Tìm máy in theo tên (không phân biệt hoa thường)
  static Future<Printer?> findPrinterByName(String name) async {
    final printers = await listPrinters();
    try {
      return printers.firstWhere(
        (p) => p.name.toLowerCase().contains(name.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  // ── In trực tiếp tới máy in ──────────────────────────────────────────────
  /// In PDF trực tiếp tới máy in được chọn (không hiện dialog)
  static Future<bool> printDirectly({
    required Printer printer,
    required Uint8List pdfBytes,
    String jobName = 'Hoa don',
  }) async {
    try {
      return await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => pdfBytes,
        name: jobName,
      );
    } catch (e) {
      debugPrint('Lỗi in trực tiếp: $e');
      return false;
    }
  }

  /// In hóa đơn lên máy in nhiệt 80mm (XP-80C hoặc máy in khác)
  static Future<PrintResult> printInvoiceToThermal({
    required Invoice invoice,
    String printerName = defaultThermalPrinter,
  }) async {
    try {
      // 1. Tạo PDF dạng phiếu nhiệt 80mm
      final pdfBytes = await generateReceiptPdf(invoice);

      // 2. Tìm máy in theo tên
      final printer = await findPrinterByName(printerName);

      if (printer == null) {
        return PrintResult(
          success: false,
          message: 'Không tìm thấy máy in "$printerName". '
              'Vui lòng kiểm tra kết nối máy in.',
        );
      }

      // 3. In trực tiếp
      final success = await printDirectly(
        printer: printer,
        pdfBytes: pdfBytes,
        jobName: 'HoaDon_Phong${invoice.roomNumber}_T${invoice.month}_${invoice.year}',
      );

      return PrintResult(
        success: success,
        message: success ? 'In hóa đơn thành công!' : 'In thất bại.',
      );
    } catch (e) {
      return PrintResult(success: false, message: 'Lỗi in: $e');
    }
  }

  /// In hóa đơn với dialog chọn máy in
  static Future<bool> printInvoiceWithDialog(Invoice invoice) async {
    try {
      final pdfBytes = await generateReceiptPdf(invoice);
      return await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'HoaDon_Phong${invoice.roomNumber}_T${invoice.month}_${invoice.year}',
        format: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
      );
    } catch (e) {
      debugPrint('Lỗi in với dialog: $e');
      return false;
    }
  }

  /// Chia sẻ hóa đơn PDF qua các ứng dụng khác
  static Future<void> shareInvoice(Invoice invoice) async {
    final pdfBytes = await generateA4Pdf(invoice);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'HoaDon_Phong${invoice.roomNumber}_T${invoice.month}_${invoice.year}.pdf',
    );
  }

  // ── Tạo PDF biên lai nhiệt 80mm ─────────────────────────────────────────
  static Future<Uint8List> generateReceiptPdf(Invoice invoice) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Kích thước giấy nhiệt 80mm (226pt x auto)
    const pageWidth = 72.0 * PdfPageFormat.mm; // 72mm vùng in (80mm - 8mm lề)
    const margin = 4.0 * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: margin,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ── Tiêu đề ──────────────────────────────────────────────
              pw.Text(
                'HOA DON TIEN NHA',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Ky: Thang ${invoice.month}/${invoice.year}',
                style: pw.TextStyle(font: font, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                _divider(pageWidth),
                style: pw.TextStyle(font: font, fontSize: 8),
              ),

              // ── Thông tin phòng ───────────────────────────────────────
              pw.SizedBox(height: 4),
              _receiptRow('Phong:', invoice.roomNumber, font, fontBold),
              _receiptRow(
                'Khach thue:',
                invoice.tenantName ?? 'Khong co',
                font,
                font,
              ),
              _receiptRow(
                'Ma HD:',
                '#${invoice.id.substring(0, 8).toUpperCase()}',
                font,
                font,
              ),
              pw.Text(
                _divider(pageWidth),
                style: pw.TextStyle(font: font, fontSize: 8),
              ),

              // ── Chi tiết ──────────────────────────────────────────────
              pw.SizedBox(height: 4),
              _receiptItem(
                'Tien phong',
                AppFormatters.formatCurrency(invoice.rentAmount),
                font,
                fontBold,
              ),

              if (invoice.serviceAmount > 0)
                _receiptItem(
                  'Phi dich vu',
                  AppFormatters.formatCurrency(invoice.serviceAmount),
                  font,
                  fontBold,
                ),

              // Điện
              pw.SizedBox(height: 4),
              pw.Text(
                '--- DIEN ---',
                style: pw.TextStyle(font: font, fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              _receiptRow(
                '  Chi so cu:',
                '${invoice.electricPrevReading.toStringAsFixed(0)} kWh',
                font,
                font,
              ),
              _receiptRow(
                '  Chi so moi:',
                '${invoice.electricCurrReading.toStringAsFixed(0)} kWh',
                font,
                font,
              ),
              _receiptRow(
                '  Tieu thu:',
                '${invoice.electricUnitsUsed.toStringAsFixed(0)} kWh',
                font,
                fontBold,
              ),
              _receiptRow(
                '  Don gia:',
                '${AppFormatters.formatCurrency(invoice.electricUnitPrice)}/kWh',
                font,
                font,
              ),
              _receiptItem(
                'Tien dien',
                AppFormatters.formatCurrency(invoice.electricAmount),
                font,
                fontBold,
              ),

              // Nước
              pw.SizedBox(height: 4),
              pw.Text(
                '--- NUOC ---',
                style: pw.TextStyle(font: font, fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              _receiptRow(
                '  Chi so cu:',
                '${invoice.waterPrevReading.toStringAsFixed(0)} m3',
                font,
                font,
              ),
              _receiptRow(
                '  Chi so moi:',
                '${invoice.waterCurrReading.toStringAsFixed(0)} m3',
                font,
                font,
              ),
              _receiptRow(
                '  Tieu thu:',
                '${invoice.waterUnitsUsed.toStringAsFixed(0)} m3',
                font,
                fontBold,
              ),
              _receiptRow(
                '  Don gia:',
                '${AppFormatters.formatCurrency(invoice.waterUnitPrice)}/m3',
                font,
                font,
              ),
              _receiptItem(
                'Tien nuoc',
                AppFormatters.formatCurrency(invoice.waterAmount),
                font,
                fontBold,
              ),

              // Phí khác
              if ((invoice.otherAmount ?? 0) > 0) ...[
                pw.SizedBox(height: 4),
                _receiptItem(
                  invoice.otherDescription ?? 'Phi khac',
                  AppFormatters.formatCurrency(invoice.otherAmount!),
                  font,
                  fontBold,
                ),
              ],

              pw.Text(
                _divider(pageWidth),
                style: pw.TextStyle(font: font, fontSize: 8),
              ),

              // ── Tổng cộng ─────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TONG CONG:',
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                  pw.Text(
                    AppFormatters.formatCurrency(invoice.totalAmount),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      color: PdfColors.red,
                    ),
                  ),
                ],
              ),
              pw.Text(
                _divider(pageWidth),
                style: pw.TextStyle(font: font, fontSize: 8),
              ),

              // ── Hạn thanh toán ───────────────────────────────────────
              pw.SizedBox(height: 4),
              _receiptRow(
                'Han thanh toan:',
                AppFormatters.formatDate(invoice.dueDate),
                font,
                fontBold,
              ),
              _receiptRow(
                'Trang thai:',
                invoice.status.displayName,
                font,
                font,
              ),

              // ── Chữ ký ───────────────────────────────────────────────
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Nguoi lap phieu',
                        style: pw.TextStyle(font: font, fontSize: 8),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Text(
                        '(Ky, ghi ro ho ten)',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Nguoi nhan',
                        style: pw.TextStyle(font: font, fontSize: 8),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Text(
                        '(Ky, ghi ro ho ten)',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Cam on quy khach! Hen gap lai.',
                style: pw.TextStyle(font: fontBold, fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),

              // ── Dòng kẻ cuối (để cắt giấy thủ công) ─────────────────
              pw.Text(
                '- - - - - - - - - - - - - - - - - - -',
                style: pw.TextStyle(font: font, fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Tạo PDF A4 đầy đủ ─────────────────────────────────────────────────────
  static Future<Uint8List> generateA4Pdf(Invoice invoice) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'HÓA ĐƠN TIỀN NHÀ',
                  style: pw.TextStyle(font: fontBold, fontSize: 20),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Kỳ hóa đơn: Tháng ${invoice.month}/${invoice.year}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Phòng: ${invoice.roomNumber}',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
              pw.Text(
                'Khách thuê: ${invoice.tenantName ?? "Không rõ"}',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.Text(
                'Mã hóa đơn: #${invoice.id.substring(0, 8).toUpperCase()}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.Text(
                'Hạn thanh toán: ${AppFormatters.formatDate(invoice.dueDate)}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(font: fontBold),
                cellStyle: pw.TextStyle(font: font),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey100),
                data: <List<String>>[
                  ['Mô tả', 'Thành tiền'],
                  [
                    'Tiền phòng',
                    AppFormatters.formatCurrency(invoice.rentAmount),
                  ],
                  if (invoice.serviceAmount > 0)
                    [
                      'Phí dịch vụ',
                      AppFormatters.formatCurrency(invoice.serviceAmount),
                    ],
                  [
                    'Tiền điện (${invoice.electricCurrReading.toStringAsFixed(0)} - ${invoice.electricPrevReading.toStringAsFixed(0)} = ${invoice.electricUnitsUsed.toStringAsFixed(0)} kWh × ${AppFormatters.formatCurrency(invoice.electricUnitPrice)})',
                    AppFormatters.formatCurrency(invoice.electricAmount),
                  ],
                  [
                    'Tiền nước (${invoice.waterCurrReading.toStringAsFixed(0)} - ${invoice.waterPrevReading.toStringAsFixed(0)} = ${invoice.waterUnitsUsed.toStringAsFixed(0)} m³ × ${AppFormatters.formatCurrency(invoice.waterUnitPrice)})',
                    AppFormatters.formatCurrency(invoice.waterAmount),
                  ],
                  if ((invoice.otherAmount ?? 0) > 0)
                    [
                      invoice.otherDescription ?? 'Phí khác',
                      AppFormatters.formatCurrency(invoice.otherAmount!),
                    ],
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Tổng cộng: ',
                    style: pw.TextStyle(font: font, fontSize: 16),
                  ),
                  pw.Text(
                    AppFormatters.formatCurrency(invoice.totalAmount),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.red800,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Người lập phiếu',
                        style: pw.TextStyle(font: font),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        '(Ký, ghi rõ họ tên)',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Người thanh toán',
                        style: pw.TextStyle(font: font),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        '(Ký, ghi rõ họ tên)',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static String _divider(double width) {
    return '=' * 32;
  }

  /// Row 2 cột: nhãn bên trái, giá trị bên phải
  static pw.Widget _receiptRow(
    String label,
    String value,
    pw.Font font,
    pw.Font valueFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9)),
        pw.Text(value, style: pw.TextStyle(font: valueFont, fontSize: 9)),
      ],
    );
  }

  /// Dòng khoản mục: tên hàng + số tiền in đậm bên phải
  static pw.Widget _receiptItem(
    String label,
    String amount,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9)),
          ),
          pw.Text(amount, style: pw.TextStyle(font: boldFont, fontSize: 9)),
        ],
      ),
    );
  }
}

// ── Kết quả in ───────────────────────────────────────────────────────────────
class PrintResult {
  final bool success;
  final String message;
  const PrintResult({required this.success, required this.message});
}
