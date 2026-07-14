import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/usecases/create_invoice_usecase.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/mark_invoice_paid_usecase.dart';

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

class FetchPreviousReadingsEvent extends InvoiceEvent {
  final String roomId;
  const FetchPreviousReadingsEvent(this.roomId);
  @override
  List<Object?> get props => [roomId];
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

// ── BLoC ──────────────────────────────────────────────────────────────────
class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final GetInvoicesUseCase _getInvoicesUseCase;
  final CreateInvoiceUseCase _createInvoiceUseCase;
  final MarkInvoicePaidUseCase _markInvoicePaidUseCase;

  List<Invoice> _currentInvoices = [];

  InvoiceBloc({
    required GetInvoicesUseCase getInvoicesUseCase,
    required CreateInvoiceUseCase createInvoiceUseCase,
    required MarkInvoicePaidUseCase markInvoicePaidUseCase,
  })  : _getInvoicesUseCase = getInvoicesUseCase,
        _createInvoiceUseCase = createInvoiceUseCase,
        _markInvoicePaidUseCase = markInvoicePaidUseCase,
        super(const InvoiceInitial()) {
    on<LoadInvoicesEvent>(_onLoadInvoices);
    on<LoadInvoiceDetailEvent>(_onLoadInvoiceDetail);
    on<CreateInvoiceEvent>(_onCreateInvoice);
    on<MarkInvoicePaidEvent>(_onMarkInvoicePaid);
    on<FetchPreviousReadingsEvent>(_onFetchPreviousReadings);
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
    try {
      final invoice = _currentInvoices.firstWhere((i) => i.id == event.invoiceId);
      emit(InvoiceDetailLoaded(invoice));
    } catch (_) {
      final result = await _getInvoicesUseCase();
      result.fold(
        (failure) => emit(InvoiceError(failure.message)),
        (invoices) {
          _currentInvoices = invoices;
          try {
            final invoice = _currentInvoices.firstWhere((i) => i.id == event.invoiceId);
            emit(InvoiceDetailLoaded(invoice));
          } catch (_) {
            emit(const InvoiceError('Không tìm thấy hóa đơn'));
          }
        },
      );
    }
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
}
