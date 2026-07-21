// lib/features/tenant_management/data/datasources/tenant_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/security/encryption_service.dart';
import '../models/tenant_model.dart';

abstract class TenantRemoteDataSource {
  Future<List<TenantModel>> getTenants({
    String? propertyId,
    String? roomId,
    bool? isActive,
  });
  Future<TenantModel> getTenantById(String tenantId);
  Future<TenantModel> createTenant(TenantModel tenant);
  Future<TenantModel> updateTenant(TenantModel tenant);
  Future<void> deleteTenant(String tenantId);
}

class TenantRemoteDataSourceImpl implements TenantRemoteDataSource {
  final SupabaseClient _client;
  final EncryptionService _encryptionService;

  TenantRemoteDataSourceImpl(this._client, this._encryptionService);

  @override
  Future<List<TenantModel>> getTenants({
    String? propertyId,
    String? roomId,
    bool? isActive,
  }) async {
    var query = _client
        .from(AppConstants.tableTenants)
        .select('*, users(tenuser, sdt, email)')
        .order('full_name', ascending: true);

    final data = await query as List<dynamic>;
    final List<TenantModel> tenants = [];
    for (var e in data) {
      final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
      if (map['cccd_number'] != null && (map['cccd_number'] as String).isNotEmpty) {
        try {
          map['cccd_number'] = await _encryptionService.decryptText(map['cccd_number'] as String);
        } catch (_) {
          // Fallback if decryption fails (e.g. key mismatch due to master key change)
          map['cccd_number'] = '';
        }
      }
      
      // Đồng bộ thông tin từ users nếu có tài khoản
      if (map['users'] != null) {
        final user = map['users'] as Map<String, dynamic>;
        if (user['tenuser'] != null && user['tenuser'].toString().isNotEmpty) {
          map['full_name'] = user['tenuser'];
        }
        if (user['sdt'] != null && user['sdt'].toString().isNotEmpty) {
          map['phone_number'] = user['sdt'];
        }
        if (user['email'] != null && user['email'].toString().isNotEmpty) {
          map['email'] = user['email'];
        }
      }

      tenants.add(TenantModel.fromJson(map));
    }

    return tenants
        .where((t) {
          if (propertyId != null && t.propertyId != propertyId) return false;
          if (roomId != null && t.roomId != roomId) return false;
          if (isActive != null && t.isActive != isActive) return false;
          return true;
        })
        .toList();
  }

  @override
  Future<TenantModel> getTenantById(String tenantId) async {
    final data = await _client
        .from(AppConstants.tableTenants)
        .select('*, users(tenuser, sdt, email)')
        .eq('id', tenantId)
        .single();
    
    final map = Map<String, dynamic>.from(data);
    if (map['cccd_number'] != null && (map['cccd_number'] as String).isNotEmpty) {
      try {
        map['cccd_number'] = await _encryptionService.decryptText(map['cccd_number'] as String);
      } catch (_) {
        map['cccd_number'] = '';
      }
    }
    
    // Đồng bộ thông tin từ users nếu có tài khoản
    if (map['users'] != null) {
      final user = map['users'] as Map<String, dynamic>;
      if (user['tenuser'] != null && user['tenuser'].toString().isNotEmpty) {
        map['full_name'] = user['tenuser'];
      }
      if (user['sdt'] != null && user['sdt'].toString().isNotEmpty) {
        map['phone_number'] = user['sdt'];
      }
      if (user['email'] != null && user['email'].toString().isNotEmpty) {
        map['email'] = user['email'];
      }
    }
    
    return TenantModel.fromJson(map);
  }

  @override
  Future<TenantModel> createTenant(TenantModel tenant) async {
    final json = tenant.toJson();
    // Encrypt sensitive data before saving
    if (tenant.cccdNumber.isNotEmpty) {
      json['cccd_number'] = await _encryptionService.encryptText(tenant.cccdNumber);
    }
    final data = await _client
        .from(AppConstants.tableTenants)
        .insert(json)
        .select()
        .single();
        
    // Cập nhật trạng thái phòng thành OCCUPIED
    try {
      if (tenant.roomId != null) {
        await _client
            .from('phong')
            .update({'status': 'OCCUPIED'})
            .eq('id', tenant.roomId!);
            
        // Tự động tạo bản ghi xác nhận thuê phòng (thuephong)
        await _client.from('thuephong').insert({
          'tenant_id': data['id'],
          'room_id': tenant.roomId,
          'start_date': DateTime.now().toIso8601String(),
          'end_date': null, // Để trống khi đang thuê
          'deposit_amount': 0,
          'status': 'ACTIVE'
        });
      }
    } catch (e) {
      // Bỏ qua lỗi (non-blocking)
    }

        
    return TenantModel.fromJson(data);
  }


  @override
  Future<TenantModel> updateTenant(TenantModel tenant) async {
    final json = tenant.toJson();
    if (tenant.cccdNumber.isNotEmpty) {
      json['cccd_number'] = await _encryptionService.encryptText(tenant.cccdNumber);
    }
    
    final data = await _client
        .from(AppConstants.tableTenants)
        .update(json)
        .eq('id', tenant.id)
        .select()
        .single();
        
    return TenantModel.fromJson(data);
  }

  @override
  Future<void> deleteTenant(String tenantId) async {
    await _client
        .from(AppConstants.tableTenants)
        .delete()
        .eq('id', tenantId);
  }
}
