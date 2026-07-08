// lib/features/auth/domain/usecases/check_session_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class CheckSessionUseCase {
  final AuthRepository _repository;
  CheckSessionUseCase(this._repository);

  Future<Either<Failure, AppUser?>> call() => _repository.checkSession();
}
