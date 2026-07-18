// lib/features/invoice/data/models/payment_model.dart
import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.invoiceId,
    required super.amount,
    required super.paymentMethod,
    super.transactionId,
    required super.paidAt,
    required super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: PaymentMethodExt.fromCode(
        json['payment_method'] as String? ?? 'BANK_TRANSFER',
      ),
      transactionId: json['transaction_id'] as String?,
      paidAt: DateTime.parse(json['paid_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_method': paymentMethod.code,
      'transaction_id': transactionId,
      'paid_at': paidAt.toIso8601String(),
    };
  }
}
