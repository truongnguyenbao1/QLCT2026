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
        .select()
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
        .select()
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
      await _client
          .from('phong')
          .update({'status': 'OCCUPIED'})
          .eq('id', tenant.roomId);
    } catch (e) {
      // Bỏ qua lỗi cập nhật trạng thái phòng (non-blocking)
    }

    // Cập nhật room_id và property_id cho tài khoản khách thuê (nếu có)
    await _syncTenantToUser(tenant);
        
    return TenantModel.fromJson(data);
  }

  Future<void> _syncTenantToUser(TenantModel tenant) async {
    try {
      final updateData = {
        'room_id': tenant.roomId,
        'property_id': tenant.propertyId,
      };

      if (tenant.email != null && tenant.email!.isNotEmpty) {
        await _client.from(AppConstants.tableUsers).update(updateData).eq('email', tenant.email!);
      } else if (tenant.phoneNumber.isNotEmpty) {
        // Fallback sync by phone number if email is not available
        await _client.from(AppConstants.tableUsers).update(updateData).eq('phone', tenant.phoneNumber);
      }
    } catch (e) {
      // Bỏ qua lỗi (không chặn flow chính)
    }
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
        
    // Đồng bộ lại room_id và property_id cho tài khoản khách thuê
    await _syncTenantToUser(tenant);
    
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
