import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => n['status'] == 'UNREAD').length;

        return IconButton(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount.toString()),
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: 'Thông báo',
          onPressed: () {
            context.push('/notifications');
          },
        );
      },
    );
  }
}
