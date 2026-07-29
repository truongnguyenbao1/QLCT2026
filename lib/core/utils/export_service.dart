import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import '../../features/tenant_management/domain/entities/tenant.dart';

class ExportService {
  static Future<bool> exportTenantsToCsv(List<Tenant> tenants) async {
    try {
      final List<List<dynamic>> rows = [];
      
      // Header
      rows.add([
        'Họ và tên',
        'Số điện thoại',
        'CCCD/CMND',
        'Ngày sinh',
        'Email',
        'Trạng thái',
        'Ngày tạo'
      ]);

      // Data rows
      for (var tenant in tenants) {
        rows.add([
          tenant.fullName,
          tenant.phoneNumber,
          tenant.cccdNumber,
          tenant.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(tenant.dateOfBirth!) : '',
          tenant.email ?? '',
          tenant.isActive ? 'Đang thuê' : 'Đã rời đi',
          DateFormat('dd/MM/yyyy HH:mm').format(tenant.createdAt),
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      
      // Add BOM for Excel UTF-8 compatibility
      final bytes = [0xEF, 0xBB, 0xBF] + utf8.encode(csv);

      final fileName = 'Danh_sach_khach_thue_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      return true;
    } catch (e) {
      debugPrint('Export error: $e');
      return false;
    }
  }
}
