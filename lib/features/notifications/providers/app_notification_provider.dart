import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../repositories/app_notification_repository.dart';

class AppNotificationProvider extends ChangeNotifier {
  AppNotificationProvider({AppNotificationRepository? repository})
    : _repository = repository ?? AppNotificationRepository();

  final AppNotificationRepository _repository;
  StreamSubscription<List<AppNotification>>? _subscription;
  List<AppNotification> _notifications = const [];
  String? _userId;
  String? _errorMessage;
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void updateUser(String? userId) {
    if (_userId == userId) return;
    _subscription?.cancel();
    _subscription = null;
    _userId = userId;
    _notifications = const [];
    _errorMessage = null;
    _isLoading = userId != null;

    if (userId != null) {
      _subscription = _repository
          .watchNotifications(userId)
          .listen(
            (items) {
              _notifications = items;
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (Object error) {
              _isLoading = false;
              _errorMessage = 'Bildirimler yüklenemedi.';
              notifyListeners();
            },
          );
    }
    notifyListeners();
  }

  Future<void> markAsRead(AppNotification notification) async {
    final userId = _userId;
    if (userId == null || notification.isRead) return;
    await _repository.markAsRead(userId, notification.id);
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null || unreadCount == 0) return;
    await _repository.markAllAsRead(userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
