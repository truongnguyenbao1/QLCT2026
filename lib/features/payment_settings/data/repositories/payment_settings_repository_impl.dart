// lib/features/payment_settings/data/repositories/payment_settings_repository_impl.dart
import '../../domain/entities/payment_settings.dart';
import '../../domain/repositories/payment_settings_repository.dart';
import '../datasources/payment_settings_remote_datasource.dart';
import '../models/payment_settings_model.dart';

class PaymentSettingsRepositoryImpl implements PaymentSettingsRepository {
  final PaymentSettingsRemoteDataSource _dataSource;

  PaymentSettingsRepositoryImpl(this._dataSource);

  @override
  Future<PaymentSettings?> getByUserId(String userId) async {
    return _dataSource.getByUserId(userId);
  }

  @override
  Future<PaymentSettings> save(PaymentSettings settings) async {
    final model = PaymentSettingsModel.fromEntity(settings);
    final data = model.toJson();
    data.remove('id');
    data.remove('user_id');
    data.remove('created_at');
    data.remove('updated_at');

    return _dataSource.upsert(data, settings.userId);
  }
}
