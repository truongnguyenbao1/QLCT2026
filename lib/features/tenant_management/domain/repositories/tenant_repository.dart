// lib/features/tenant_management/domain/repositories/tenant_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tenant.dart';

abstract class TenantRepository {
  Future<Either<Failure, List<Tenant>>> getTenants({
    String? propertyId,
    String? roomId,
    bool? isActive,
  });
  Future<Either<Failure, Tenant>> getTenantById(String tenantId);
  Future<Either<Failure, Tenant>> createTenant(Tenant tenant);
  Future<Either<Failure, Tenant>> updateTenant(Tenant tenant);
  Future<Either<Failure, void>> deleteTenant(String tenantId);
}
