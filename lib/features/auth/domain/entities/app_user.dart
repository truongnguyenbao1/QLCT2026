// lib/features/auth/domain/entities/app_user.dart
import 'package:equatable/equatable.dart';

enum UserRole { owner, tenant }

extension UserRoleExt on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Chủ trọ';
      case UserRole.tenant:
        return 'Khách thuê';
    }
  }

  String get code {
    switch (this) {
      case UserRole.owner:
        return 'admin';
      case UserRole.tenant:
        return 'khách thuê';
    }
  }

  static UserRole fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'admin':
      case 'owner':
      case 'chủ trọ':
        return UserRole.owner;
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
  /// Trạng thái duyệt đăng ký của chủ trọ (từ nhatro.registration_status)
  /// Giá trị: 'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED' | null
  final String? registrationStatus;

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
    this.registrationStatus,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isTenant => role == UserRole.tenant;
  bool get canViewCccd => isOwner;
  bool get canDeleteData => isOwner;

  /// Chủ trọ đang chờ duyệt tài khoản
  bool get isPendingApproval =>
      isOwner && (registrationStatus == 'PENDING' || (registrationStatus == null && propertyId != null));

  /// Chủ trọ đã được duyệt
  bool get isApproved => !isOwner || registrationStatus == 'APPROVED';

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? propertyId,
    bool? hasAcceptedPrivacyPolicy,
    String? registrationStatus,
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
      registrationStatus: registrationStatus ?? this.registrationStatus,
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
        registrationStatus,
      ];
}
