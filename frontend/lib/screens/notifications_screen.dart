import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        // ignore: use_build_context_synchronously
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications());
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'success': return Icons.check_circle;
      case 'warning': return Icons.warning_amber;
      case 'error':   return Icons.error;
      default:        return Icons.info;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'success': return Colors.green;
      case 'warning': return Colors.orange;
      case 'error':   return Colors.red;
      default:        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final notifications = notifProvider.notifications;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          unreadCount > 0
              ? 'Notifications ($unreadCount non lues)'
              : 'Notifications',
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () => notifProvider.markAllAsRead(),
              icon: const Icon(Icons.done_all, color: Colors.white),
              label: const Text('Tout lire', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifProvider.fetchNotifications(),
          ),
        ],
      ),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(notifProvider.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => notifProvider.fetchNotifications(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Tsy misy notification', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => notifProvider.fetchNotifications(),
                      child: ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final n = notifications[i];
                          final color = _getColor(n.type);
                          return Container(
                            color: n.isRead
                                ? null
                                // ignore: deprecated_member_use
                                : color.withOpacity(0.05),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_getIcon(n.type), color: color, size: 22),
                              ),
                              title: Text(
                                n.titre,
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.message),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(n.createdAt),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: n.isRead
                                  ? const Icon(Icons.done_all, color: Colors.grey, size: 18)
                                  : IconButton(
                                      icon: const Icon(Icons.done_all, color: Colors.blue),
                                      tooltip: 'Marquer comme lu',
                                      onPressed: () => notifProvider.markAsRead(n.id),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}