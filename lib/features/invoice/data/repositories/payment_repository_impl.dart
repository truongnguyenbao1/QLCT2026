// lib/features/invoice/data/repositories/payment_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;

  PaymentRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, Payment>> createPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? transactionId,
  }) async {
    try {
      final result = await _remoteDataSource.createPayment(
        invoiceId: invoiceId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi ghi nhận thanh toán: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByInvoice(
      String invoiceId) async {
    try {
      final result =
          await _remoteDataSource.getPaymentsByInvoice(invoiceId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tải lịch sử thanh toán: $e'));
    }
  }
}
