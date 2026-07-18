// lib/features/invoice/domain/repositories/payment_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  /// Ghi nhận thanh toán (chỉ Admin/Owner) và cập nhật trạng thái hóa đơn sang PAID
  Future<Either<Failure, Payment>> createPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? transactionId,
  });

  /// Lấy danh sách giao dịch thanh toán theo hóa đơn
  Future<Either<Failure, List<Payment>>> getPaymentsByInvoice(String invoiceId);
}
