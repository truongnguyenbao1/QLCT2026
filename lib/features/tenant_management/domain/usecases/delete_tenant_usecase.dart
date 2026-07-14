import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/tenant_repository.dart';

class DeleteTenantUseCase {
  final TenantRepository repository;

  DeleteTenantUseCase(this.repository);

  Future<Either<Failure, void>> call(String tenantId) async {
    return await repository.deleteTenant(tenantId);
  }
}
