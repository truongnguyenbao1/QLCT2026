// lib/features/invoice/data/repositories/invoice_repository_impl.dart
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_datasource.dart';
import '../models/invoice_model.dart';

import '../../../system_logs/data/repositories/system_log_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource _remoteDataSource;
  final SystemLogRepository _logRepository;

  InvoiceRepositoryImpl(this._remoteDataSource, this._logRepository);

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
      
      _logRepository.logAction(
        action: 'INSERT',
        tableName: 'hoa_don',
        recordId: result.id,
      );
      
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tạo hóa đơn: $e'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> updateInvoice(Invoice invoice) async {
    try {
      final model = InvoiceModel.fromEntity(invoice);
      final result = await _remoteDataSource.updateInvoice(model);
      
      _logRepository.logAction(
        action: 'UPDATE',
        tableName: 'hoa_don',
        recordId: result.id,
      );
      
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi cập nhật hóa đơn: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String invoiceId) async {
    try {
      await _remoteDataSource.deleteInvoice(invoiceId);
      
      _logRepository.logAction(
        action: 'DELETE',
        tableName: 'hoa_don',
        recordId: invoiceId,
      );
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi xóa hóa đơn: $e'));
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
      
      _logRepository.logAction(
        action: 'UPDATE_STATUS',
        tableName: 'hoa_don',
        recordId: invoiceId,
        newValue: {'status': status.name},
      );
      
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Invoice>> tenantConfirmPayment(String invoiceId, {Uint8List? imageBytes, String? imageExt}) async {
    try {
      final result = await _remoteDataSource.tenantConfirmPayment(invoiceId, imageBytes: imageBytes, imageExt: imageExt);
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
