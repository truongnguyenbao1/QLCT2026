// lib/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../invoice/domain/repositories/invoice_repository.dart';
import '../../../room_management/domain/entities/room.dart';
import '../../../room_management/domain/repositories/room_repository.dart';

class DashboardStats {
  final int totalRooms;
  final int occupiedRooms;
  final int emptyRooms;
  final int maintenanceRooms;
  final double monthlyRevenue;
  final int pendingInvoices;
  final int overdueInvoices;

  const DashboardStats({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.emptyRooms,
    required this.maintenanceRooms,
    required this.monthlyRevenue,
    required this.pendingInvoices,
    required this.overdueInvoices,
  });

  double get occupancyRate =>
      totalRooms == 0 ? 0.0 : occupiedRooms / totalRooms;
}

class GetDashboardStatsUseCase {
  final RoomRepository _roomRepository;
  final InvoiceRepository _invoiceRepository;

  const GetDashboardStatsUseCase(this._roomRepository, this._invoiceRepository);

  Future<Either<Failure, DashboardStats>> call(String propertyId) async {
    try {
      final roomsResult = await _roomRepository.getRooms(propertyId);
      final invoicesResult = await _invoiceRepository.getInvoices(
        propertyId: propertyId,
        month: DateTime.now().month,
        year: DateTime.now().year,
      );

      return roomsResult.fold(
        (failure) => Left(failure),
        (rooms) {
          return invoicesResult.fold(
            (failure) => Left(failure),
            (invoices) {
              final occupied =
                  rooms.where((r) => r.status == RoomStatus.occupied).length;
              final empty =
                  rooms.where((r) => r.status == RoomStatus.empty).length;
              final maintenance =
                  rooms.where((r) => r.status == RoomStatus.maintenance).length;

              final monthlyRevenue = invoices.fold<double>(
                0.0,
                (sum, inv) => sum + inv.totalAmount,
              );

              return Right(DashboardStats(
                totalRooms: rooms.length,
                occupiedRooms: occupied,
                emptyRooms: empty,
                maintenanceRooms: maintenance,
                monthlyRevenue: monthlyRevenue,
                pendingInvoices: 0,
                overdueInvoices: 0,
              ));
            },
          );
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
