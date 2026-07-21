// lib/features/invoice/data/datasources/invoice_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/invoice.dart';
import '../models/invoice_model.dart';

abstract class InvoiceRemoteDataSource {
  Future<List<InvoiceModel>> getInvoices({
    String? propertyId,
    String? roomId,
    int? month,
    int? year,
    InvoiceStatus? status,
  });
  Future<InvoiceModel> getInvoiceById(String invoiceId);
  Future<InvoiceModel> createInvoice(InvoiceModel invoice);
  Future<InvoiceModel> updateInvoiceStatus({
    required String invoiceId,
    required InvoiceStatus status,
    String? paymentMethod,
    String? transactionId,
  });
  Future<InvoiceModel> updateInvoice(InvoiceModel invoice);
  Future<void> deleteInvoice(String invoiceId);
  Future<InvoiceModel> tenantConfirmPayment(String invoiceId);
  Future<InvoiceModel> ownerConfirmPayment(String invoiceId);
  Future<List<InvoiceModel>> getInvoicesByQuarter({
    required String propertyId,
    required int quarter,
    required int year,
  });
  Stream<List<InvoiceModel>> watchInvoices({String? roomId, String? propertyId});
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final SupabaseClient _client;

  InvoiceRemoteDataSourceImpl(this._client);

  @override
  Future<List<InvoiceModel>> getInvoices({
    String? propertyId,
    String? roomId,
    int? month,
    int? year,
    InvoiceStatus? status,
  }) async {
    try {
      var query = _client
          .from(AppConstants.tableInvoices)
          .select('''
            *,
            phong!inner(room_number, property_id),
            khachthue(full_name)
          ''');

      if (propertyId != null) {
        query = query.eq('phong.property_id', propertyId);
      }
      if (roomId != null) {
        query = query.eq('room_id', roomId);
      }
      if (month != null) {
        query = query.eq('month', month);
      }
      if (year != null) {
        query = query.eq('year', year);
      }
      if (status != null) {
        query = query.eq('status', status.code);
      }

      final data = await query.order('year', ascending: false)
          .order('month', ascending: false);

      return (data as List).map((e) {
        // Flatten joined data
        final map = Map<String, dynamic>.from(e);
        map['room_number'] = e['phong']?['room_number'] ?? '';
        map['tenant_name'] = e['khachthue']?['full_name'];
        return InvoiceModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw ServerFailure(message: 'Lỗi tải hóa đơn: $e');
    }
  }

  @override
  Future<InvoiceModel> getInvoiceById(String invoiceId) async {
    try {
      final data = await _client
          .from(AppConstants.tableInvoices)
          .select('''
            *,
            phong!inner(room_number),
            khachthue(full_name)
          ''')
          .eq('id', invoiceId)
          .single();

      final map = Map<String, dynamic>.from(data);
      map['room_number'] = data['phong']?['room_number'] ?? '';
      map['tenant_name'] = data['khachthue']?['full_name'];
      return InvoiceModel.fromJson(map);
    } catch (e) {
      throw NotFoundFailure(message: 'Không tìm thấy hóa đơn: $invoiceId');
    }
  }

  @override
  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    try {
      // Kiểm tra đã có hóa đơn tháng này chưa
      final existing = await _client
          .from(AppConstants.tableInvoices)
          .select('id')
          .eq('room_id', invoice.roomId)
          .eq('month', invoice.month)
          .eq('year', invoice.year)
          .maybeSingle();

      if (existing != null) {
        throw const DuplicateFailure(
            message: 'Hóa đơn tháng này đã được tạo rồi.');
      }

      final data = await _client
          .from(AppConstants.tableInvoices)
          .insert(invoice.toJson())
          .select('''
            *,
            phong!inner(room_number),
            khachthue(full_name)
          ''')
          .single();

      // Cập nhật bảng chiso (ELECTRIC)
      try {
        await _client.from(AppConstants.tableMeterReadings).upsert({
          'room_id': invoice.roomId,
          'type': 'ELECTRIC',
          'prev_reading': invoice.electricPrevReading,
          'curr_reading': invoice.electricCurrReading,
          'unit_price': invoice.electricUnitPrice,
          'month': invoice.month,
          'year': invoice.year,
          'reading_date': DateTime.now().toIso8601String(),
        }, onConflict: 'room_id, type, month, year');
      } catch (e) {
        // Bỏ qua nếu có lỗi nhỏ lúc ghi log chiso
      }

      // Cập nhật bảng chiso (WATER)
      try {
        await _client.from(AppConstants.tableMeterReadings).upsert({
          'room_id': invoice.roomId,
          'type': 'WATER',
          'prev_reading': invoice.waterPrevReading,
          'curr_reading': invoice.waterCurrReading,
          'unit_price': invoice.waterUnitPrice,
          'month': invoice.month,
          'year': invoice.year,
          'reading_date': DateTime.now().toIso8601String(),
        }, onConflict: 'room_id, type, month, year');
      } catch (e) {
        // Bỏ qua
      }

      final map = Map<String, dynamic>.from(data);
      map['room_number'] = data['phong']?['room_number'] ?? '';
      map['tenant_name'] = data['khachthue']?['full_name'];
      return InvoiceModel.fromJson(map);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: 'Lỗi tạo hóa đơn: $e');
    }
  }

