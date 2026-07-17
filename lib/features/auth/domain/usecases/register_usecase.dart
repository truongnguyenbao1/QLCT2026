import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final UserRole role;
  final String? cccd;

  RegisterParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
    this.cccd,
  });
}

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, AppUser>> call(RegisterParams params) {
    return repository.register(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      phone: params.phone,
      role: params.role,
      cccd: params.cccd,
    );
  }
}
