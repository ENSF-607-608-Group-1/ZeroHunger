// notification_service.dart
// Event-driven alert store combining live FCM push notifications with persisted
// Cloud SQL Notification rows (via Data Connect ListMyNotifications).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart' show DataConnectError;
import 'package:flutter/foundation.dart';

import '../generated/zerohunger.dart';

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
  // Shared in-memory store for the running app so incoming FCM pushes, Cloud SQL
  // rows, and read-state updates immediately update the unread badge on every screen.
  static final List<AppNotification> _sharedStore = [];
  static final Set<String> _readIds = <String>{};
  static final ValueNotifier<int> _sharedUnreadCount = ValueNotifier<int>(_countUnread(_sharedStore));

  NotificationService({
    List<AppNotification>? initialNotifications,
    this.simulatedDelay = const Duration(milliseconds: 250),
  })  : _store = initialNotifications != null ? List<AppNotification>.of(initialNotifications) : _sharedStore,
        _unreadNotifier = initialNotifications != null
            ? ValueNotifier<int>(_countUnread(initialNotifications))
            : _sharedUnreadCount,
        _isConnected = false,
        _connectorOverride = null;

  NotificationService.connected({
    ZerohungerConnector? connector,
    this.simulatedDelay = Duration.zero,
  })  : _store = _sharedStore,
        _unreadNotifier = _sharedUnreadCount,
        _isConnected = true,
        _connectorOverride = connector;

  final List<AppNotification> _store;
  final ValueNotifier<int> _unreadNotifier;
  final Duration simulatedDelay;
  final bool _isConnected;
  final ZerohungerConnector? _connectorOverride;

  bool get isConnected => _isConnected;

  static int _countUnread(List<AppNotification> items) => items.where((n) => !n.isRead).length;

  int get unreadCount => _unreadNotifier.value;

  // Lets NotificationButton and NotificationsScreen react when unread count changes.
  ValueListenable<int> get unreadCountListenable => _unreadNotifier;

  // Records a live event-driven push notification (from FCM) in the shared store.
  static void recordIncoming(AppNotification notification) {
    final normalized = _readIds.contains(notification.notificationId)
        ? notification.copyWith(isRead: true)
        : notification;

    final existingIndex = _sharedStore.indexWhere((n) => n.notificationId == normalized.notificationId);
    if (existingIndex >= 0) {
      _sharedStore[existingIndex] = normalized;
    } else {
      _sharedStore.insert(0, normalized);
    }

    // Remove any Cloud SQL duplicate for the same food title within 5 minutes so the
    // richer live FCM entry (with exact donationId) is shown once.
    if (!normalized.notificationId.startsWith('db-') &&
        normalized.targetType == NotificationTargetType.food &&
        normalized.targetTitle != null &&
        normalized.targetTitle!.trim().isNotEmpty) {
      final liveTitle = normalized.targetTitle!.trim().toLowerCase();
      _sharedStore.removeWhere(
        (existing) =>
            existing.notificationId.startsWith('db-') &&
            existing.targetType == NotificationTargetType.food &&
            existing.targetTitle?.trim().toLowerCase() == liveTitle &&
            existing.createdAt.difference(normalized.createdAt).abs().inMinutes <= 5,
      );
    }

    _sharedStore.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _sharedUnreadCount.value = _countUnread(_sharedStore);
  }

  // Clears session-scoped alerts when signing out or switching accounts.
  static void clearSession() {
    _sharedStore.clear();
    _readIds.clear();
    _sharedUnreadCount.value = 0;
  }

  // Refreshes the shared store & unread badge from Cloud SQL in the background.
  static Future<void> syncFromDatabase({ZerohungerConnector? connector}) async {
    try {
      await NotificationService.connected(connector: connector).myNotifications();
    } catch (e) {
      debugPrint('Notification sync skipped: $e');
    }
  }

  // Maps Cloud SQL Notification rows (from ListMyNotifications) into AppNotification models.
  static List<AppNotification> fromDatabaseRecords(
    List<ListMyNotificationsNotifications> records, {
    Set<String> readIds = const {},
  }) {
    return records.map((record) {
      final id = 'db-${record.notificationId}';
      final isEvent = record.eventId != null;
      final lowerTitle = record.title.toLowerCase();
      final isChat = !isEvent &&
          (lowerTitle.contains('message') || lowerTitle.contains('claimed'));
      final content = record.content.trim();
      final extractedTitle = content.contains(' • ')
          ? content.split(' • ').first.trim()
          : (content.isNotEmpty ? content : record.title);

      final NotificationTargetType targetType;
      if (isEvent) {
        targetType = NotificationTargetType.event;
      } else if (isChat) {
        targetType = NotificationTargetType.chat;
      } else {
        targetType = NotificationTargetType.food;
      }

      return AppNotification(
        notificationId: id,
        title: record.title,
        message: content,
        createdAt: record.createdAt.toDateTime(),
        isRead: readIds.contains(id),
        targetType: targetType,
        targetId: isEvent ? record.eventId.toString() : id,
        targetTitle: isEvent ? record.title : extractedTitle,
      );
    }).toList();
  }

  // Merges live FCM alerts with Cloud SQL records without showing duplicate cards
  // for the same donation.
  static List<AppNotification> mergeNotifications(
    List<AppNotification> liveItems,
    List<AppNotification> dbItems,
  ) {
    final merged = <AppNotification>[];
    final seenIds = <String>{};

    for (final item in liveItems) {
      if (seenIds.add(item.notificationId)) {
        merged.add(item);
      }
    }

    for (final dbItem in dbItems) {
      if (!seenIds.add(dbItem.notificationId)) continue;
      final dbTitle = dbItem.targetTitle?.trim().toLowerCase();
      final matchesLiveFood = dbItem.targetType == NotificationTargetType.food &&
          dbTitle != null &&
          dbTitle.isNotEmpty &&
          liveItems.any(
            (live) =>
                live.targetType == NotificationTargetType.food &&
                live.targetTitle?.trim().toLowerCase() == dbTitle &&
                live.createdAt.difference(dbItem.createdAt).abs().inMinutes <= 5,
          );
      if (!matchesLiveFood) {
        merged.add(dbItem);
      }
    }

    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  // All notifications for the signed-in user, newest first.
  Future<List<AppNotification>> myNotifications() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (_isConnected) {
      final dbItems = await _fetchDatabaseNotifications();
      final liveOnly = _sharedStore.where((n) => !n.notificationId.startsWith('db-')).toList();
      final merged = mergeNotifications(liveOnly, dbItems);
      _sharedStore
        ..clear()
        ..addAll(merged);
      _sharedUnreadCount.value = _countUnread(_sharedStore);
      return List<AppNotification>.unmodifiable(merged);
    }

    final sorted = List<AppNotification>.of(_store)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<AppNotification>.unmodifiable(sorted);
  }

  Future<List<AppNotification>> _fetchDatabaseNotifications() async {
    if (_connectorOverride == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        return const [];
      }
    }

    final activeConnector = _connectorOverride ?? ZerohungerConnector.instance;
    try {
      final result = await activeConnector.listMyNotifications().execute();
      return fromDatabaseRecords(result.data.notifications, readIds: _readIds);
    } on DataConnectError catch (e) {
      final msg = e.message ?? '';
      if (msg.contains('NOT_FOUND') || msg.contains('status code of 404')) {
        // Connector not yet deployed with ListMyNotifications; keep live FCM alerts working.
        return const [];
      }
      rethrow;
    }
  }

  // Marks one notification as read and updates the unread badge.
  Future<AppNotification?> markAsRead(String notificationId) async {
    if (_isConnected || identical(_store, _sharedStore)) {
      _readIds.add(notificationId);
    }
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
    final trackShared = _isConnected || identical(_store, _sharedStore);
    for (var i = 0; i < _store.length; i++) {
      if (trackShared) {
        _readIds.add(_store[i].notificationId);
      }
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
