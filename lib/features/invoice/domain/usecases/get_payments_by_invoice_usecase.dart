// lib/features/invoice/domain/usecases/get_payments_by_invoice_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetPaymentsByInvoiceUseCase {
  final PaymentRepository repository;

  GetPaymentsByInvoiceUseCase(this.repository);

  Future<Either<Failure, List<Payment>>> call(String invoiceId) {
    return repository.getPaymentsByInvoice(invoiceId);
  }
}
