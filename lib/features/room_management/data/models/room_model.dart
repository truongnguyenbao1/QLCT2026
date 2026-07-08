// lib/features/room_management/data/models/room_model.dart
import '../../domain/entities/room.dart';

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.propertyId,
    required super.roomNumber,
    required super.floor,
    required super.area,
    required super.rentPrice,
    required super.electricPrice,
    required super.waterPrice,
    required super.servicePrice,
    required super.status,
    super.amenities,
    super.description,
    super.imageUrls,
    super.maxOccupants,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      roomNumber: json['room_number'] as String,
      floor: (json['floor'] as num?)?.toInt() ?? 1,
      area: (json['area'] as num?)?.toDouble() ?? 0,
      rentPrice: (json['rent_price'] as num?)?.toDouble() ?? 0,
      electricPrice: (json['electric_price'] as num?)?.toDouble() ?? 3500,
      waterPrice: (json['water_price'] as num?)?.toDouble() ?? 15000,
      servicePrice: (json['service_price'] as num?)?.toDouble() ?? 0,
      status: RoomStatusExt.fromCode(json['status'] as String? ?? 'EMPTY'),
      amenities: List<String>.from(json['amenities'] as List? ?? []),
      description: json['description'] as String?,
      imageUrls: List<String>.from(json['image_urls'] as List? ?? []),
      maxOccupants: (json['max_occupants'] as num?)?.toInt(),
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'room_number': roomNumber,
      'floor': floor,
      'area': area,
      'rent_price': rentPrice,
      'electric_price': electricPrice,
      'water_price': waterPrice,
      'service_price': servicePrice,
      'status': status.code,
      'amenities': amenities,
      'description': description,
      'image_urls': imageUrls,
      'max_occupants': maxOccupants,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json['updated_at'] = DateTime.now().toIso8601String();
    return json;
  }
}
