import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:intl/intl.dart';

@lazySingleton
class ThermalPrinterService {
  
  /// Lấy danh sách các thiết bị Bluetooth đã ghép nối
  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  /// Kiểm tra trạng thái kết nối
  Future<bool> get isConnected async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  /// Kết nối tới máy in
  Future<bool> connect(String macAddress) async {
    return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  /// Ngắt kết nối
  Future<bool> disconnect() async {
    return await PrintBluetoothThermal.disconnect;
  }

  /// Khởi tạo generator với khổ giấy (mặc định K58)
  Future<Generator> getGenerator({PaperSize size = PaperSize.mm58}) async {
    final profile = await CapabilityProfile.load();
    return Generator(size, profile);
  }

  /// Hàm tạo layout hóa đơn và trả về mảng byte (List<int>)
  /// Bạn có thể truyền dữ liệu thật của hóa đơn vào đây.
  Future<List<int>> generateInvoiceTicket({
    required String propertyName,
    required String roomName,
    required int month,
    required int year,
    required double totalAmount,
    required String invoiceId,
    String? paymentQrData,
  }) async {
    final generator = await getGenerator(size: PaperSize.mm58);
    List<int> bytes = [];

    // Header
    bytes += generator.text(propertyName,
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2));
    bytes += generator.emptyLines(1);
    bytes += generator.text('HOA DON TIEN PHONG',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Thang $month/$year - Phong: $roomName',
        styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.text('Ngay in: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.emptyLines(1);
    bytes += generator.hr();

    // Chi tiết (Giả lập một vài thông tin)
    bytes += generator.row([
      PosColumn(text: 'Tien phong:', width: 6),
      PosColumn(
          text: NumberFormat.currency(locale: 'vi', symbol: 'VND').format(totalAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr();
    bytes += generator.emptyLines(1);

    // QR Code (Nếu có dữ liệu QR VietQR hoặc Link)
    if (paymentQrData != null && paymentQrData.isNotEmpty) {
      bytes += generator.text('Ma QR Tra Cuu / Thanh Toan:',
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.emptyLines(1);
      bytes += generator.qrcode(paymentQrData, size: QRSize.Size6);
      bytes += generator.emptyLines(1);
    }

    // Mã hóa đơn
    bytes += generator.text('Ma HD: $invoiceId',
        styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.emptyLines(1);
    bytes += generator.text('Cam on quy khach!',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    
    // Đẩy giấy lên để cắt không bị phạm chữ
    bytes += generator.emptyLines(3);

    // Lệnh cắt giấy tự động (Cắt một phần)
    bytes += generator.cut();

    return bytes;
  }

  /// Gửi lệnh in (Mảng byte) tới máy in đã kết nối
  Future<bool> printTicket(List<int> bytes) async {
    bool connected = await isConnected;
    if (!connected) return false;
    return await PrintBluetoothThermal.writeBytes(bytes);
  }
}
