// lib/features/invoice/data/models/invoice_model.dart
import '../../domain/entities/invoice.dart';

class InvoiceModel extends Invoice {
  const InvoiceModel({
    required super.id,
    required super.roomId,
    required super.roomNumber,
    super.tenantId,
    super.tenantName,
    required super.month,
    required super.year,
    required super.electricPrevReading,
    required super.electricCurrReading,
    required super.electricUnitPrice,
    required super.waterPrevReading,
    required super.waterCurrReading,
    required super.waterUnitPrice,
    required super.rentAmount,
    required super.serviceAmount,
    super.otherAmount,
    super.otherDescription,
    required super.status,
    required super.dueDate,
    super.paidAt,
    super.paymentMethod,
    super.transactionId,
    required super.createdAt,
    required super.createdBy,
    super.isLocked,
  });

  factory InvoiceModel.fromEntity(Invoice entity) {
    return InvoiceModel(
      id: entity.id,
      roomId: entity.roomId,
      roomNumber: entity.roomNumber,
      tenantId: entity.tenantId,
      tenantName: entity.tenantName,
      month: entity.month,
      year: entity.year,
      electricPrevReading: entity.electricPrevReading,
      electricCurrReading: entity.electricCurrReading,
      electricUnitPrice: entity.electricUnitPrice,
      waterPrevReading: entity.waterPrevReading,
      waterCurrReading: entity.waterCurrReading,
      waterUnitPrice: entity.waterUnitPrice,
      rentAmount: entity.rentAmount,
      serviceAmount: entity.serviceAmount,
      otherAmount: entity.otherAmount,
      otherDescription: entity.otherDescription,
      status: entity.status,
      dueDate: entity.dueDate,
      paidAt: entity.paidAt,
      paymentMethod: entity.paymentMethod,
      transactionId: entity.transactionId,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      isLocked: entity.isLocked,
    );
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    // Thông tin chi tiết nằm trong mảng hoặc object (do join 1-1 với Supabase)
    dynamic detailsRaw = json['chitiethoadon'];
    Map<String, dynamic> details = <String, dynamic>{};
    if (detailsRaw is List && detailsRaw.isNotEmpty) {
      details = detailsRaw.first as Map<String, dynamic>;
    } else if (detailsRaw is Map) {
      details = detailsRaw as Map<String, dynamic>;
    }

    return InvoiceModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      roomNumber: json['room_number'] as String? ?? '',
      tenantId: json['tenant_id'] as String?,
      tenantName: json['tenant_name'] as String?,
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      electricPrevReading: (details['electric_prev_reading'] as num?)?.toDouble() ?? 0,
      electricCurrReading: (details['electric_curr_reading'] as num?)?.toDouble() ?? 0,
      electricUnitPrice: (details['electric_unit_price'] as num?)?.toDouble() ?? 3500,
      waterPrevReading: (details['water_prev_reading'] as num?)?.toDouble() ?? 0,
      waterCurrReading: (details['water_curr_reading'] as num?)?.toDouble() ?? 0,
      waterUnitPrice: (details['water_unit_price'] as num?)?.toDouble() ?? 15000,
      rentAmount: (details['rent_amount'] as num?)?.toDouble() ?? 0,
      serviceAmount: (details['service_amount'] as num?)?.toDouble() ?? 0,
      otherAmount: (details['other_amount'] as num?)?.toDouble(),
      otherDescription: details['other_description'] as String?,
      status: InvoiceStatusExt.fromCode(
          json['status'] as String? ?? 'PENDING'),
      dueDate: DateTime.parse(json['due_date'] as String),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      paymentMethod: json['payment_method'] as String?,
      transactionId: json['transaction_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String? ?? '',
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'tenant_id': tenantId,
      'month': month,
      'year': year,
      'total_amount': totalAmount,
      'status': status.code,
      'due_date': dueDate.toIso8601String(),
      'created_by': createdBy.isEmpty ? null : createdBy,
      'is_locked': isLocked,
    };
  }

  Map<String, dynamic> toDetailsJson() {
    return {
      'electric_prev_reading': electricPrevReading,
      'electric_curr_reading': electricCurrReading,
      'electric_unit_price': electricUnitPrice,
      'water_prev_reading': waterPrevReading,
      'water_curr_reading': waterCurrReading,
      'water_unit_price': waterUnitPrice,
      'rent_amount': rentAmount,
      'service_amount': serviceAmount,
      'other_amount': otherAmount,
      'other_description': otherDescription,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'total_amount': totalAmount,
      'status': status.code,
      'due_date': dueDate.toIso8601String(),
      'is_locked': isLocked,
    };
  }
}
