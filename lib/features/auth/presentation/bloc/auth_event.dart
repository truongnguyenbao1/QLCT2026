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