  @override
  Future<InvoiceModel> updateInvoiceStatus({
    required String invoiceId,
    required InvoiceStatus status,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.code,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == InvoiceStatus.paid) {
        updateData['paid_at'] = DateTime.now().toIso8601String();
        updateData['is_locked'] = true; // Khóa hóa đơn sau khi thanh toán
        if (paymentMethod != null) {
          updateData['payment_method'] = paymentMethod;
        }
        if (transactionId != null) {
          updateData['transaction_id'] = transactionId;
        }
      }

      final data = await _client
          .from(AppConstants.tableInvoices)
          .update(updateData)
          .eq('id', invoiceId)
          .select('''
            *,
            phong!inner(room_number),
            khachthue(full_name)
          ''')
          .single();

      // Ghi audit log
      await _writeAuditLog(
        action: 'UPDATE_INVOICE_STATUS',
        recordId: invoiceId,
        newValue: {'status': status.code},
      );

      final map = Map<String, dynamic>.from(data);
      map['room_number'] = data['phong']?['room_number'] ?? '';
      map['tenant_name'] = data['khachthue']?['full_name'];
      return InvoiceModel.fromJson(map);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Lỗi cập nhật trạng thái: $e');
    }
  }

  @override
  Future<InvoiceModel> updateInvoice(InvoiceModel invoice) async {
    try {
      final data = await _client
          .from(AppConstants.tableInvoices)
          .update(invoice.toUpdateJson())
          .eq('id', invoice.id)
          .select('''
            *,
            phong!inner(room_number),
            khachthue(full_name)
          ''')
          .single();

      // Cập nhật bảng chiso (ELECTRIC)
      try {
        await _client.from(AppConstants.tableMeterReadings).upsert({
          'room_id': invoice.roomId,
          'type': 'ELECTRIC',
          'prev_reading': invoice.electricPrevReading,
          'curr_reading': invoice.electricCurrReading,
          'unit_price': invoice.electricUnitPrice,
          'month': invoice.month,
          'year': invoice.year,
          'reading_date': DateTime.now().toIso8601String(),
        }, onConflict: 'room_id, type, month, year');
      } catch (e) {
        // Bỏ qua
      }

      // Cập nhật bảng chiso (WATER)
      try {
        await _client.from(AppConstants.tableMeterReadings).upsert({
          'room_id': invoice.roomId,
          'type': 'WATER',
          'prev_reading': invoice.waterPrevReading,
          'curr_reading': invoice.waterCurrReading,
          'unit_price': invoice.waterUnitPrice,
          'month': invoice.month,
          'year': invoice.year,
          'reading_date': DateTime.now().toIso8601String(),
        }, onConflict: 'room_id, type, month, year');
      } catch (e) {
        // Bỏ qua
      }

      final map = Map<String, dynamic>.from(data);
      map['room_number'] = data['phong']?['room_number'] ?? '';
      map['tenant_name'] = data['khachthue']?['full_name'];
      return InvoiceModel.fromJson(map);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi cập nhật hóa đơn: $e');
    }
  }

  @override
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _client.from(AppConstants.tableInvoices).delete().eq('id', invoiceId);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi xóa hóa đơn: $e');
    }
  }

  @override
  Future<InvoiceModel> tenantConfirmPayment(String invoiceId) async {
    try {
      final response = await _client.rpc('tenant_confirm_payment', params: {
        'p_invoice_id': invoiceId,
      });
      // The RPC returns basic invoice details, but we can just fetch the whole invoice again,
      // or return a partial one. Wait, the RPC returns exactly what we need?
      // Actually, returning a full InvoiceModel might require khachthue info.
      // Let's just fetch the updated invoice using the standard query after RPC.
      final data = await _client
          .from(AppConstants.tableInvoices)
          .select('''
            *,
            phong!inner(room_number),
            khachthue(full_name)
          ''')
          .eq('id', invoiceId)
          .single();

      final map = Map<String, dynamic>.from(data);
      map['room_number'] = data['phong']?['room_number'] ?? '';
      map['tenant_name'] = data['khachthue']?['full_name'];
      return InvoiceModel.fromJson(map);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Lỗi xác nhận thanh toán: $e');
    }
  }

  @override
  Future<InvoiceModel> ownerConfirmPayment(String invoiceId) async {
    return updateInvoiceStatus(
      invoiceId: invoiceId,
      status: InvoiceStatus.paid,
      paymentMethod: 'MANUAL',
    );
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByQuarter({
    required String propertyId,
    required int quarter,
    required int year,
  }) async {
    // Tháng bắt đầu và kết thúc của quý
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = quarter * 3;

    try {
      final data = await _client
          .from(AppConstants.tableInvoices)
          .select('''
            *,
            phong!inner(room_number, property_id),
            khachthue(full_name)
          ''')
          .eq('phong.property_id', propertyId)
          .eq('year', year)
          .gte('month', startMonth)
          .lte('month', endMonth)
          .order('month');

      return (data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        map['room_number'] = e['phong']?['room_number'] ?? '';
        map['tenant_name'] = e['khachthue']?['full_name'];
        return InvoiceModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw ServerFailure(message: 'Lỗi tải báo cáo quý: $e');
    }
  }

  @override
  Stream<List<InvoiceModel>> watchInvoices(
      {String? roomId, String? propertyId}) {
    // SupabaseStreamBuilder supports filtering via eqFilters only at construction
    // For simplicity, stream all and filter client-side
    final stream = _client
        .from(AppConstants.tableInvoices)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return stream.map((data) {
      var list = data.map((e) => InvoiceModel.fromJson(e)).toList();
      if (roomId != null) {
        list = list.where((inv) => inv.roomId == roomId).toList();
      }
      return list;
    });
  }

  // ── Audit Log ────────────────────────────────────────────────────────────
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
        'table_name': AppConstants.tableInvoices,
        'record_id': recordId,
        'new_value': newValue,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Audit log thất bại không nên block main operation
    }
  }
}
