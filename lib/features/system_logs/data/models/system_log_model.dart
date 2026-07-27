// lib/features/system_logs/data/models/system_log_model.dart
import '../../domain/entities/system_log.dart';

class SystemLogModel extends SystemLog {
  SystemLogModel({
    required super.id,
    super.propertyId,
    super.userId,
    required super.action,
    required super.tableName,
    required super.recordId,
    super.newValue,
    required super.createdAt,
  });

  factory SystemLogModel.fromJson(Map<String, dynamic> json) {
    return SystemLogModel(
      id: json['id'],
      propertyId: json['property_id'],
      userId: json['user_id'],
      action: json['action'] ?? '',
      tableName: json['table_name'] ?? '',
      recordId: json['record_id'] ?? '',
      newValue: json['new_value'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (propertyId != null) 'property_id': propertyId,
      if (userId != null) 'user_id': userId,
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      if (newValue != null) 'new_value': newValue,
    };
  }
}
