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
    on<UploadMomoQrEvent>(_onUploadMomoQr);
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
        momoQrUrl: event.momoQrUrl,
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

  Future<void> _onUploadMomoQr(
    UploadMomoQrEvent event,
    Emitter<PaymentSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PaymentSettingsLoaded || currentState.settings == null) {
      emit(const PaymentSettingsError('Chưa tải cài đặt'));
      return;
    }

    emit(const PaymentSettingsSaving());
    try {
      final url = await _repository.uploadMomoQr(event.userId, event.filePath);
      
      // Update the settings with the new URL
      final updatedSettings = currentState.settings!.copyWith(momoQrUrl: url);
      final saved = await _repository.save(updatedSettings);
      
      emit(PaymentSettingsSaved(saved));
    } catch (e) {
      emit(PaymentSettingsError('Tải ảnh thất bại: $e'));
      // Fallback to previous state
      emit(PaymentSettingsLoaded(currentState.settings));
    }
  }
}
