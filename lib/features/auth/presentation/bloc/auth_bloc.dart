import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/usecases/check_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/security/encryption_service.dart';
import '../../domain/entities/app_user.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckSessionUseCase _checkSessionUseCase;
  final RegisterUseCase _registerUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final AuthRemoteDataSource _authDataSource;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required CheckSessionUseCase checkSessionUseCase,
    required RegisterUseCase registerUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required AuthRemoteDataSource authDataSource,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _checkSessionUseCase = checkSessionUseCase,
        _registerUseCase = registerUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _authDataSource = authDataSource,
        super(const AuthInitial()) {
    on<AuthCheckSessionEvent>(_onCheckSession);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthAcceptPrivacyPolicyEvent>(_onAcceptPrivacyPolicy);
    on<AuthPropertySetupCompletedEvent>(_onPropertySetupCompleted);
    on<AuthUpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onCheckSession(
    AuthCheckSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _checkSessionUseCase.call();
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) {
        if (user == null) {
          emit(const AuthUnauthenticated());
        } else if (user.phone == null || user.phone!.isEmpty) {
          emit(AuthNeedProfileCompletion(email: user.email, fullName: user.fullName));
        } else if (!user.hasAcceptedPrivacyPolicy) {
          emit(AuthNeedPrivacyAcceptance(user));
        } else if (user.isOwner && (user.propertyId == null || user.propertyId!.isEmpty)) {
          emit(AuthNeedPropertySetup(user));
        } else {
          emit(AuthAuthenticated(user));
        }
      },
    );
  }

  Future<void> _onLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUseCase.call(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        if (!user.hasAcceptedPrivacyPolicy) {
          emit(AuthNeedPrivacyAcceptance(user));
        } else if (user.isOwner && (user.propertyId == null || user.propertyId!.isEmpty)) {
          emit(AuthNeedPropertySetup(user));
        } else {
          emit(AuthAuthenticated(user));
        }
      },
    );
  }

  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase.call();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onRegister(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Nếu đăng nhập qua OAuth (Google) thì chỉ cần cập nhật profile
    if (event.isOAuth) {
      final session = sb.Supabase.instance.client.auth.currentSession;
      if (session == null) {
        emit(const AuthError('Phiên đăng nhập đã hết hạn. Vui lòng thử lại.'));
        return;
      }
      try {
        final userId = session.user.id;
        
        // Liên kết CCCD nếu là khách thuê
        if (event.role == UserRole.tenant && event.cccd != null && event.cccd!.isNotEmpty) {
          final encryptedCccd = await getIt<EncryptionService>().encryptText(event.cccd!);
          final response = await sb.Supabase.instance.client.rpc('check_tenant_cccd', params: {'p_encrypted_cccd': encryptedCccd});
          
          if (response == null) {
            emit(const AuthError('Không tìm thấy thông tin hợp đồng thuê khớp với CCCD này. Vui lòng liên hệ chủ trọ!'));
            return;
          }
          final tenantData = response as Map<String, dynamic>;
          final tenantId = tenantData['id'];
          final roomId = tenantData['room_id'];
          final propertyId = tenantData['property_id'];

          await sb.Supabase.instance.client.from(AppConstants.tableUsers).update({
            'room_id': roomId,
            'property_id': propertyId,
            'quyenhan': event.role.code,
            'tenuser': event.fullName,
            'sdt': event.phone,
          }).eq('iduser', userId);

          await sb.Supabase.instance.client.rpc('link_tenant_to_user', params: {
            'p_tenant_id': tenantId,
            'p_user_id': userId,
            'p_phone': event.phone,
            'p_email': event.email,
          });
        } else {
          // Là chủ trọ
          await sb.Supabase.instance.client.from(AppConstants.tableUsers).update({
            'quyenhan': event.role.code,
            'tenuser': event.fullName,
            'sdt': event.phone,
          }).eq('iduser', userId);
        }
        
        // Kích hoạt check session để reload lại user
        add(const AuthCheckSessionEvent());
        return;
      } catch (e) {
        emit(AuthError(e.toString()));
        return;
      }
    }

    final result = await _registerUseCase.call(
      RegisterParams(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        phone: event.phone,
        role: event.role,
        cccd: event.cccd,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        if (!user.hasAcceptedPrivacyPolicy) {
          emit(AuthNeedPrivacyAcceptance(user));
        } else if (user.isOwner && (user.propertyId == null || user.propertyId!.isEmpty)) {
          emit(AuthNeedPropertySetup(user));
        } else {
          emit(AuthAuthenticated(user));
        }
      },
    );
  }

  Future<void> _onAcceptPrivacyPolicy(
    AuthAcceptPrivacyPolicyEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthNeedPrivacyAcceptance) return;

    emit(const AuthLoading());
    try {
      // Lưu vào Supabase
      await _authDataSource.acceptPrivacyPolicy(currentState.user.id);
    } catch (_) {
      // Không block user nếu lỗi network, vẫn cho tiếp tục
    }

    final updatedUser = currentState.user.copyWith(hasAcceptedPrivacyPolicy: true);
    // Kiểm tra chủ trọ có cần đăng ký dãy trọ không
    if (updatedUser.isOwner && (updatedUser.propertyId == null || updatedUser.propertyId!.isEmpty)) {
      emit(AuthNeedPropertySetup(updatedUser));
    } else {
      emit(AuthAuthenticated(updatedUser));
    }
  }

  Future<void> _onPropertySetupCompleted(
    AuthPropertySetupCompletedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthAuthenticated(event.updatedUser));
  }

  Future<void> _onUpdateProfile(
    AuthUpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    
    emit(const AuthLoading());
    final result = await _updateProfileUseCase.call(
      UpdateProfileParams(
        userId: currentState.user.id,
        fullName: event.fullName,
        phone: event.phone,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

}
