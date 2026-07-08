// lib/features/tenant_management/presentation/pages/add_edit_tenant_page.dart
import 'package:flutter/material.dart';

class AddEditTenantPage extends StatelessWidget {
  final String? tenantId;
  final String? roomId;

  const AddEditTenantPage({super.key, this.tenantId, this.roomId});

  bool get isEditing => tenantId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa thông tin khách thuê' : 'Thêm khách thuê'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Tính năng đang phát triển',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Form thêm/sửa khách thuê sẽ được hoàn thiện sớm',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
