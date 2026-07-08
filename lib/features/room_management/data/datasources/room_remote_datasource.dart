// lib/features/room_management/data/datasources/room_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/room_model.dart';
import '../../domain/entities/room.dart';

abstract class RoomRemoteDataSource {
  Future<List<RoomModel>> getRooms(String propertyId);
  Future<RoomModel> getRoomById(String roomId);
  Future<RoomModel> createRoom(RoomModel room);
  Future<RoomModel> updateRoom(RoomModel room);
  Future<void> deleteRoom(String roomId);
  Future<List<RoomModel>> getRoomsByStatus(String propertyId, RoomStatus status);
  Stream<List<RoomModel>> watchRooms(String propertyId);
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  final SupabaseClient _client;

  RoomRemoteDataSourceImpl(this._client);

  @override
  Future<List<RoomModel>> getRooms(String propertyId) async {
    try {
      final data = await _client
          .from(AppConstants.tableRooms)
          .select()
          .eq('property_id', propertyId)
          .order('floor')
          .order('room_number');

      return (data as List).map((e) => RoomModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure(message: 'Lỗi tải danh sách phòng: $e');
    }
  }

  @override
  Future<RoomModel> getRoomById(String roomId) async {
    try {
      final data = await _client
          .from(AppConstants.tableRooms)
          .select()
          .eq('id', roomId)
          .single();
      return RoomModel.fromJson(data);
    } catch (e) {
      throw NotFoundFailure(message: 'Không tìm thấy phòng: $roomId');
    }
  }

  @override
  Future<RoomModel> createRoom(RoomModel room) async {
    try {
      final data = await _client
          .from(AppConstants.tableRooms)
          .insert(room.toJson())
          .select()
          .single();
      return RoomModel.fromJson(data);
    } catch (e) {
      if (e.toString().contains('duplicate')) {
        throw const DuplicateFailure(message: 'Số phòng đã tồn tại trong dãy trọ này.');
      }
      throw ServerFailure(message: 'Lỗi tạo phòng: $e');
    }
  }

  @override
  Future<RoomModel> updateRoom(RoomModel room) async {
    try {
      final data = await _client
          .from(AppConstants.tableRooms)
          .update(room.toUpdateJson())
          .eq('id', room.id)
          .select()
          .single();
      return RoomModel.fromJson(data);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi cập nhật phòng: $e');
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    try {
      // Kiểm tra phòng có đang cho thuê không
      final occupiedCheck = await _client
          .from(AppConstants.tableRooms)
          .select('status')
          .eq('id', roomId)
          .single();

      if (occupiedCheck['status'] == 'OCCUPIED') {
        throw const RoomOccupiedFailure();
      }

      await _client.from(AppConstants.tableRooms).delete().eq('id', roomId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: 'Lỗi xóa phòng: $e');
    }
  }

  @override
  Future<List<RoomModel>> getRoomsByStatus(
      String propertyId, RoomStatus status) async {
    try {
      final data = await _client
          .from(AppConstants.tableRooms)
          .select()
          .eq('property_id', propertyId)
          .eq('status', status.code)
          .order('room_number');

      return (data as List).map((e) => RoomModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Stream<List<RoomModel>> watchRooms(String propertyId) {
    return _client
        .from(AppConstants.tableRooms)
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .order('floor')
        .map((data) => data.map((e) => RoomModel.fromJson(e)).toList());
  }
}
