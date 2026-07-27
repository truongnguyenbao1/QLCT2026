// lib/features/system_logs/data/repositories/system_log_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/system_log_model.dart';
import '../../domain/entities/system_log.dart';

@lazySingleton
class SystemLogRepository {
  final SupabaseClient _supabase;

  SystemLogRepository(this._supabase);

  /// Lấy danh sách logs cho một nhà trọ cụ thể
  Future<List<SystemLog>> getLogs(String propertyId) async {
    try {
      final response = await _supabase
          .from('nhatky_hethong')
          .select()
          .eq('property_id', propertyId)
          .order('created_at', ascending: false)
          .limit(100); // Lấy 100 log gần nhất

      return (response as List).map((json) => SystemLogModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy nhật ký: $e');
    }
  }

  /// Hàm hỗ trợ ghi log, được gọi từ các Repository khác
  Future<void> logAction({
    required String action,
    required String tableName,
    required String recordId,
    String? propertyId,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final log = SystemLogModel(
        id: '', // Supabase sẽ tự tạo uuid
        propertyId: propertyId,
        userId: userId,
        action: action,
        tableName: tableName,
        recordId: recordId,
        newValue: newValue,
        createdAt: DateTime.now(),
      );

      await _supabase.from('nhatky_hethong').insert(log.toJson());
    } catch (e) {
      // Ghi log lỗi nội bộ nếu có
      print('Lỗi ghi nhật ký hệ thống: $e');
    }
  }
}
