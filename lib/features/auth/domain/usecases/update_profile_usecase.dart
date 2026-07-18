// lib/features/auth/domain/usecases/update_profile_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, AppUser>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      userId: params.userId,
      fullName: params.fullName,
      phone: params.phone,
    );
  }
}

class UpdateProfileParams {
  final String userId;
  final String fullName;
  final String phone;

  const UpdateProfileParams({
    required this.userId,
    required this.fullName,
    required this.phone,
  });
}
