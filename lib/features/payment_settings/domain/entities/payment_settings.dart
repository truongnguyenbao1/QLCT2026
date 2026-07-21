// lib/features/payment_settings/domain/entities/payment_settings.dart
import 'package:equatable/equatable.dart';

/// Entity chứa thông tin cài đặt thanh toán của chủ trọ
class PaymentSettings extends Equatable {
  final String id;
  final String userId;

  // ── Thông tin tài khoản ngân hàng ────────────────────────────────────
  final String? bankCode;       // Mã ngân hàng (VD: VCB, TCB, MB...)
  final String? bankName;       // Tên ngân hàng đầy đủ
  final String? accountNumber;  // Số tài khoản
  final String? accountName;    // Tên chủ tài khoản

  // ── Nội dung chuyển khoản ─────────────────────────────────────────────
  final String? transferNoteTemplate; // Mẫu nội dung CK (có thể có placeholder)

  // ── Ví điện tử ───────────────────────────────────────────────────────
  final String? momoPhone;  // SĐT Momo
  final String? momoQrUrl;  // Link ảnh mã QR Momo
  final String? vnpayQr;    // Mã VNPay QR

  // ── Metadata ──────────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentSettings({
    required this.id,
    required this.userId,
    this.bankCode,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.transferNoteTemplate,
    this.momoPhone,
    this.momoQrUrl,
    this.vnpayQr,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Kiểm tra đã cấu hình thông tin ngân hàng chưa
  bool get hasBankInfo =>
      bankCode != null &&
      bankCode!.isNotEmpty &&
      accountNumber != null &&
      accountNumber!.isNotEmpty &&
      accountName != null &&
      accountName!.isNotEmpty;

  bool get hasMomo => (momoPhone != null && momoPhone!.isNotEmpty) || (momoQrUrl != null && momoQrUrl!.isNotEmpty);

  PaymentSettings copyWith({
    String? bankCode,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? transferNoteTemplate,
    String? momoPhone,
    String? momoQrUrl,
    String? vnpayQr,
  }) {
    return PaymentSettings(
      id: id,
      userId: userId,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      transferNoteTemplate: transferNoteTemplate ?? this.transferNoteTemplate,
      momoPhone: momoPhone ?? this.momoPhone,
      momoQrUrl: momoQrUrl ?? this.momoQrUrl,
      vnpayQr: vnpayQr ?? this.vnpayQr,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        bankCode,
        bankName,
        accountNumber,
        accountName,
        transferNoteTemplate,
        momoPhone,
        momoQrUrl,
        vnpayQr,
        createdAt,
        updatedAt,
      ];
}

/// Danh sách các ngân hàng Việt Nam phổ biến
class VietnamBanks {
  VietnamBanks._();

  static const List<BankInfo> list = [
    BankInfo(code: 'VCB',  name: 'Vietcombank',     shortName: 'Vietcombank',  bin: '970436'),
    BankInfo(code: 'TCB',  name: 'Techcombank',      shortName: 'Techcombank',  bin: '970407'),
    BankInfo(code: 'MB',   name: 'MB Bank',           shortName: 'MB',           bin: '970422'),
    BankInfo(code: 'VPB',  name: 'VPBank',            shortName: 'VPBank',       bin: '970432'),
    BankInfo(code: 'ACB',  name: 'ACB',               shortName: 'ACB',          bin: '970416'),
    BankInfo(code: 'BIDV', name: 'BIDV',              shortName: 'BIDV',         bin: '970418'),
    BankInfo(code: 'VTB',  name: 'Vietinbank',        shortName: 'Vietinbank',   bin: '970415'),
    BankInfo(code: 'TPB',  name: 'TPBank',            shortName: 'TPBank',       bin: '970423'),
    BankInfo(code: 'SHB',  name: 'SHB',               shortName: 'SHB',          bin: '970443'),
    BankInfo(code: 'HDB',  name: 'HDBank',            shortName: 'HDBank',       bin: '970437'),
    BankInfo(code: 'OCB',  name: 'OCB',               shortName: 'OCB',          bin: '970448'),
    BankInfo(code: 'MSB',  name: 'Maritime Bank',     shortName: 'MSB',          bin: '970426'),
    BankInfo(code: 'STB',  name: 'Sacombank',         shortName: 'Sacombank',    bin: '970403'),
    BankInfo(code: 'EIB',  name: 'Eximbank',          shortName: 'Eximbank',     bin: '970431'),
    BankInfo(code: 'LPB',  name: 'LienVietPostBank',  shortName: 'LienVietPost', bin: '970449'),
    BankInfo(code: 'NAB',  name: 'Nam A Bank',        shortName: 'Nam A',        bin: '970428'),
    BankInfo(code: 'ABB',  name: 'An Bình Bank',      shortName: 'An Bình',      bin: '970425'),
    BankInfo(code: 'SEAB', name: 'SeABank',           shortName: 'SeABank',      bin: '970440'),
    BankInfo(code: 'VAB',  name: 'VietABank',         shortName: 'VietA',        bin: '970427'),
    BankInfo(code: 'VBSP', name: 'Agribank',          shortName: 'Agribank',     bin: '970405'),
  ];

  static BankInfo? findByCode(String code) {
    try {
      return list.firstWhere((b) => b.code == code);
    } catch (_) {
      return null;
    }
  }
}

class BankInfo extends Equatable {
  final String code;
  final String name;
  final String shortName;
  /// Mã BIN 6 số chuẩn Napas – dùng cho VietQR Lookup API
  final String bin;

  const BankInfo({
    required this.code,
    required this.name,
    required this.shortName,
    required this.bin,
  });

  @override
  List<Object?> get props => [code];
}
