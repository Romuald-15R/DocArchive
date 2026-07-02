import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('notifications');
      _notifications = (data as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Tsy afaka naka notifications: $e';
      _notifications = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.put('notifications/$id/read', {});
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          titre: _notifications[index].titre,
          message: _notifications[index].message,
          type: _notifications[index].type,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Tsy afaka namenoana ho namaky: $e';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      try {
        await _api.put('notifications/${n.id}/read', {});
      } catch (_) {}
    }
    _notifications = _notifications.map((n) => AppNotification(
      id: n.id,
      titre: n.titre,
      message: n.message,
      type: n.type,
      isRead: true,
      createdAt: n.createdAt,
    )).toList();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}