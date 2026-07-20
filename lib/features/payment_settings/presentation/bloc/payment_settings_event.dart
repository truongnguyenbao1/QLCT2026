// lib/features/payment_settings/presentation/bloc/payment_settings_event.dart
import 'package:equatable/equatable.dart';

abstract class PaymentSettingsEvent extends Equatable {
  const PaymentSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load cài đặt thanh toán của user hiện tại
class LoadPaymentSettingsEvent extends PaymentSettingsEvent {
  final String userId;
  const LoadPaymentSettingsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Lưu cài đặt thanh toán
class SavePaymentSettingsEvent extends PaymentSettingsEvent {
  final String userId;
  final String? bankCode;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String? transferNoteTemplate;
  final String? momoPhone;
  final String? momoQrUrl;
  final String? vnpayQr;

  const SavePaymentSettingsEvent({
    required this.userId,
    this.bankCode,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.transferNoteTemplate,
    this.momoPhone,
    this.momoQrUrl,
    this.vnpayQr,
  });

  @override
  List<Object?> get props => [
        userId,
        bankCode,
        accountNumber,
        accountName,
        momoPhone,
        momoQrUrl,
      ];
}

class UploadMomoQrEvent extends PaymentSettingsEvent {
  final String userId;
  final String filePath;

  const UploadMomoQrEvent({required this.userId, required this.filePath});

  @override
  List<Object?> get props => [userId, filePath];
}
