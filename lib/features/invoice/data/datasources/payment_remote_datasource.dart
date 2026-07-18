// lib/features/invoice/data/datasources/payment_remote_datasource.dart
// ─────────────────────────────────────────────────────────────────────────────
//  Datasource cho bảng chitiethoadon
//  Chỉ Admin/Owner được phép ghi nhận thanh toán (createPayment)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  /// Ghi nhận thanh toán vào chitiethoadon và cập nhật hoadon → PAID
  Future<PaymentModel> createPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? transactionId,
  });

  /// Lấy lịch sử giao dịch của một hóa đơn
  Future<List<PaymentModel>> getPaymentsByInvoice(String invoiceId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final SupabaseClient _client;

  PaymentRemoteDataSourceImpl(this._client);

  @override
  Future<PaymentModel> createPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? transactionId,
  }) async {
    try {
      // 1. Insert vào chitiethoadon
      final paymentData = await _client
          .from(AppConstants.tablePayments)
          .insert({
            'invoice_id': invoiceId,
            'amount': amount,
            'payment_method': paymentMethod.code,
            'transaction_id': transactionId,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // 2. Cập nhật hoadon → PAID
      await _client
          .from(AppConstants.tableInvoices)
          .update({
            'status': InvoiceStatus.paid.code,
            'paid_at': DateTime.now().toIso8601String(),
            'payment_method': paymentMethod.code,
            if (transactionId != null) 'transaction_id': transactionId,
            'is_locked': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId);

      // 3. Ghi audit log
      await _writeAuditLog(
        action: 'CREATE_PAYMENT',
        recordId: invoiceId,
        newValue: {
          'payment_id': paymentData['id'],
          'amount': amount,
          'payment_method': paymentMethod.code,
        },
      );

      return PaymentModel.fromJson(paymentData);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: 'Lỗi ghi nhận thanh toán: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByInvoice(String invoiceId) async {
    try {
      final data = await _client
          .from(AppConstants.tablePayments)
          .select()
          .eq('invoice_id', invoiceId)
          .order('paid_at', ascending: false);

      return (data as List)
          .map((e) => PaymentModel.fromJson(e))
          .toList();
    } catch (e) {
      throw ServerFailure(message: 'Lỗi tải lịch sử thanh toán: $e');
    }
  }

  // ── Audit Log ─────────────────────────────────────────────────────────────
  Future<void> _writeAuditLog({
    required String action,
    required String recordId,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from(AppConstants.tableAuditLogs).insert({
        'user_id': userId,
        'action': action,
        'table_name': AppConstants.tablePayments,
        'record_id': recordId,
        'new_value': newValue,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Audit log thất bại không block main operation
    }
  }
}
