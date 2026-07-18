// lib/features/tenant_management/data/models/tenant_model.dart
import '../../domain/entities/tenant.dart';

class TenantModel extends Tenant {
  const TenantModel({
    required super.id,
    required super.propertyId,
    super.roomId,
    required super.fullName,
    required super.phoneNumber,
    required super.cccdNumber,
    super.email,
    super.isActive,
    super.userId, // Thêm userId
    required super.createdAt,
    required super.updatedAt,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      roomId: json['room_id'] as String?,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      cccdNumber: json['cccd_number'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      userId: json['user_id'] as String?, // Thêm userId
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'room_id': roomId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'cccd_number': cccdNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'email': email,
      'is_active': isActive,
      'user_id': userId, // Thêm userId
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TenantModel.fromEntity(Tenant tenant) {
    return TenantModel(
      id: tenant.id,
      propertyId: tenant.propertyId,
      roomId: tenant.roomId,
      fullName: tenant.fullName,
      phoneNumber: tenant.phoneNumber,
      cccdNumber: tenant.cccdNumber,
      dateOfBirth: tenant.dateOfBirth,
      email: tenant.email,
      isActive: tenant.isActive,
      userId: tenant.userId, // Thêm userId
      createdAt: tenant.createdAt,
      updatedAt: tenant.updatedAt,
    );
  }
}
