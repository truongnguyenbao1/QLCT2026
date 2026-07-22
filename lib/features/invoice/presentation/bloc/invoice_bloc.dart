import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/create_invoice_usecase.dart';
import '../../domain/usecases/create_payment_usecase.dart';
import '../../domain/usecases/get_invoice_by_id_usecase.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/get_payments_by_invoice_usecase.dart';
import '../../domain/usecases/mark_invoice_paid_usecase.dart';
import '../../domain/usecases/update_invoice_usecase.dart';
import '../../domain/usecases/delete_invoice_usecase.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoicesEvent extends InvoiceEvent {
  final String? propertyId;
  final String? roomId;
  final int? month;
  final int? year;
  final InvoiceStatus? status;

  const LoadInvoicesEvent({
    this.propertyId,
    this.roomId,
    this.month,
    this.year,
    this.status,
  });

  @override
  List<Object?> get props => [propertyId, roomId, month, year, status];
}

class LoadInvoiceDetailEvent extends InvoiceEvent {
  final String invoiceId;
  const LoadInvoiceDetailEvent(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class CreateInvoiceEvent extends InvoiceEvent {
  final Invoice invoice;
  const CreateInvoiceEvent(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class UpdateInvoiceEvent extends InvoiceEvent {
  final Invoice invoice;
  const UpdateInvoiceEvent(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class DeleteInvoiceEvent extends InvoiceEvent {
  final String invoiceId;
  const DeleteInvoiceEvent(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class MarkInvoicePaidEvent extends InvoiceEvent {
  final String invoiceId;
  final String? paymentMethod;
  final String? transactionId;
  const MarkInvoicePaidEvent({
    required this.invoiceId,
    this.paymentMethod,
    this.transactionId,
  });
  @override
  List<Object?> get props => [invoiceId, paymentMethod, transactionId];
}

class TenantConfirmPaymentEvent extends InvoiceEvent {
  final String invoiceId;
  final Uint8List? imageBytes;
  final String? imageExt;
  const TenantConfirmPaymentEvent(this.invoiceId, {this.imageBytes, this.imageExt});
  @override
  List<Object?> get props => [invoiceId, imageBytes, imageExt];
}

class FetchPreviousReadingsEvent extends InvoiceEvent {
  final String roomId;
  const FetchPreviousReadingsEvent(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

/// Load danh sách giao dịch thanh toán của một hóa đơn
class LoadPaymentsEvent extends InvoiceEvent {
  final String invoiceId;
  const LoadPaymentsEvent(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

/// Ghi nhận thanh toán (chỉ Admin/Owner)
class CreatePaymentEvent extends InvoiceEvent {
  final String invoiceId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  /// Phải là true (owner) — BLoC sẽ từ chối nếu false
  final bool isOwner;

  const CreatePaymentEvent({
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    required this.isOwner,
  });
  @override
  List<Object?> get props =>
      [invoiceId, amount, paymentMethod, transactionId, isOwner];
}

// ── States ────────────────────────────────────────────────────────────────
abstract class InvoiceState extends Equatable {
  const InvoiceState();
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {
  const InvoiceInitial();
}

class InvoicesLoading extends InvoiceState {
  const InvoicesLoading();
}

class InvoicesLoaded extends InvoiceState {
  final List<Invoice> invoices;

  const InvoicesLoaded({required this.invoices});

  @override
  List<Object?> get props => [invoices];
}

class InvoiceDetailLoaded extends InvoiceState {
  final Invoice invoice;
  const InvoiceDetailLoaded(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class InvoiceActionSuccess extends InvoiceState {
  final String message;
  final List<Invoice>? invoices;
  const InvoiceActionSuccess({required this.message, this.invoices});
  @override
  List<Object?> get props => [message, invoices];
}

class InvoiceError extends InvoiceState {
  final String message;
  const InvoiceError(this.message);
  @override
  List<Object?> get props => [message];
}

class InvoicePreviousReadingsLoaded extends InvoiceState {
  final double electricPrev;
  final double waterPrev;
  const InvoicePreviousReadingsLoaded(this.electricPrev, this.waterPrev);
  @override
  List<Object?> get props => [electricPrev, waterPrev];
}

/// Danh sách giao dịch thanh toán đã tải
class PaymentsLoaded extends InvoiceState {
  final List<Payment> payments;
  const PaymentsLoaded(this.payments);
  @override
  List<Object?> get props => [payments];
}

/// Đang xử lý tạo thanh toán
class PaymentCreating extends InvoiceState {
  const PaymentCreating();
}

// ── BLoC ──────────────────────────────────────────────────────────────────
class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final GetInvoicesUseCase _getInvoicesUseCase;
  final GetInvoiceByIdUseCase _getInvoiceByIdUseCase;
  final CreateInvoiceUseCase _createInvoiceUseCase;
  final MarkInvoicePaidUseCase _markInvoicePaidUseCase;
  final UpdateInvoiceUseCase _updateInvoiceUseCase;
  final DeleteInvoiceUseCase _deleteInvoiceUseCase;
  final CreatePaymentUseCase _createPaymentUseCase;
  final GetPaymentsByInvoiceUseCase _getPaymentsByInvoiceUseCase;

  List<Invoice> _currentInvoices = [];

  InvoiceBloc({
    required GetInvoicesUseCase getInvoicesUseCase,
    required GetInvoiceByIdUseCase getInvoiceByIdUseCase,
    required CreateInvoiceUseCase createInvoiceUseCase,
    required MarkInvoicePaidUseCase markInvoicePaidUseCase,
    required UpdateInvoiceUseCase updateInvoiceUseCase,
    required DeleteInvoiceUseCase deleteInvoiceUseCase,
    required CreatePaymentUseCase createPaymentUseCase,
    required GetPaymentsByInvoiceUseCase getPaymentsByInvoiceUseCase,
  })  : _getInvoicesUseCase = getInvoicesUseCase,
        _getInvoiceByIdUseCase = getInvoiceByIdUseCase,
        _createInvoiceUseCase = createInvoiceUseCase,
        _markInvoicePaidUseCase = markInvoicePaidUseCase,
        _updateInvoiceUseCase = updateInvoiceUseCase,
        _deleteInvoiceUseCase = deleteInvoiceUseCase,
        _createPaymentUseCase = createPaymentUseCase,
        _getPaymentsByInvoiceUseCase = getPaymentsByInvoiceUseCase,
        super(const InvoiceInitial()) {
    on<LoadInvoicesEvent>(_onLoadInvoices);
    on<LoadInvoiceDetailEvent>(_onLoadInvoiceDetail);
    on<CreateInvoiceEvent>(_onCreateInvoice);
    on<MarkInvoicePaidEvent>(_onMarkInvoicePaid);
    on<TenantConfirmPaymentEvent>(_onTenantConfirmPayment);
    on<FetchPreviousReadingsEvent>(_onFetchPreviousReadings);
    on<UpdateInvoiceEvent>(_onUpdateInvoice);
    on<DeleteInvoiceEvent>(_onDeleteInvoice);
    on<LoadPaymentsEvent>(_onLoadPayments);
    on<CreatePaymentEvent>(_onCreatePayment);
  }

  Future<void> _onLoadInvoices(
      LoadInvoicesEvent event, Emitter<InvoiceState> emit) async {
    emit(const InvoicesLoading());
    final result = await _getInvoicesUseCase(
      propertyId: event.propertyId,
      roomId: event.roomId,
      month: event.month,
      year: event.year,
      status: event.status,
    );
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (invoices) {
        _currentInvoices = invoices;
        emit(InvoicesLoaded(invoices: _currentInvoices));
      },
    );
  }

  Future<void> _onLoadInvoiceDetail(
      LoadInvoiceDetailEvent event, Emitter<InvoiceState> emit) async {
    emit(const InvoicesLoading());

    // 1. Thử tìm trong cache trước (nhanh hơn)
    try {
      final cached = _currentInvoices.firstWhere((i) => i.id == event.invoiceId);
      emit(InvoiceDetailLoaded(cached));
      return;
    } catch (_) {
      // Không có trong cache, gọi API trực tiếp
    }

    // 2. Gọi API lấy theo ID
    final result = await _getInvoiceByIdUseCase(event.invoiceId);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (invoice) => emit(InvoiceDetailLoaded(invoice)),
    );
  }

  Future<void> _onCreateInvoice(
      CreateInvoiceEvent event, Emitter<InvoiceState> emit) async {
    emit(const InvoicesLoading());
    final result = await _createInvoiceUseCase(event.invoice);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (newInvoice) {
        _currentInvoices = [newInvoice, ..._currentInvoices];
        emit(InvoiceActionSuccess(
          message: 'Tạo hóa đơn thành công!',
          invoices: _currentInvoices,
        ));
        emit(InvoicesLoaded(invoices: _currentInvoices));
      },
    );
  }

  Future<void> _onMarkInvoicePaid(
      MarkInvoicePaidEvent event, Emitter<InvoiceState> emit) async {
    emit(const InvoicesLoading());
    final result = await _markInvoicePaidUseCase(
      event.invoiceId,
      paymentMethod: event.paymentMethod,
      transactionId: event.transactionId,
    );
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (updatedInvoice) {
        _currentInvoices = _currentInvoices
            .map((i) => i.id == updatedInvoice.id ? updatedInvoice : i)
            .toList();
        emit(InvoiceActionSuccess(
          message: 'Thanh toán thành công!',
          invoices: _currentInvoices,
        ));
        emit(InvoiceDetailLoaded(updatedInvoice));
        emit(InvoicesLoaded(invoices: _currentInvoices));
      },
    );
  }

  Future<void> _onTenantConfirmPayment(
    TenantConfirmPaymentEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoicesLoading());
    final result = await _updateInvoiceUseCase.repository.tenantConfirmPayment(
      event.invoiceId,
      imageBytes: event.imageBytes,
      imageExt: event.imageExt,
    );

    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (updatedInvoice) {
        emit(const InvoiceActionSuccess(message: 'Đã thông báo cho chủ trọ!'));
        // Reload detail or list depending on where they are
        add(LoadInvoiceDetailEvent(updatedInvoice.id));
      },
    );
  }

  Future<void> _onFetchPreviousReadings(
      FetchPreviousReadingsEvent event, Emitter<InvoiceState> emit) async {
    final result = await _getInvoicesUseCase(roomId: event.roomId);
    result.fold(
      (failure) {
        // Lỗi lấy danh sách thì mặc định là 0
        emit(const InvoicePreviousReadingsLoaded(0, 0));
      },
      (invoices) {
        if (invoices.isNotEmpty) {
          // DataSource đã sắp xếp mới nhất lên đầu
          final latest = invoices.first;
          emit(InvoicePreviousReadingsLoaded(
            latest.electricCurrReading,
            latest.waterCurrReading,
          ));
        } else {
          emit(const InvoicePreviousReadingsLoaded(0, 0));
        }
      },
    );
  }

  Future<void> _onUpdateInvoice(
      UpdateInvoiceEvent event, Emitter<InvoiceState> emit) async {
    emit(const InvoicesLoading());
    final result = await _updateInvoiceUseCase(event.invoice);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (updatedInvoice) {
        _currentInvoices = _currentInvoices
            .map((i) => i.id == updatedInvoice.id ? updatedInvoice : i)
            .cast<Invoice>()
            .toList();
        emit(InvoiceActionSuccess(
          message: 'Cập nhật hóa đơn thành công!',
          invoices: _currentInvoices,
        ));
        emit(InvoiceDetailLoaded(updatedInvoice));
        emit(InvoicesLoaded(invoices: _currentInvoices));
      },
    );
  }

  Future<void> _onDeleteInvoice(
      DeleteInvoiceEvent event, Emitter<InvoiceState> emit) async {
    emit(const InvoicesLoading());
    final result = await _deleteInvoiceUseCase(event.invoiceId);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (_) {
        _currentInvoices =
            _currentInvoices.where((i) => i.id != event.invoiceId).toList();
        emit(InvoiceActionSuccess(
          message: 'Xóa hóa đơn thành công!',
          invoices: _currentInvoices,
        ));
        emit(InvoicesLoaded(invoices: _currentInvoices));
      },
    );
  }

  // ── Payment Handlers ──────────────────────────────────────────────────────

  Future<void> _onLoadPayments(
      LoadPaymentsEvent event, Emitter<InvoiceState> emit) async {
    final result =
        await _getPaymentsByInvoiceUseCase(event.invoiceId);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (payments) => emit(PaymentsLoaded(payments)),
    );
  }

  /// Chỉ Admin/Owner được phép tạo giao dịch thanh toán
  Future<void> _onCreatePayment(
      CreatePaymentEvent event, Emitter<InvoiceState> emit) async {
    // Kiểm tra quyền
    if (!event.isOwner) {
      emit(const InvoiceError('Chỉ chủ trọ mới được ghi nhận thanh toán.'));
      return;
    }

    emit(const PaymentCreating());
    final result = await _createPaymentUseCase(
      invoiceId: event.invoiceId,
      amount: event.amount,
      paymentMethod: event.paymentMethod,
      transactionId: event.transactionId,
    );
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (payment) {
        emit(const InvoiceActionSuccess(
          message: 'Ghi nhận thanh toán thành công!',
        ));
        // Reload invoice detail để cập nhật status sang PAID
        add(LoadInvoiceDetailEvent(event.invoiceId));
        // Reload danh sách giao dịch
        add(LoadPaymentsEvent(event.invoiceId));
      },
    );
  }
}
