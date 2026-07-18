// lib/features/invoice/domain/entities/payment.dart
import 'package:equatable/equatable.dart';

/// Các phương thức thanh toán được hỗ trợ
enum PaymentMethod {
  bankTransfer,
  cash,
  momo,
  vnpay,
}

extension PaymentMethodExt on PaymentMethod {
  String get code {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.momo:
        return 'MOMO';
      case PaymentMethod.vnpay:
        return 'VNPAY';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
    }
  }

  static PaymentMethod fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'CASH':
        return PaymentMethod.cash;
      case 'MOMO':
        return PaymentMethod.momo;
      case 'VNPAY':
        return PaymentMethod.vnpay;
      case 'BANK_TRANSFER':
      default:
        return PaymentMethod.bankTransfer;
    }
  }
}

/// Entity chi tiết giao dịch thanh toán (bảng chitiethoadon)
class Payment extends Equatable {
  final String id;
  final String invoiceId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final DateTime paidAt;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    required this.paidAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, invoiceId, amount, paymentMethod, transactionId, paidAt];
}
