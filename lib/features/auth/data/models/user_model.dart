// lib/features/auth/data/models/user_model.dart
import '../../domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phone,
    required super.role,
    super.propertyId,
    super.roomId,
    required super.hasAcceptedPrivacyPolicy,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['iduser'] as String,
      email: json['email'] as String,
      fullName: json['tenuser'] as String? ?? '',
      phone: json['sdt'] as String?,
      role: UserRoleExt.fromCode(json['quyenhan'] as String? ?? 'khách thuê'),
      propertyId: json['property_id'] as String?,
      roomId: json['room_id'] as String?,
      hasAcceptedPrivacyPolicy:
          json['has_accepted_privacy_policy'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['ngaytao'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iduser': id,
      'email': email,
      'tenuser': fullName,
      'sdt': phone,
      'quyenhan': role.code,
      'property_id': propertyId,
      'room_id': roomId,
      'has_accepted_privacy_policy': hasAcceptedPrivacyPolicy,
      'ngaytao': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role,
      propertyId: user.propertyId,
      roomId: user.roomId,
      hasAcceptedPrivacyPolicy: user.hasAcceptedPrivacyPolicy,
      createdAt: user.createdAt,
    );
  }
}
