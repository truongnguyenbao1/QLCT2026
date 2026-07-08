// lib/features/room_management/domain/usecases/update_room_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/room.dart';
import '../repositories/room_repository.dart';

class UpdateRoomUseCase {
  final RoomRepository _repository;
  UpdateRoomUseCase(this._repository);
  Future<Either<Failure, Room>> call(Room room) =>
      _repository.updateRoom(room);
}
