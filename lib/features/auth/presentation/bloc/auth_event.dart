// lib/features/auth/presentation/bloc/auth_event.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/app_user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckSessionEvent extends AuthEvent {
  const AuthCheckSessionEvent();
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

class AuthUserUpdatedEvent extends AuthEvent {
  final AppUser? user;
  const AuthUserUpdatedEvent(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthAcceptPrivacyPolicyEvent extends AuthEvent {
  const AuthAcceptPrivacyPolicyEvent();
}

/// Sự kiện khi chủ trọ hoàn thành đăng ký dãy trọ, cập nhật user trong state
class AuthPropertySetupCompletedEvent extends AuthEvent {
  final AppUser updatedUser;
  const AuthPropertySetupCompletedEvent(this.updatedUser);
  @override
  List<Object?> get props => [updatedUser];
}

class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final UserRole role;

  const AuthRegisterEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, fullName, phone, role];
}
