// lib/features/dashboard/presentation/bloc/dashboard_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboardEvent extends DashboardEvent {
  final String propertyId;
  const LoadDashboardEvent(this.propertyId);
  @override
  List<Object?> get props => [propertyId];
}

class RefreshDashboardEvent extends DashboardEvent {
  final String propertyId;
  const RefreshDashboardEvent(this.propertyId);
  @override
  List<Object?> get props => [propertyId];
}

// ── States ────────────────────────────────────────────────────────────────
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  const DashboardLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardStatsUseCase _getStatsUseCase;

  DashboardBloc(this._getStatsUseCase) : super(const DashboardInitial()) {
    on<LoadDashboardEvent>(_onLoad);
    on<RefreshDashboardEvent>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    final result = await _getStatsUseCase(event.propertyId);
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (stats) => emit(DashboardLoaded(stats)),
    );
  }

  Future<void> _onRefresh(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final result = await _getStatsUseCase(event.propertyId);
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (stats) => emit(DashboardLoaded(stats)),
    );
  }
}
