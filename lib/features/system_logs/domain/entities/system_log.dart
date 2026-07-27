// lib/features/system_logs/domain/entities/system_log.dart

class SystemLog {
  final String id;
  final String? propertyId;
  final String? userId;
  final String action;
  final String tableName;
  final String recordId;
  final Map<String, dynamic>? newValue;
  final DateTime createdAt;

  SystemLog({
    required this.id,
    this.propertyId,
    this.userId,
    required this.action,
    required this.tableName,
    required this.recordId,
    this.newValue,
    required this.createdAt,
  });
}
