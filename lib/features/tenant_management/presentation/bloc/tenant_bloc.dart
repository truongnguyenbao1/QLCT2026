// lib/features/tenant_management/presentation/bloc/tenant_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/usecases/create_tenant_usecase.dart';
import '../../domain/usecases/get_tenants_usecase.dart';
import '../../domain/usecases/update_tenant_usecase.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class TenantEvent extends Equatable {
  const TenantEvent();
  @override
  List<Object?> get props => [];
}

class LoadTenantsEvent extends TenantEvent {
  final String? propertyId;
  final String? roomId;
  final bool? isActive;
  const LoadTenantsEvent({this.propertyId, this.roomId, this.isActive});
  @override
  List<Object?> get props => [propertyId, roomId, isActive];
}

class CreateTenantEvent extends TenantEvent {
  final Tenant tenant;
  const CreateTenantEvent(this.tenant);
  @override
  List<Object?> get props => [tenant];
}

class UpdateTenantEvent extends TenantEvent {
  final Tenant tenant;
  const UpdateTenantEvent(this.tenant);
  @override
  List<Object?> get props => [tenant];
}

// ── States ────────────────────────────────────────────────────────────────
abstract class TenantState extends Equatable {
  const TenantState();
  @override
  List<Object?> get props => [];
}

class TenantInitial extends TenantState {
  const TenantInitial();
}

class TenantLoading extends TenantState {
  const TenantLoading();
}

class TenantLoaded extends TenantState {
  final List<Tenant> tenants;
  const TenantLoaded(this.tenants);
  @override
  List<Object?> get props => [tenants];
}

class TenantError extends TenantState {
  final String message;
  const TenantError(this.message);
  @override
  List<Object?> get props => [message];
}

class TenantOperationSuccess extends TenantState {
  final String message;
  const TenantOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────
class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final GetTenantsUseCase _getTenantsUseCase;
  final CreateTenantUseCase _createTenantUseCase;
  final UpdateTenantUseCase _updateTenantUseCase;

  TenantBloc({
    required GetTenantsUseCase getTenantsUseCase,
    required CreateTenantUseCase createTenantUseCase,
    required UpdateTenantUseCase updateTenantUseCase,
  })  : _getTenantsUseCase = getTenantsUseCase,
        _createTenantUseCase = createTenantUseCase,
        _updateTenantUseCase = updateTenantUseCase,
        super(const TenantInitial()) {
    on<LoadTenantsEvent>(_onLoadTenants);
    on<CreateTenantEvent>(_onCreateTenant);
    on<UpdateTenantEvent>(_onUpdateTenant);
  }

  Future<void> _onLoadTenants(
    LoadTenantsEvent event,
    Emitter<TenantState> emit,
  ) async {
    emit(const TenantLoading());
    final result = await _getTenantsUseCase(
      propertyId: event.propertyId,
      roomId: event.roomId,
      isActive: event.isActive,
    );
    result.fold(
      (failure) => emit(TenantError(failure.message)),
      (tenants) => emit(TenantLoaded(tenants)),
    );
  }

  Future<void> _onCreateTenant(
    CreateTenantEvent event,
    Emitter<TenantState> emit,
  ) async {
    emit(const TenantLoading());
    final result = await _createTenantUseCase(event.tenant);
    result.fold(
      (failure) => emit(TenantError(failure.message)),
      (_) => emit(const TenantOperationSuccess('Thêm khách thuê thành công')),
    );
  }

  Future<void> _onUpdateTenant(
    UpdateTenantEvent event,
    Emitter<TenantState> emit,
  ) async {
    emit(const TenantLoading());
    final result = await _updateTenantUseCase(event.tenant);
    result.fold(
      (failure) => emit(TenantError(failure.message)),
      (_) => emit(const TenantOperationSuccess('Cập nhật khách thuê thành công')),
    );
  }
}
