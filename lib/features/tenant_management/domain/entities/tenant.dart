// lib/features/tenant_management/domain/entities/tenant.dart
import 'package:equatable/equatable.dart';

class Tenant extends Equatable {
  final String id;
  final String propertyId;
  final String roomId;
  final String fullName;
  final String phoneNumber;
  final String cccdNumber; // Encrypted
  final DateTime? dateOfBirth;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tenant({
    required this.id,
    required this.propertyId,
    required this.roomId,
    required this.fullName,
    required this.phoneNumber,
    required this.cccdNumber,
    this.dateOfBirth,
    this.email,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Tenant copyWith({
    String? fullName,
    String? phoneNumber,
    String? cccdNumber,
    String? email,
    bool? isActive,
  }) {
    return Tenant(
      id: id,
      propertyId: propertyId,
      roomId: roomId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      cccdNumber: cccdNumber ?? this.cccdNumber,
      dateOfBirth: dateOfBirth,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, fullName, roomId, isActive];
}
