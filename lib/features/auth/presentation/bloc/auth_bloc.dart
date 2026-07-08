// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckSessionUseCase _checkSessionUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required CheckSessionUseCase checkSessionUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _checkSessionUseCase = checkSessionUseCase,
        super(const AuthInitial()) {
    on<AuthCheckSessionEvent>(_onCheckSession);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthAcceptPrivacyPolicyEvent>(_onAcceptPrivacyPolicy);
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

  Future<void> _onAcceptPrivacyPolicy(
    AuthAcceptPrivacyPolicyEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthNeedPrivacyAcceptance) {
      // User đã chấp nhận, chuyển sang Authenticated
      final updatedUser =
          currentState.user.copyWith(hasAcceptedPrivacyPolicy: true);
      emit(AuthAuthenticated(updatedUser));
    }
  }
}
