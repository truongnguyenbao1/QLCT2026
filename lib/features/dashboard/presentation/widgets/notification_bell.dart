import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class NotificationBell extends StatefulWidget {
  final String userId;
  const NotificationBell({super.key, required this.userId});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final Stream<List<Map<String, dynamic>>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = Supabase.instance.client
        .from('thongbao')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', widget.userId)
        .order('sent_at', ascending: false)
        .limit(10)
        .map((maps) => maps);
  }

  Future<void> _markAsRead(String id) async {
    try {
      await Supabase.instance.client
          .from('thongbao')
          .update({'status': 'READ'})
          .eq('id', id);
    } catch (_) {}
  }

  String _cleanNotificationContent(String content) {
    return content.replaceAll(RegExp(r'\s*\[invoice_id:[a-f0-9\-]+\]'), '');
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    if (notification['status'] == 'UNREAD') {
      _markAsRead(notification['id']);
    }
    
    final content = notification['content'] as String;
    
    // 1. Thử match theo định dạng ẩn mới [invoice_id:...]
    final match = RegExp(r'\[invoice_id:([a-f0-9\-]+)\]').firstMatch(content);
    if (match != null) {
      final invoiceId = match.group(1);
      context.push('/invoices/$invoiceId/payment');
      return;
    }
    
    // 2. Thử match theo định dạng text cũ "Mã hóa đơn: ..."
    final oldMatch = RegExp(r'Mã hóa đơn: ([a-f0-9\-]+)\.').firstMatch(content);
    if (oldMatch != null) {
      final invoiceId = oldMatch.group(1);
      context.push('/invoices/$invoiceId/payment');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => n['status'] == 'UNREAD').length;

        return PopupMenuButton<Map<String, dynamic>>(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount.toString()),
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: 'Thông báo',
          position: PopupMenuPosition.under,
          constraints: const BoxConstraints(
            maxWidth: 350,
            maxHeight: 500,
          ),
          itemBuilder: (context) {
            if (notifications.isEmpty) {
              return [
                const PopupMenuItem(
                  enabled: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Không có thông báo mới'),
                    ),
                  ),
                ),
              ];
            }
            return notifications.map((n) {
              final isUnread = n['status'] == 'UNREAD';
              return PopupMenuItem<Map<String, dynamic>>(
                value: n,
                padding: EdgeInsets.zero,
                child: Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: isUnread ? AppColors.primary.withValues(alpha: 0.05) : null,
                    border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n['title'] ?? '',
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cleanNotificationContent(n['content'] ?? ''),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.formatDateTime(DateTime.parse(n['sent_at'])),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
          onSelected: _handleNotificationTap,
        );
      },
    );
  }
}
