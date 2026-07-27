// lib/features/room_management/data/repositories/room_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/room_remote_datasource.dart';
import '../models/room_model.dart';

import '../../../system_logs/data/repositories/system_log_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _dataSource;
  final SystemLogRepository _logRepository;
  RoomRepositoryImpl(this._dataSource, this._logRepository);

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
      final createdRoom = await _dataSource.createRoom(model);
      
      // Ghi nhật ký
      _logRepository.logAction(
        action: 'INSERT',
        tableName: 'phong',
        recordId: createdRoom.id,
        propertyId: room.propertyId,
      );
      
      return Right(createdRoom);
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
      final updatedRoom = await _dataSource.updateRoom(model);
      
      // Ghi nhật ký
      _logRepository.logAction(
        action: 'UPDATE',
        tableName: 'phong',
        recordId: room.id,
        propertyId: room.propertyId,
      );
      
      return Right(updatedRoom);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoom(String roomId) async {
    try {
      final room = await _dataSource.getRoomById(roomId);
      await _dataSource.deleteRoom(roomId);
      
      // Ghi nhật ký
      _logRepository.logAction(
        action: 'DELETE',
        tableName: 'phong',
        recordId: roomId,
        propertyId: room.propertyId,
      );
      
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
