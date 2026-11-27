// notification_service.dart
// Keeps every alert in one place so a missed push notification is never lost.
//
// Each notification knows what it is about (food, chat, or event) and its targetId,
// so tapping a row opens that exact donation, pickup chat, or event.
//
// TODO: Review when database & Notification processor are complete. Replace the
//   in-memory store below with real cloud queries / Cloud Functions calls
//   (screens only ask this class, so real backend wiring changes this file only).

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
  static final List<AppNotification> _sharedStore = _seedNotifications();
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

// Sample notifications linked to the sample donations and pickup chats in the app.
List<AppNotification> _seedNotifications() {
  final now = DateTime.now();
  DateTime ago(Duration d) => now.subtract(d);

  return [
    AppNotification(
      notificationId: 'notif-1',
      title: 'New pickup message',
      message: 'Maya Patel: Sounds great — bring a tote bag if you have one, there are 4 containers total.',
      createdAt: ago(const Duration(minutes: 18)),
      isRead: false,
      targetType: NotificationTargetType.chat,
      targetId: 'sample-res-rice-and-stew',
      targetTitle: 'Rice and stew',
    ),
    AppNotification(
      notificationId: 'notif-2',
      title: 'New Halal & Vegan food near you',
      message: 'Rice and stew (10 portions) was posted in T2N, Calgary.',
      createdAt: ago(const Duration(minutes: 45)),
      isRead: false,
      targetType: NotificationTargetType.food,
      targetId: 'sample-rice-and-stew',
      targetTitle: 'Rice and stew',
    ),
    AppNotification(
      notificationId: 'notif-3',
      title: 'Pickup time rescheduled',
      message: 'Vegetable biryani and raita moved to Tomorrow, 12–2 pm.',
      createdAt: ago(const Duration(hours: 4, minutes: 15)),
      isRead: false,
      targetType: NotificationTargetType.chat,
      targetId: 'sample-res-biryani-and-raita',
      targetTitle: 'Vegetable biryani and raita',
    ),
    AppNotification(
      notificationId: 'notif-4',
      title: 'Upcoming food distribution',
      message: 'Saturday Community Food Pantry starts tomorrow at 10 am in NW Calgary.',
      createdAt: ago(const Duration(hours: 8)),
      isRead: true,
      targetType: NotificationTargetType.event,
      targetId: 'sample-event-community-pantry',
      targetTitle: 'Saturday Community Food Pantry',
    ),
    AppNotification(
      notificationId: 'notif-5',
      title: 'Fresh bagels and bread posted',
      message: 'Assorted bagels and sourdough loaves available in T2G, Calgary.',
      createdAt: ago(const Duration(days: 1, hours: 2)),
      isRead: true,
      targetType: NotificationTargetType.food,
      targetId: 'sample-bagels-and-bread',
      targetTitle: 'Fresh bagels and bread',
    ),
    AppNotification(
      notificationId: 'notif-6',
      title: 'New message from recipient',
      message: 'Alex Chen asked about visitor parking for Homemade lentil soup.',
      createdAt: ago(const Duration(days: 1, hours: 6)),
      isRead: true,
      targetType: NotificationTargetType.chat,
      targetId: 'sample-donor-soup-alex',
      targetTitle: 'Homemade lentil soup',
    ),
  ];
}
