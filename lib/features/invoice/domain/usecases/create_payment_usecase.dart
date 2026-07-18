// lib/features/invoice/domain/usecases/create_payment_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentUseCase {
  final PaymentRepository repository;

  CreatePaymentUseCase(this.repository);

  Future<Either<Failure, Payment>> call({
    required String invoiceId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? transactionId,
  }) {
    return repository.createPayment(
      invoiceId: invoiceId,
      amount: amount,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
    );
  }
}
