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

  bool get hasMomo => momoPhone != null && momoPhone!.isNotEmpty;

  PaymentSettings copyWith({
    String? bankCode,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? transferNoteTemplate,
    String? momoPhone,
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
        accountNumber,
        accountName,
        transferNoteTemplate,
        momoPhone,
        vnpayQr,
      ];
}

/// Danh sách các ngân hàng Việt Nam phổ biến
class VietnamBanks {
  VietnamBanks._();

  static const List<BankInfo> list = [
    BankInfo(code: 'VCB',  name: 'Vietcombank',              shortName: 'Vietcombank'),
    BankInfo(code: 'TCB',  name: 'Techcombank',               shortName: 'Techcombank'),
    BankInfo(code: 'MB',   name: 'MB Bank',                   shortName: 'MB'),
    BankInfo(code: 'VPB',  name: 'VPBank',                    shortName: 'VPBank'),
    BankInfo(code: 'ACB',  name: 'ACB',                       shortName: 'ACB'),
    BankInfo(code: 'BIDV', name: 'BIDV',                      shortName: 'BIDV'),
    BankInfo(code: 'VTB',  name: 'Vietinbank',                shortName: 'Vietinbank'),
    BankInfo(code: 'TPB',  name: 'TPBank',                    shortName: 'TPBank'),
    BankInfo(code: 'SHB',  name: 'SHB',                       shortName: 'SHB'),
    BankInfo(code: 'HDB',  name: 'HDBank',                    shortName: 'HDBank'),
    BankInfo(code: 'OCB',  name: 'OCB',                       shortName: 'OCB'),
    BankInfo(code: 'MSB',  name: 'Maritime Bank',             shortName: 'MSB'),
    BankInfo(code: 'STB',  name: 'Sacombank',                 shortName: 'Sacombank'),
    BankInfo(code: 'EIB',  name: 'Eximbank',                  shortName: 'Eximbank'),
    BankInfo(code: 'LPB',  name: 'LienVietPostBank',          shortName: 'LienVietPost'),
    BankInfo(code: 'NAB',  name: 'Nam A Bank',                shortName: 'Nam A'),
    BankInfo(code: 'ABB',  name: 'An Bình Bank',              shortName: 'An Bình'),
    BankInfo(code: 'SEAB', name: 'SeABank',                   shortName: 'SeABank'),
    BankInfo(code: 'VAB',  name: 'VietABank',                 shortName: 'VietA'),
    BankInfo(code: 'VBSP', name: 'Agribank',                  shortName: 'Agribank'),
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

  const BankInfo({
    required this.code,
    required this.name,
    required this.shortName,
  });

  @override
  List<Object?> get props => [code];
}
