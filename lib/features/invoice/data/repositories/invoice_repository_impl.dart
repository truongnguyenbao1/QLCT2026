// lib/features/invoice/data/repositories/invoice_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_datasource.dart';
import '../models/invoice_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource _remoteDataSource;

  InvoiceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Invoice>>> getInvoices({
    String? propertyId,
    String? roomId,
    int? month,
    int? year,
    InvoiceStatus? status,
  }) async {
    try {
      final invoices = await _remoteDataSource.getInvoices(
        propertyId: propertyId,
        roomId: roomId,
        month: month,
        year: year,
        status: status,
      );
      return Right(invoices);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String invoiceId) async {
    try {
      final invoice = await _remoteDataSource.getInvoiceById(invoiceId);
      return Right(invoice);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Invoice>> createInvoice(Invoice invoice) async {
    try {
      final model = InvoiceModel.fromEntity(invoice);
      final result = await _remoteDataSource.createInvoice(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Invoice>> updateInvoiceStatus({
    required String invoiceId,
    required InvoiceStatus status,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      final result = await _remoteDataSource.updateInvoiceStatus(
        invoiceId: invoiceId,
        status: status,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Invoice>> tenantConfirmPayment(String invoiceId) async {
    try {
      final result = await _remoteDataSource.tenantConfirmPayment(invoiceId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Invoice>> ownerConfirmPayment(String invoiceId) async {
    try {
      final result = await _remoteDataSource.ownerConfirmPayment(invoiceId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getInvoicesByQuarter({
    required String propertyId,
    required int quarter,
    required int year,
  }) async {
    try {
      final invoices = await _remoteDataSource.getInvoicesByQuarter(
        propertyId: propertyId,
        quarter: quarter,
        year: year,
      );
      return Right(invoices);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Invoice>> watchInvoices({String? roomId, String? propertyId}) {
    return _remoteDataSource.watchInvoices(
      roomId: roomId,
      propertyId: propertyId,
    );
  }
}
