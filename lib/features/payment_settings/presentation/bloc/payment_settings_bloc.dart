// lib/features/payment_settings/presentation/bloc/payment_settings_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payment_settings.dart';
import '../../domain/repositories/payment_settings_repository.dart';
import 'payment_settings_event.dart';
import 'payment_settings_state.dart';

class PaymentSettingsBloc
    extends Bloc<PaymentSettingsEvent, PaymentSettingsState> {
  final PaymentSettingsRepository _repository;

  PaymentSettingsBloc(this._repository)
      : super(const PaymentSettingsInitial()) {
    on<LoadPaymentSettingsEvent>(_onLoad);
    on<SavePaymentSettingsEvent>(_onSave);
  }

  Future<void> _onLoad(
    LoadPaymentSettingsEvent event,
    Emitter<PaymentSettingsState> emit,
  ) async {
    emit(const PaymentSettingsLoading());
    try {
      final settings = await _repository.getByUserId(event.userId);
      emit(PaymentSettingsLoaded(settings));
    } catch (e) {
      emit(PaymentSettingsError('Không thể tải cài đặt: $e'));
    }
  }

  Future<void> _onSave(
    SavePaymentSettingsEvent event,
    Emitter<PaymentSettingsState> emit,
  ) async {
    emit(const PaymentSettingsSaving());
    try {
      // Lấy id hiện tại nếu có
      final currentState = state;
      final existingId = (currentState is PaymentSettingsLoaded &&
              currentState.settings != null)
          ? currentState.settings!.id
          : '';

      final settings = PaymentSettings(
        id: existingId,
        userId: event.userId,
        bankCode: event.bankCode,
        bankName: event.bankName,
        accountNumber: event.accountNumber,
        accountName: event.accountName,
        transferNoteTemplate: event.transferNoteTemplate,
        momoPhone: event.momoPhone,
        vnpayQr: event.vnpayQr,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saved = await _repository.save(settings);
      emit(PaymentSettingsSaved(saved));
    } catch (e) {
      emit(PaymentSettingsError('Lưu thất bại: $e'));
    }
  }
}
