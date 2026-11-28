// notification_service.dart
// Notifications are unavailable until a processor writes targetable, readable alerts.

import 'package:flutter/foundation.dart';

// What tapping a notification opens.
enum NotificationTargetType {
  food,  // opens FoodDetailsScreen for a donation
  chat,  // opens PickupChatScreen for a reservation/conversation
  event, // opens Event details once the Events screen is built
}

// One alert row shown on the Notifications screen.
class AppNotification {
  final String notificationId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationTargetType targetType;
  final String targetId;     // donationId, conversationId, or eventId
  final String? targetTitle; // optional fallback title when opening the target

  const AppNotification({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      notificationId: notificationId,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      targetType: targetType,
      targetId: targetId,
      targetTitle: targetTitle,
    );
  }
}
class NotificationService {
  // Shared in-memory store for the running app so reading a notification immediately
  // updates the unread badge next to the user icon on every screen.
  static final List<AppNotification> _sharedStore = [];
  static final ValueNotifier<int> _sharedUnreadCount = ValueNotifier<int>(_countUnread(_sharedStore));

  NotificationService({
    List<AppNotification>? initialNotifications,
    this.simulatedDelay = const Duration(milliseconds: 250),
  })  : _store = initialNotifications != null ? List<AppNotification>.of(initialNotifications) : _sharedStore,
        _unreadNotifier = initialNotifications != null
            ? ValueNotifier<int>(_countUnread(initialNotifications))
            : _sharedUnreadCount;

  final List<AppNotification> _store;
  final ValueNotifier<int> _unreadNotifier;
  final Duration simulatedDelay;

  static int _countUnread(List<AppNotification> items) => items.where((n) => !n.isRead).length;

  int get unreadCount => _unreadNotifier.value;

  // Lets NotificationButton rebuild automatically whenever the unread count changes.
  ValueListenable<int> get unreadCountListenable => _unreadNotifier;

  // All notifications for the signed-in user, newest first.
  Future<List<AppNotification>> myNotifications() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    final sorted = List<AppNotification>.of(_store)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<AppNotification>.unmodifiable(sorted);
  }

  // Marks one notification as read and updates the unread badge.
  Future<AppNotification?> markAsRead(String notificationId) async {
    final index = _store.indexWhere((n) => n.notificationId == notificationId);
    if (index == -1) return null;

    final current = _store[index];
    if (!current.isRead) {
      final updated = current.copyWith(isRead: true);
      _store[index] = updated;
      _unreadNotifier.value = _countUnread(_store);
      return updated;
    }
    return current;
  }

  // Marks every notification as read and clears the unread badge.
  Future<void> markAllAsRead() async {
    var changed = false;
    for (var i = 0; i < _store.length; i++) {
      if (!_store[i].isRead) {
        _store[i] = _store[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      _unreadNotifier.value = 0;
    }
  }
}
