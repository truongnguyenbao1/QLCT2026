// lib/features/auth/domain/usecases/login_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
}

class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<Either<Failure, AppUser>> call(LoginParams params) {
    return _repository.login(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }
}
