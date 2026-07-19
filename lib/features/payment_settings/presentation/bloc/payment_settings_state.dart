// lib/features/payment_settings/presentation/bloc/payment_settings_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/payment_settings.dart';

abstract class PaymentSettingsState extends Equatable {
  const PaymentSettingsState();

  @override
  List<Object?> get props => [];
}

class PaymentSettingsInitial extends PaymentSettingsState {
  const PaymentSettingsInitial();
}

class PaymentSettingsLoading extends PaymentSettingsState {
  const PaymentSettingsLoading();
}

class PaymentSettingsLoaded extends PaymentSettingsState {
  final PaymentSettings? settings; // null = chưa cấu hình
  const PaymentSettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class PaymentSettingsSaving extends PaymentSettingsState {
  const PaymentSettingsSaving();
}

class PaymentSettingsSaved extends PaymentSettingsState {
  final PaymentSettings settings;
  const PaymentSettingsSaved(this.settings);

  @override
  List<Object?> get props => [settings];
}

class PaymentSettingsError extends PaymentSettingsState {
  final String message;
  const PaymentSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
