// lib/features/tenant_management/domain/usecases/update_tenant_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tenant.dart';
import '../repositories/tenant_repository.dart';

class UpdateTenantUseCase {
  final TenantRepository _repository;
  const UpdateTenantUseCase(this._repository);

  Future<Either<Failure, Tenant>> call(Tenant tenant) {
    return _repository.updateTenant(tenant);
  }
}
