// lib/features/invoice/domain/usecases/get_invoice_by_id_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceByIdUseCase {
  final InvoiceRepository repository;

  GetInvoiceByIdUseCase(this.repository);

  Future<Either<Failure, Invoice>> call(String invoiceId) async {
    return await repository.getInvoiceById(invoiceId);
  }
}
