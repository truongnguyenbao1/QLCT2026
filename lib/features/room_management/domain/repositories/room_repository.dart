// lib/features/room_management/domain/repositories/room_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/room.dart';

abstract class RoomRepository {
  Future<Either<Failure, List<Room>>> getRooms(String propertyId);
  Future<Either<Failure, Room>> getRoomById(String roomId);
  Future<Either<Failure, Room>> createRoom(Room room);
  Future<Either<Failure, Room>> updateRoom(Room room);
  Future<Either<Failure, void>> deleteRoom(String roomId);
  Future<Either<Failure, List<Room>>> getRoomsByStatus(
      String propertyId, RoomStatus status);
  Stream<List<Room>> watchRooms(String propertyId);
}
