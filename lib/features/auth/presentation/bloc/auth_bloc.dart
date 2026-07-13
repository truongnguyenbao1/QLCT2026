// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckSessionUseCase _checkSessionUseCase;
  final RegisterUseCase _registerUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required CheckSessionUseCase checkSessionUseCase,
    required RegisterUseCase registerUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _checkSessionUseCase = checkSessionUseCase,
        _registerUseCase = registerUseCase,
        super(const AuthInitial()) {
    on<AuthCheckSessionEvent>(_onCheckSession);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthAcceptPrivacyPolicyEvent>(_onAcceptPrivacyPolicy);
    on<AuthPropertySetupCompletedEvent>(_onPropertySetupCompleted);
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
    final result = await _registerUseCase.call(
      RegisterParams(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        phone: event.phone,
        role: event.role,
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
    if (currentState is AuthNeedPrivacyAcceptance) {
      final updatedUser = currentState.user.copyWith(hasAcceptedPrivacyPolicy: true);
      // Kiểm tra chủ trọ có cần đăng ký dãy trọ không
      if (updatedUser.isOwner && (updatedUser.propertyId == null || updatedUser.propertyId!.isEmpty)) {
        emit(AuthNeedPropertySetup(updatedUser));
      } else {
        emit(AuthAuthenticated(updatedUser));
      }
    }
  }

  Future<void> _onPropertySetupCompleted(
    AuthPropertySetupCompletedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthAuthenticated(event.updatedUser));
  }
}
