// lib/features/auth/domain/entities/app_user.dart
import 'package:equatable/equatable.dart';

enum UserRole { owner, staff, tenant }

extension UserRoleExt on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Chủ trọ';
      case UserRole.staff:
        return 'Nhân viên';
      case UserRole.tenant:
        return 'Khách thuê';
    }
  }

  String get code {
    switch (this) {
      case UserRole.owner:
        return 'Chủ trọ';
      case UserRole.staff:
        return 'Nhân viên';
      case UserRole.tenant:
        return 'Khách thuê';
    }
  }

  static UserRole fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'admin':
      case 'owner':
      case 'chủ trọ':
        return UserRole.owner;
      case 'staff':
      case 'nhân viên':
      case 'quản lý':
        return UserRole.staff;
      case 'khách thuê':
      case 'tenant':
        return UserRole.tenant;
      default:
        return UserRole.tenant;
    }
  }
}

class AppUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final UserRole role;
  final String? propertyId; // property chủ trọ đang quản lý
  final String? roomId;     // phòng khách đang thuê
  final bool hasAcceptedPrivacyPolicy;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.propertyId,
    this.roomId,
    required this.hasAcceptedPrivacyPolicy,
    required this.createdAt,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isStaff => role == UserRole.staff;
  bool get isTenant => role == UserRole.tenant;
  bool get canManageRooms => isOwner || isStaff;
  bool get canViewCccd => isOwner;
  bool get canDeleteData => isOwner;

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? propertyId,
    bool? hasAcceptedPrivacyPolicy,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role,
      propertyId: propertyId ?? this.propertyId,
      roomId: roomId,
      hasAcceptedPrivacyPolicy:
          hasAcceptedPrivacyPolicy ?? this.hasAcceptedPrivacyPolicy,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        role,
        propertyId,
        roomId,
        hasAcceptedPrivacyPolicy,
      ];
}
