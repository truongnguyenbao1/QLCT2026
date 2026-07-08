// lib/features/room_management/data/repositories/room_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/room_remote_datasource.dart';
import '../models/room_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _dataSource;
  RoomRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<Room>>> getRooms(String propertyId) async {
    try {
      final rooms = await _dataSource.getRooms(propertyId);
      return Right(rooms);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Room>> getRoomById(String roomId) async {
    try {
      return Right(await _dataSource.getRoomById(roomId));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Room>> createRoom(Room room) async {
    try {
      final model = RoomModel(
        id: '',
        propertyId: room.propertyId,
        roomNumber: room.roomNumber,
        floor: room.floor,
        area: room.area,
        rentPrice: room.rentPrice,
        electricPrice: room.electricPrice,
        waterPrice: room.waterPrice,
        servicePrice: room.servicePrice,
        status: room.status,
        amenities: room.amenities,
        description: room.description,
        imageUrls: room.imageUrls,
        maxOccupants: room.maxOccupants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return Right(await _dataSource.createRoom(model));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Room>> updateRoom(Room room) async {
    try {
      final model = RoomModel(
        id: room.id,
        propertyId: room.propertyId,
        roomNumber: room.roomNumber,
        floor: room.floor,
        area: room.area,
        rentPrice: room.rentPrice,
        electricPrice: room.electricPrice,
        waterPrice: room.waterPrice,
        servicePrice: room.servicePrice,
        status: room.status,
        amenities: room.amenities,
        description: room.description,
        imageUrls: room.imageUrls,
        maxOccupants: room.maxOccupants,
        createdAt: room.createdAt,
        updatedAt: DateTime.now(),
      );
      return Right(await _dataSource.updateRoom(model));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoom(String roomId) async {
    try {
      await _dataSource.deleteRoom(roomId);
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Room>>> getRoomsByStatus(
      String propertyId, RoomStatus status) async {
    try {
      return Right(await _dataSource.getRoomsByStatus(propertyId, status));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Room>> watchRooms(String propertyId) =>
      _dataSource.watchRooms(propertyId);
}
