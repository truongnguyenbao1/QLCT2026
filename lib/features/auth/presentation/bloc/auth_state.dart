// lib/features/auth/presentation/bloc/auth_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/app_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Đã đăng nhập nhưng chưa chấp nhận Privacy Policy
class AuthNeedPrivacyAcceptance extends AuthState {
  final AppUser user;
  const AuthNeedPrivacyAcceptance(this.user);
  @override
  List<Object?> get props => [user];
}

/// Chủ trọ đã đăng nhập nhưng chưa đăng ký dãy trọ
class AuthNeedPropertySetup extends AuthState {
  final AppUser user;
  const AuthNeedPropertySetup(this.user);
  @override
  List<Object?> get props => [user];
}

/// Đăng nhập bằng Google nhưng chưa cung cấp đủ thông tin bắt buộc (ví dụ: role, SĐT)
class AuthNeedProfileCompletion extends AuthState {
  final String email;
  final String fullName;

  const AuthNeedProfileCompletion({required this.email, required this.fullName});

  @override
  List<Object?> get props => [email, fullName];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
