// lib/features/invoice/domain/entities/invoice.dart
import 'package:equatable/equatable.dart';

enum InvoiceStatus { pending, confirmedByTenant, confirmedByOwner, paid, overdue }

extension InvoiceStatusExt on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.pending:
        return 'Chờ thanh toán';
      case InvoiceStatus.confirmedByTenant:
        return 'Khách đã xác nhận';
      case InvoiceStatus.confirmedByOwner:
        return 'Chủ đã xác nhận';
      case InvoiceStatus.paid:
        return 'Đã thanh toán';
      case InvoiceStatus.overdue:
        return 'Quá hạn';
    }
  }

  String get code {
    switch (this) {
      case InvoiceStatus.pending:
        return 'PENDING';
      case InvoiceStatus.confirmedByTenant:
        return 'CONFIRMED_BY_TENANT';
      case InvoiceStatus.confirmedByOwner:
        return 'CONFIRMED_BY_OWNER';
      case InvoiceStatus.paid:
        return 'PAID';
      case InvoiceStatus.overdue:
        return 'OVERDUE';
    }
  }

  static InvoiceStatus fromCode(String code) {
    switch (code) {
      case 'CONFIRMED_BY_TENANT':
        return InvoiceStatus.confirmedByTenant;
      case 'CONFIRMED_BY_OWNER':
        return InvoiceStatus.confirmedByOwner;
      case 'PAID':
        return InvoiceStatus.paid;
      case 'OVERDUE':
        return InvoiceStatus.overdue;
      default:
        return InvoiceStatus.pending;
    }
  }
}

class Invoice extends Equatable {
  final String id;
  final String roomId;
  final String roomNumber;
  final String? tenantId;
  final String? tenantName;
  final int month;
  final int year;

  // Chỉ số điện
  final double electricPrevReading;  // Chỉ số cũ kWh
  final double electricCurrReading;  // Chỉ số mới kWh
  final double electricUnitPrice;    // Giá điện /kWh

  // Chỉ số nước
  final double waterPrevReading;     // Chỉ số cũ m³
  final double waterCurrReading;     // Chỉ số mới m³
  final double waterUnitPrice;       // Giá nước /m³

  // Giá thuê & phí dịch vụ
  final double rentAmount;
  final double serviceAmount;

  // Các khoản khác (có thể thêm)
  final double? otherAmount;
  final String? otherDescription;

  // Trạng thái
  final InvoiceStatus status;
  final DateTime dueDate;       // Hạn thanh toán
  final DateTime? paidAt;       // Ngày thanh toán thực tế
  final String? paymentMethod;  // Phương thức thanh toán
  final String? transactionId;  // Mã giao dịch
  final String? paymentImageUrl; // Ảnh minh chứng thanh toán

  // Audit
  final DateTime createdAt;
  final String createdBy;       // userId người tạo
  final bool isLocked;          // true = không cho sửa sau khi đã paid

  const Invoice({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    this.tenantId,
    this.tenantName,
    required this.month,
    required this.year,
    required this.electricPrevReading,
    required this.electricCurrReading,
    required this.electricUnitPrice,
    required this.waterPrevReading,
    required this.waterCurrReading,
    required this.waterUnitPrice,
    required this.rentAmount,
    required this.serviceAmount,
    this.otherAmount,
    this.otherDescription,
    required this.status,
    required this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.transactionId,
    this.paymentImageUrl,
    required this.createdAt,
    required this.createdBy,
    this.isLocked = false,
  });

  // ── Computed Properties ──────────────────────────────────────────────────

  /// Số kWh tiêu thụ
  double get electricUnitsUsed =>
      electricCurrReading - electricPrevReading;

  /// Tiền điện
  double get electricAmount => electricUnitsUsed * electricUnitPrice;

  /// Số m³ nước tiêu thụ
  double get waterUnitsUsed => waterCurrReading - waterPrevReading;

  /// Tiền nước
  double get waterAmount => waterUnitsUsed * waterUnitPrice;

  /// Tổng hóa đơn
  double get totalAmount =>
      rentAmount +
      electricAmount +
      waterAmount +
      serviceAmount +
      (otherAmount ?? 0);

  /// Kiểm tra quá hạn
  bool get isOverdue =>
      status == InvoiceStatus.pending &&
      DateTime.now().isAfter(dueDate);

  /// Kỳ thanh toán hiển thị
  String get billingPeriod => 'Tháng $month/$year';

  bool get isPaid => status == InvoiceStatus.paid;
  bool get isPending => status == InvoiceStatus.pending ||
      status == InvoiceStatus.confirmedByTenant;

  Invoice copyWith({
    String? id,
    String? roomId,
    String? roomNumber,
    String? tenantId,
    String? tenantName,
    int? month,
    int? year,
    double? electricPrevReading,
    double? electricCurrReading,
    double? electricUnitPrice,
    double? waterPrevReading,
    double? waterCurrReading,
    double? waterUnitPrice,
    double? rentAmount,
    double? serviceAmount,
    double? otherAmount,
    String? otherDescription,
    InvoiceStatus? status,
    DateTime? dueDate,
    DateTime? paidAt,
    String? paymentMethod,
    String? transactionId,
    String? paymentImageUrl,
    DateTime? createdAt,
    String? createdBy,
    bool? isLocked,
  }) {
    return Invoice(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      month: month ?? this.month,
      year: year ?? this.year,
      electricPrevReading: electricPrevReading ?? this.electricPrevReading,
      electricCurrReading: electricCurrReading ?? this.electricCurrReading,
      electricUnitPrice: electricUnitPrice ?? this.electricUnitPrice,
      waterPrevReading: waterPrevReading ?? this.waterPrevReading,
      waterCurrReading: waterCurrReading ?? this.waterCurrReading,
      waterUnitPrice: waterUnitPrice ?? this.waterUnitPrice,
      rentAmount: rentAmount ?? this.rentAmount,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      otherAmount: otherAmount ?? this.otherAmount,
      otherDescription: otherDescription ?? this.otherDescription,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      paymentImageUrl: paymentImageUrl ?? this.paymentImageUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  List<Object?> get props => [id, roomId, month, year, status, totalAmount];
}
