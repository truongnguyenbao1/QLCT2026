import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class MarkInvoicePaidUseCase {
  final InvoiceRepository repository;

  MarkInvoicePaidUseCase(this.repository);

  Future<Either<Failure, Invoice>> call(String invoiceId, {String? paymentMethod, String? transactionId}) async {
    return await repository.updateInvoiceStatus(
      invoiceId: invoiceId, 
      status: InvoiceStatus.paid,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
    );
  }
}
