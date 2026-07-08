// lib/core/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  // ── Supabase ──────────────────────────────────────────────────────────
  // TODO: Thay bằng URL và key thật từ Supabase Dashboard
  static const String supabaseUrl = 'https://eaihqwzhfwtwzqmsrkgk.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_D887foMxZKHPBkpqcr6VOg_AcyGGAA5';

  // ── Tên Table trong Supabase ──────────────────────────────────────────
  static const String tableUsers = 'users';
  static const String tableRooms = 'rooms';
  static const String tableProperties = 'properties';
  static const String tableTenants = 'tenants';
  static const String tableContracts = 'contracts';
  static const String tableInvoices = 'invoices';
  static const String tablePayments = 'payments';
  static const String tableAuditLogs = 'audit_logs';
  static const String tableMeterReadings = 'meter_readings';

  // ── Storage Buckets ───────────────────────────────────────────────────
  static const String bucketContracts = 'contracts';
  static const String bucketCccdImages = 'cccd-images';
  static const String bucketPropertyImages = 'property-images';

  // ── Hive Box Names ────────────────────────────────────────────────────
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxCache = 'cache';

  // ── Secure Storage Keys ───────────────────────────────────────────────
  static const String keyEncryptionKey = 'enc_key_v1';
  static const String keyEncryptionIV = 'enc_iv_v1';

  // ── Quy tắc nghiệp vụ ────────────────────────────────────────────────
  /// Số ngày cảnh báo trước khi hợp đồng hết hạn
  static const int contractExpiryWarningDays = 30;

  /// Số phòng tối đa (quy mô nhỏ/vừa)
  static const int maxRoomsPerProperty = 50;

  /// Dung lượng ảnh tối đa sau khi nén (500KB = 500 * 1024 bytes)
  static const int maxImageSizeBytes = 500 * 1024;

  /// Chất lượng nén ảnh (0-100)
  static const int imageCompressQuality = 75;

  // ── Giá điện/nước mặc định (VND) ─────────────────────────────────────
  /// Giá điện mặc định /kWh - có thể chỉnh trong settings
  static const double defaultElectricPricePerUnit = 3500.0;

  /// Giá nước mặc định /m³
  static const double defaultWaterPricePerUnit = 15000.0;

  // ── VietQR ────────────────────────────────────────────────────────────
  static const String vietQrBaseUrl = 'https://img.vietqr.io/image';

  // ── Timeout ───────────────────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration cacheExpiry = Duration(minutes: 30);

  // ── Regex Validation ──────────────────────────────────────────────────
  static const String phoneRegex = r'^(0[3|5|7|8|9])+([0-9]{8})$';
  static const String cccdRegex = r'^\d{12}$';
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // ── Roles ─────────────────────────────────────────────────────────────
  static const String roleOwner = 'OWNER';
  static const String roleStaff = 'STAFF';
  static const String roleTenant = 'TENANT';
}
