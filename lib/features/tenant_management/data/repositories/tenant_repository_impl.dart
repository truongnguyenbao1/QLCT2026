// lib/features/tenant_management/data/repositories/tenant_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../datasources/tenant_remote_datasource.dart';
import '../models/tenant_model.dart';

class TenantRepositoryImpl implements TenantRepository {
  final TenantRemoteDataSource _remoteDataSource;

  TenantRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Tenant>>> getTenants({
    String? propertyId,
    String? roomId,
    bool? isActive,
  }) async {
    try {
      final tenants = await _remoteDataSource.getTenants(
        propertyId: propertyId,
        roomId: roomId,
        isActive: isActive,
      );
      return Right(tenants);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Tenant>> getTenantById(String tenantId) async {
    try {
      final tenant = await _remoteDataSource.getTenantById(tenantId);
      return Right(tenant);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Tenant>> createTenant(Tenant tenant) async {
    try {
      final model = TenantModel.fromEntity(tenant);
      final result = await _remoteDataSource.createTenant(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Tenant>> updateTenant(Tenant tenant) async {
    try {
      final model = TenantModel.fromEntity(tenant);
      final result = await _remoteDataSource.updateTenant(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTenant(String tenantId) async {
    try {
      await _remoteDataSource.deleteTenant(tenantId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
