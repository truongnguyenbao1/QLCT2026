import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class GetInvoicesUseCase {
  final InvoiceRepository repository;

  GetInvoicesUseCase(this.repository);

  Future<Either<Failure, List<Invoice>>> call({
    String? propertyId,
    String? roomId,
    int? month,
    int? year,
    InvoiceStatus? status,
  }) async {
    return await repository.getInvoices(
      propertyId: propertyId,
      roomId: roomId,
      month: month,
      year: year,
      status: status,
    );
  }
}
