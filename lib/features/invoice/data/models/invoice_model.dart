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

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      roomNumber: json['room_number'] as String? ?? '',
      tenantId: json['tenant_id'] as String?,
      tenantName: json['tenant_name'] as String?,
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      electricPrevReading:
          (json['electric_prev_reading'] as num?)?.toDouble() ?? 0,
      electricCurrReading:
          (json['electric_curr_reading'] as num?)?.toDouble() ?? 0,
      electricUnitPrice:
          (json['electric_unit_price'] as num?)?.toDouble() ?? 3500,
      waterPrevReading:
          (json['water_prev_reading'] as num?)?.toDouble() ?? 0,
      waterCurrReading:
          (json['water_curr_reading'] as num?)?.toDouble() ?? 0,
      waterUnitPrice:
          (json['water_unit_price'] as num?)?.toDouble() ?? 15000,
      rentAmount: (json['rent_amount'] as num?)?.toDouble() ?? 0,
      serviceAmount: (json['service_amount'] as num?)?.toDouble() ?? 0,
      otherAmount: (json['other_amount'] as num?)?.toDouble(),
      otherDescription: json['other_description'] as String?,
      status: InvoiceStatusExt.fromCode(
          json['status'] as String? ?? 'PENDING'),
      dueDate: DateTime.parse(json['due_date'] as String),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
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
      'status': status.code,
      'due_date': dueDate.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'created_by': createdBy,
      'is_locked': isLocked,
    };
  }
}
