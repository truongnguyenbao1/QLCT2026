// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  // ── Tiền tệ VND ──────────────────────────────────────────────────────────
  // Dùng getter để tránh khởi tạo sớm trước initializeDateFormatting()
  static NumberFormat get _currencyFormatter => NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static NumberFormat get _numberFormatter => NumberFormat('#,##0', 'vi_VN');

  /// Định dạng tiền tệ: 1500000 → "1.500.000 ₫"
  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Định dạng số: 1500000 → "1.500.000"
  static String formatNumber(num number) {
    return _numberFormatter.format(number);
  }

  /// Rút gọn số tiền lớn: 1500000 → "1,5 Tr"
  static String formatCurrencyShort(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} Tỷ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} Tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} K';
    }
    return formatCurrency(amount);
  }

  // ── Ngày tháng ────────────────────────────────────────────────────────────
  // Dùng getter thay vì static final để tránh khởi tạo sớm
  // trước khi initializeDateFormatting('vi_VN') được gọi trong main()
  static DateFormat get _dateFormatter => DateFormat('dd/MM/yyyy', 'vi_VN');
  static DateFormat get _dateTimeFormatter =>
      DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');
  static DateFormat get _monthYearFormatter => DateFormat('MM/yyyy', 'vi_VN');
  static DateFormat get _fullDateFormatter =>
      DateFormat('EEEE, dd MMMM yyyy', 'vi_VN');

  /// Định dạng ngày: DateTime → "25/12/2025"
  static String formatDate(DateTime date) => _dateFormatter.format(date);

  /// Định dạng ngày giờ: DateTime → "25/12/2025 14:30"
  static String formatDateTime(DateTime date) =>
      _dateTimeFormatter.format(date);

  /// Định dạng tháng/năm: DateTime → "12/2025"
  static String formatMonthYear(DateTime date) =>
      _monthYearFormatter.format(date);

  /// Định dạng ngày đầy đủ: DateTime → "Thứ Năm, 25 Tháng 12 2025"
  static String formatFullDate(DateTime date) =>
      _fullDateFormatter.format(date);

  /// Tên tháng tiếng Việt: 1 → "Tháng 1"
  static String formatMonthName(int month) => 'Tháng $month';

  /// Hiển thị thời gian tương đối: "2 giờ trước", "3 ngày trước"
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }

  /// Số ngày còn lại đến hạn: "Còn 15 ngày" hoặc "Quá hạn 3 ngày"
  static String formatDaysUntil(DateTime targetDate) {
    final now = DateTime.now();
    final diff = targetDate.difference(now);
    if (diff.isNegative) {
      return 'Quá hạn ${diff.inDays.abs()} ngày';
    } else if (diff.inDays == 0) {
      return 'Hôm nay';
    }
    return 'Còn ${diff.inDays} ngày';
  }

  // ── Số điện thoại ─────────────────────────────────────────────────────────
  /// Che dấu số điện thoại: "0912345678" → "091****678"
  static String maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}';
  }

  /// Định dạng SĐT hiển thị: "0912345678" → "0912 345 678"
  static String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    return phone;
  }

  // ── CCCD ──────────────────────────────────────────────────────────────────
  /// Che dấu CCCD: "001204012345" → "0012 **** 2345"
  static String maskCccd(String cccd) {
    if (cccd.length < 8) return cccd;
    return '${cccd.substring(0, 4)} **** ${cccd.substring(cccd.length - 4)}';
  }

  // ── Đơn vị đo ─────────────────────────────────────────────────────────────
  /// Định dạng kWh điện
  static String formatElectric(double units) =>
      '${_numberFormatter.format(units)} kWh';

  /// Định dạng m³ nước
  static String formatWater(double units) =>
      '${_numberFormatter.format(units)} m³';

  /// Định dạng diện tích m²
  static String formatArea(double area) =>
      '${_numberFormatter.format(area)} m²';

  // ── Tên quý ───────────────────────────────────────────────────────────────
  /// Lấy tên quý từ tháng: tháng 1-3 → "Quý I"
  static String getQuarterName(int month) {
    if (month <= 3) return 'Quý I';
    if (month <= 6) return 'Quý II';
    if (month <= 9) return 'Quý III';
    return 'Quý IV';
  }

  /// Số quý từ tháng
  static int getQuarterNumber(int month) {
    return ((month - 1) ~/ 3) + 1;
  }

  /// Kỳ hóa đơn: "Tháng 12/2025"
  static String formatBillingPeriod(int month, int year) =>
      'Tháng $month/$year';
}
