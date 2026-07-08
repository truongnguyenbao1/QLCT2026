// lib/features/room_management/domain/usecases/get_rooms_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/room.dart';
import '../repositories/room_repository.dart';

class GetRoomsUseCase {
  final RoomRepository _repository;
  GetRoomsUseCase(this._repository);
  Future<Either<Failure, List<Room>>> call(String propertyId) =>
      _repository.getRooms(propertyId);
}
