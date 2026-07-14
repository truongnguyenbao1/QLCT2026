import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/invoice/domain/entities/invoice.dart';
import 'formatters.dart';

class PdfGenerator {
  static Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // Load fonts that support Vietnamese
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
              pw.Text('Phòng: ${invoice.roomNumber}', style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.Text('Khách thuê: ${invoice.tenantName ?? "Không rõ"}', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(font: fontBold),
                cellStyle: pw.TextStyle(font: font),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                data: <List<String>>[
                  ['Mô tả', 'Thành tiền'],
                  ['Tiền phòng', AppFormatters.formatCurrency(invoice.rentAmount)],
                  if (invoice.serviceAmount > 0)
                    ['Phí dịch vụ', AppFormatters.formatCurrency(invoice.serviceAmount)],
                  [
                    'Tiền điện (${invoice.electricCurrReading} - ${invoice.electricPrevReading} = ${invoice.electricUnitsUsed} kWh)',
                    AppFormatters.formatCurrency(invoice.electricAmount)
                  ],
                  [
                    'Tiền nước (${invoice.waterCurrReading} - ${invoice.waterPrevReading} = ${invoice.waterUnitsUsed} m³)',
                    AppFormatters.formatCurrency(invoice.waterAmount)
                  ],
                  if ((invoice.otherAmount ?? 0) > 0)
                    ['Các khoản khác: ${invoice.otherDescription ?? ""}', AppFormatters.formatCurrency(invoice.otherAmount!)],
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
                    style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.red800),
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
                      pw.Text('Người lập phiếu', style: pw.TextStyle(font: font)),
                      pw.SizedBox(height: 40),
                      pw.Text('(Ký, ghi rõ họ tên)', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Người thanh toán', style: pw.TextStyle(font: font)),
                      pw.SizedBox(height: 40),
                      pw.Text('(Ký, ghi rõ họ tên)', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                    ]
                  ),
                ]
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
