// lib/features/payment_settings/domain/repositories/payment_settings_repository.dart

import '../entities/payment_settings.dart';

abstract class PaymentSettingsRepository {
  /// Lấy cài đặt thanh toán theo userId
  Future<PaymentSettings?> getByUserId(String userId);

  /// Lưu (upsert) cài đặt thanh toán
  Future<PaymentSettings> save(PaymentSettings settings);
}
