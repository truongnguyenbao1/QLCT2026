import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class UpdateInvoiceUseCase {
  final InvoiceRepository repository;

  UpdateInvoiceUseCase(this.repository);

  Future<Either<Failure, Invoice>> call(Invoice invoice) {
    return repository.updateInvoice(invoice);
  }
}
