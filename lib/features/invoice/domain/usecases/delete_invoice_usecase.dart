import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/invoice_repository.dart';

class DeleteInvoiceUseCase {
  final InvoiceRepository repository;

  DeleteInvoiceUseCase(this.repository);

  Future<Either<Failure, void>> call(String invoiceId) {
    return repository.deleteInvoice(invoiceId);
  }
}
