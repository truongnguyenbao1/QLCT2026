import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class CreateInvoiceUseCase {
  final InvoiceRepository repository;

  CreateInvoiceUseCase(this.repository);

  Future<Either<Failure, Invoice>> call(Invoice invoice) async {
    return await repository.createInvoice(invoice);
  }
}
