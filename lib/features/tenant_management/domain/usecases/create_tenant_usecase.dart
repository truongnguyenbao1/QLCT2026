// lib/features/tenant_management/domain/usecases/create_tenant_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tenant.dart';
import '../repositories/tenant_repository.dart';

class CreateTenantUseCase {
  final TenantRepository _repository;
  const CreateTenantUseCase(this._repository);

  Future<Either<Failure, Tenant>> call(Tenant tenant) {
    return _repository.createTenant(tenant);
  }
}
