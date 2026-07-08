// lib/features/room_management/presentation/bloc/room_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/room.dart';
import '../../domain/usecases/create_room_usecase.dart';
import '../../domain/usecases/delete_room_usecase.dart';
import '../../domain/usecases/get_rooms_usecase.dart';
import '../../domain/usecases/update_room_usecase.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class RoomEvent extends Equatable {
  const RoomEvent();
  @override
  List<Object?> get props => [];
}

class LoadRoomsEvent extends RoomEvent {
  final String propertyId;
  const LoadRoomsEvent(this.propertyId);
  @override
  List<Object?> get props => [propertyId];
}

class CreateRoomEvent extends RoomEvent {
  final Room room;
  const CreateRoomEvent(this.room);
  @override
  List<Object?> get props => [room];
}

class UpdateRoomEvent extends RoomEvent {
  final Room room;
  const UpdateRoomEvent(this.room);
  @override
  List<Object?> get props => [room];
}

class DeleteRoomEvent extends RoomEvent {
  final String roomId;
  const DeleteRoomEvent(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class FilterRoomsEvent extends RoomEvent {
  final RoomStatus? status;
  const FilterRoomsEvent(this.status);
  @override
  List<Object?> get props => [status];
}

// ── States ────────────────────────────────────────────────────────────────
abstract class RoomState extends Equatable {
  const RoomState();
  @override
  List<Object?> get props => [];
}

class RoomInitial extends RoomState {
  const RoomInitial();
}

class RoomsLoading extends RoomState {
  const RoomsLoading();
}

class RoomsLoaded extends RoomState {
  final List<Room> rooms;
  final List<Room> filteredRooms;
  final RoomStatus? activeFilter;

  const RoomsLoaded({
    required this.rooms,
    required this.filteredRooms,
    this.activeFilter,
  });

  int get emptyCount =>
      rooms.where((r) => r.status == RoomStatus.empty).length;
  int get occupiedCount =>
      rooms.where((r) => r.status == RoomStatus.occupied).length;
  int get maintenanceCount =>
      rooms.where((r) => r.status == RoomStatus.maintenance).length;

  @override
  List<Object?> get props => [rooms, filteredRooms, activeFilter];
}

class RoomActionSuccess extends RoomState {
  final String message;
  final List<Room> rooms;
  const RoomActionSuccess({required this.message, required this.rooms});
  @override
  List<Object?> get props => [message, rooms];
}

class RoomError extends RoomState {
  final String message;
  const RoomError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final GetRoomsUseCase _getRoomsUseCase;
  final CreateRoomUseCase _createRoomUseCase;
  final UpdateRoomUseCase _updateRoomUseCase;
  final DeleteRoomUseCase _deleteRoomUseCase;

  List<Room> _allRooms = [];

  RoomBloc({
    required GetRoomsUseCase getRoomsUseCase,
    required CreateRoomUseCase createRoomUseCase,
    required UpdateRoomUseCase updateRoomUseCase,
    required DeleteRoomUseCase deleteRoomUseCase,
  })  : _getRoomsUseCase = getRoomsUseCase,
        _createRoomUseCase = createRoomUseCase,
        _updateRoomUseCase = updateRoomUseCase,
        _deleteRoomUseCase = deleteRoomUseCase,
        super(const RoomInitial()) {
    on<LoadRoomsEvent>(_onLoadRooms);
    on<CreateRoomEvent>(_onCreateRoom);
    on<UpdateRoomEvent>(_onUpdateRoom);
    on<DeleteRoomEvent>(_onDeleteRoom);
    on<FilterRoomsEvent>(_onFilterRooms);
  }

  Future<void> _onLoadRooms(
      LoadRoomsEvent event, Emitter<RoomState> emit) async {
    emit(const RoomsLoading());
    final result = await _getRoomsUseCase(event.propertyId);
    result.fold(
      (failure) => emit(RoomError(failure.message)),
      (rooms) {
        _allRooms = rooms;
        emit(RoomsLoaded(rooms: rooms, filteredRooms: rooms));
      },
    );
  }

  Future<void> _onCreateRoom(
      CreateRoomEvent event, Emitter<RoomState> emit) async {
    final result = await _createRoomUseCase(event.room);
    result.fold(
      (failure) => emit(RoomError(failure.message)),
      (newRoom) {
        _allRooms = [..._allRooms, newRoom];
        emit(RoomActionSuccess(
          message: 'Thêm phòng ${newRoom.roomNumber} thành công!',
          rooms: _allRooms,
        ));
        emit(RoomsLoaded(rooms: _allRooms, filteredRooms: _allRooms));
      },
    );
  }

  Future<void> _onUpdateRoom(
      UpdateRoomEvent event, Emitter<RoomState> emit) async {
    final result = await _updateRoomUseCase(event.room);
    result.fold(
      (failure) => emit(RoomError(failure.message)),
      (updatedRoom) {
        _allRooms = _allRooms
            .map((r) => r.id == updatedRoom.id ? updatedRoom : r)
            .toList();
        emit(RoomActionSuccess(
          message: 'Cập nhật phòng ${updatedRoom.roomNumber} thành công!',
          rooms: _allRooms,
        ));
        emit(RoomsLoaded(rooms: _allRooms, filteredRooms: _allRooms));
      },
    );
  }

  Future<void> _onDeleteRoom(
      DeleteRoomEvent event, Emitter<RoomState> emit) async {
    final result = await _deleteRoomUseCase(event.roomId);
    result.fold(
      (failure) => emit(RoomError(failure.message)),
      (_) {
        _allRooms = _allRooms.where((r) => r.id != event.roomId).toList();
        emit(RoomActionSuccess(
          message: 'Đã xóa phòng thành công!',
          rooms: _allRooms,
        ));
        emit(RoomsLoaded(rooms: _allRooms, filteredRooms: _allRooms));
      },
    );
  }

  void _onFilterRooms(FilterRoomsEvent event, Emitter<RoomState> emit) {
    final filtered = event.status == null
        ? _allRooms
        : _allRooms.where((r) => r.status == event.status).toList();
    emit(RoomsLoaded(
      rooms: _allRooms,
      filteredRooms: filtered,
      activeFilter: event.status,
    ));
  }
}
