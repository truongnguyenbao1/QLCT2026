// lib/features/invoice/domain/repositories/invoice_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, List<Invoice>>> getInvoices({
    String? propertyId,
    String? roomId,
    int? month,
    int? year,
    InvoiceStatus? status,
  });
  Future<Either<Failure, Invoice>> getInvoiceById(String invoiceId);
  Future<Either<Failure, Invoice>> createInvoice(Invoice invoice);
  Future<Either<Failure, Invoice>> updateInvoiceStatus({
    required String invoiceId,
    required InvoiceStatus status,
    String? paymentMethod,
    String? transactionId,
  });
  Future<Either<Failure, Invoice>> updateInvoice(Invoice invoice);
  Future<Either<Failure, void>> deleteInvoice(String invoiceId);
  Future<Either<Failure, Invoice>> tenantConfirmPayment(String invoiceId);
  Future<Either<Failure, Invoice>> ownerConfirmPayment(String invoiceId);
  Future<Either<Failure, List<Invoice>>> getInvoicesByQuarter({
    required String propertyId,
    required int quarter,
    required int year,
  });
  Stream<List<Invoice>> watchInvoices({String? roomId, String? propertyId});
}
