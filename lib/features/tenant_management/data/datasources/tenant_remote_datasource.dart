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
    return data
        .map((e) => TenantModel.fromJson(e as Map<String, dynamic>))
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
    return TenantModel.fromJson(data);
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
