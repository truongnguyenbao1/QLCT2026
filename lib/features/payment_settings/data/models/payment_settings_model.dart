// lib/features/payment_settings/data/models/payment_settings_model.dart
import '../../domain/entities/payment_settings.dart';

class PaymentSettingsModel extends PaymentSettings {
  const PaymentSettingsModel({
    required super.id,
    required super.userId,
    super.bankCode,
    super.bankName,
    super.accountNumber,
    super.accountName,
    super.transferNoteTemplate,
    super.momoPhone,
    super.momoQrUrl,
    super.vnpayQr,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    return PaymentSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bankCode: json['bank_code'] as String?,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      accountName: json['account_name'] as String?,
      transferNoteTemplate: json['transfer_note_template'] as String?,
      momoPhone: json['momo_phone'] as String?,
      momoQrUrl: json['momo_qr_url'] as String?,
      vnpayQr: json['vnpay_qr'] as String?,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bank_code': bankCode,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'transfer_note_template': transferNoteTemplate,
      'momo_phone': momoPhone,
      'momo_qr_url': momoQrUrl,
      'vnpay_qr': vnpayQr,
    };
  }

  Map<String, dynamic> toInsertJson() {
    final map = toJson();
    map.remove('id'); // Khi insert, không cần id (auto-gen)
    return map;
  }

  factory PaymentSettingsModel.fromEntity(PaymentSettings s) {
    return PaymentSettingsModel(
      id: s.id,
      userId: s.userId,
      bankCode: s.bankCode,
      bankName: s.bankName,
      accountNumber: s.accountNumber,
      accountName: s.accountName,
      transferNoteTemplate: s.transferNoteTemplate,
      momoPhone: s.momoPhone,
      momoQrUrl: s.momoQrUrl,
      vnpayQr: s.vnpayQr,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
    );
  }
}
