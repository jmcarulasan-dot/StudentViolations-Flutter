import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/violation_provider.dart';

const _red  = Color(0xFFFD070C);
const _navy = Color(0xFF0F136E);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ViolationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: Consumer<ViolationProvider>(
        builder: (context, vp, _) {
          if (vp.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _navy));
          }

          final notifications = vp.notifications;

          return RefreshIndicator(
            onRefresh: () => vp.loadNotifications(),
            child: notifications.isEmpty
                ? _emptyState('No notifications')
                : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif.isRead;

                return ListTile(
                  onTap: () async {
                    if (!isRead) {
                      await Provider.of<ViolationProvider>(
                          context, listen: false)
                          .markNotificationAsRead(notif.id);
                    }
                  },
                  tileColor: isRead
                      ? Colors.grey[50]
                      : Colors.white,
                  leading: Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.grey.shade300 : _red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: isRead
                          ? Colors.black45
                          : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.message,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(notif.createdAt),
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : IconButton(
                    icon: const Icon(
                        Icons.check_circle_outline_rounded),
                    color: Colors.green,
                    onPressed: () async {
                      await Provider.of<ViolationProvider>(
                          context,
                          listen: false)
                          .markNotificationAsRead(notif.id);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<ViolationProvider>(
        builder: (context, vp, _) {
          if (vp.notifications.isEmpty ||
              vp.notifications.every((n) => n.isRead)) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => vp.markAllNotificationsAsRead(),
            backgroundColor: _navy,
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            label: const Text('Mark all read',
                style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}