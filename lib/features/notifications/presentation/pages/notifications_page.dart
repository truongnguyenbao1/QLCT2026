// lib/features/notifications/presentation/pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/notification.dart';
import '../bloc/notification_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<NotificationBloc>()..add(const LoadNotificationsEvent()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo & Sự cố'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NotificationBloc>().add(const LoadNotificationsEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<NotificationBloc>().add(const LoadNotificationsEvent());
          } else if (state is NotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(child: Text('Không có thông báo nào.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = state.notifications[index];
                return _NotificationItem(notification: notif);
              },
            );
          }
          return const Center(child: Text('Đã xảy ra lỗi'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Mở popup tạo thông báo chung
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng tạo thông báo chung đang được cập nhật')));
        },
        child: const Icon(Icons.add_alert),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = notification.status == AppNotificationStatus.unread;
    
    IconData icon;
    Color iconColor;
    
    if (notification.type == AppNotificationType.issue) {
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.orange;
    } else if (notification.type == AppNotificationType.system) {
      icon = Icons.settings;
      iconColor = Colors.blue;
    } else {
      icon = Icons.campaign_rounded;
      iconColor = Colors.green;
    }

    return Card(
      elevation: isUnread ? 2 : 0,
      color: isUnread ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${notification.senderName ?? 'Khách thuê'} • ${notification.roomNumber ?? 'Hệ thống'}',
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(notification.content, style: theme.textTheme.bodyMedium),
          if (notification.imageUrl != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(notification.imageUrl!)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  notification.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Text('Không thể tải ảnh'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Gửi lúc: ${notification.sentAt.day}/${notification.sentAt.month}/${notification.sentAt.year}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const Spacer(),
              if (notification.type == AppNotificationType.issue && notification.status != AppNotificationStatus.resolved)
                FilledButton.tonal(
                  onPressed: () {
                    context.read<NotificationBloc>().add(ResolveIssueEvent(notification.id));
                  },
                  child: const Text('Đánh dấu đã giải quyết'),
                ),
              if (isUnread) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(MarkNotificationAsReadEvent(notification.id));
                    // Cập nhật giao diện tạm thời
                  },
                  child: const Text('Đã xem'),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
