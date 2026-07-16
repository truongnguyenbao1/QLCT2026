// lib/features/room_management/domain/entities/room.dart
import 'package:equatable/equatable.dart';

enum RoomStatus { empty, occupied, maintenance }

extension RoomStatusExt on RoomStatus {
  String get displayName {
    switch (this) {
      case RoomStatus.empty:
        return 'Còn trống';
      case RoomStatus.occupied:
        return 'Đang thuê';
      case RoomStatus.maintenance:
        return 'Bảo trì';
    }
  }

  String get code {
    switch (this) {
      case RoomStatus.empty:
        return 'EMPTY';
      case RoomStatus.occupied:
        return 'OCCUPIED';
      case RoomStatus.maintenance:
        return 'MAINTENANCE';
    }
  }

  static RoomStatus fromCode(String code) {
    switch (code) {
      case 'OCCUPIED':
        return RoomStatus.occupied;
      case 'MAINTENANCE':
        return RoomStatus.maintenance;
      default:
        return RoomStatus.empty;
    }
  }
}

class Room extends Equatable {
  final String id;
  final String propertyId;
  final String roomNumber;   // Tên/số phòng: "101", "A2", "Phòng 3"
  final int? floor;           // Tầng
  final double area;         // Diện tích m²
  final double rentPrice;    // Giá thuê/tháng (VND)
  final double electricPrice;   // Giá điện /kWh
  final double waterPrice;      // Giá nước /m³
  final double servicePrice;    // Phí dịch vụ/tháng (internet, vệ sinh, ...)
  final RoomStatus status;
  final List<String> amenities; // ["WiFi", "điều hòa", "máy lạnh", "nóng lạnh"]
  final String? description;
  final List<String> imageUrls;
  final int? maxOccupants;   // Số người tối đa
  final DateTime createdAt;
  final DateTime updatedAt;

  const Room({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    this.floor,
    required this.area,
    required this.rentPrice,
    required this.electricPrice,
    required this.waterPrice,
    required this.servicePrice,
    required this.status,
    this.amenities = const [],
    this.description,
    this.imageUrls = const [],
    this.maxOccupants,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmpty => status == RoomStatus.empty;
  bool get isOccupied => status == RoomStatus.occupied;
  bool get isMaintenance => status == RoomStatus.maintenance;

  /// Tổng chi phí ước tính /tháng (không tính điện nước biến đổi)
  double get estimatedMonthlyTotal => rentPrice + servicePrice;

  Room copyWith({
    String? roomNumber,
    int? floor,
    double? area,
    double? rentPrice,
    double? electricPrice,
    double? waterPrice,
    double? servicePrice,
    RoomStatus? status,
    List<String>? amenities,
    String? description,
    List<String>? imageUrls,
    int? maxOccupants,
  }) {
    return Room(
      id: id,
      propertyId: propertyId,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      area: area ?? this.area,
      rentPrice: rentPrice ?? this.rentPrice,
      electricPrice: electricPrice ?? this.electricPrice,
      waterPrice: waterPrice ?? this.waterPrice,
      servicePrice: servicePrice ?? this.servicePrice,
      status: status ?? this.status,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      maxOccupants: maxOccupants ?? this.maxOccupants,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        roomNumber,
        floor,
        rentPrice,
        status,
      ];
}
