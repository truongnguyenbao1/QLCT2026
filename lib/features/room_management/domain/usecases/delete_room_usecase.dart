// lib/features/room_management/domain/usecases/delete_room_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/room_repository.dart';

class DeleteRoomUseCase {
  final RoomRepository _repository;
  DeleteRoomUseCase(this._repository);
  Future<Either<Failure, void>> call(String roomId) =>
      _repository.deleteRoom(roomId);
}
