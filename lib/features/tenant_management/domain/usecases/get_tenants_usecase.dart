// lib/features/tenant_management/domain/usecases/get_tenants_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tenant.dart';
import '../repositories/tenant_repository.dart';

class GetTenantsUseCase {
  final TenantRepository _repository;
  const GetTenantsUseCase(this._repository);

  Future<Either<Failure, List<Tenant>>> call({
    String? propertyId,
    String? roomId,
    bool? isActive,
  }) {
    return _repository.getTenants(
      propertyId: propertyId,
      roomId: roomId,
      isActive: isActive,
    );
  }
}
