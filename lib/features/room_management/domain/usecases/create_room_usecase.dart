// lib/features/room_management/domain/usecases/create_room_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/room.dart';
import '../repositories/room_repository.dart';

class CreateRoomUseCase {
  final RoomRepository _repository;
  CreateRoomUseCase(this._repository);
  Future<Either<Failure, Room>> call(Room room) =>
      _repository.createRoom(room);
}
