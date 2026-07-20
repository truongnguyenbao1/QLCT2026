import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_settings_model.dart';

abstract class PaymentSettingsRemoteDataSource {
  Future<PaymentSettingsModel?> getByUserId(String userId);
  Future<PaymentSettingsModel> upsert(Map<String, dynamic> data, String userId);
  Future<String> uploadMomoQr(String userId, String filePath);
}

class PaymentSettingsRemoteDataSourceImpl
    implements PaymentSettingsRemoteDataSource {
  final SupabaseClient _client;

  PaymentSettingsRemoteDataSourceImpl(this._client);

  static const _table = 'caidat_thanhtoan';

  @override
  Future<PaymentSettingsModel?> getByUserId(String userId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return PaymentSettingsModel.fromJson(response);
  }

  @override
  Future<PaymentSettingsModel> upsert(
      Map<String, dynamic> data, String userId) async {
    // Kiểm tra đã tồn tại chưa
    final existing = await _client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    Map<String, dynamic> result;

    if (existing != null) {
      // UPDATE
      result = await _client
          .from(_table)
          .update(data)
          .eq('user_id', userId)
          .select()
          .single();
    } else {
      // INSERT
      result = await _client
          .from(_table)
          .insert({...data, 'user_id': userId})
          .select()
          .single();
    }

    return PaymentSettingsModel.fromJson(result);
  }

  @override
  Future<String> uploadMomoQr(String userId, String filePath) async {
    final fileName = '$userId.png'; // Ghi đè file cũ nếu có
    await _client.storage.from('payment_qrs').upload(
          fileName,
          File(filePath),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
    
    return _client.storage.from('payment_qrs').getPublicUrl(fileName);
  }
}
