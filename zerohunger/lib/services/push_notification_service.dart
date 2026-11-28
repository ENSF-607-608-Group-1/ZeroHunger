// push_notification_service.dart
// Event-driven push notifications powered by Firebase Cloud Messaging (FCM).
//
// Connects the Flutter app to NotificationProcessor (functions/src/processors/notification.ts):
//   PostFood -> Pub/Sub post-food -> ListingProcessor -> Pub/Sub food-available
//     -> NotificationProcessor -> FCM topic "area-<FSA>" (e.g. "area-T2N", "area-T3A")
//
// Also subscribes to:
//   - "user-<uid>"            for FOOD_CLAIMED, NEW_MESSAGE, DONATION_DUE
//   - "area-<postalFSA>"      for FOOD_AVAILABLE, DISTRIBUTION_SCHEDULED
//   - "org-<orgId>"           for DISTRIBUTION_SCHEDULED from followed organizations
//   - "donation-<donationId>" for QUANTITY_UPDATED, STATUS_CHANGED, CANCELLED, RESCHEDULED

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../theme/app_theme.dart';
import 'account_settings_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

const String defaultAreaCode = 'T2N';

// Matches topic(group, id) in functions/src/processors/notification.ts exactly.
String fcmTopic(String group, String id) =>
    '$group-${id.replaceAll(RegExp(r'[^A-Za-z0-9\-_.~%]'), '_')}';

// Extracts the 3-character Canadian FSA (e.g. "t3a 1l1" -> "T3A"), matching
// ListingProcessor's gridCell = postalCode.slice(0, 3).toUpperCase().
String? areaCodeFromPostalCode(String? postalCode) {
  if (postalCode == null) return null;
  final cleaned = postalCode.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  if (cleaned.length < 3) return null;
  final fsa = cleaned.substring(0, 3);
  if (!RegExp(r'^[A-Z]\d[A-Z]$').hasMatch(fsa)) return null;
  return fsa;
}

// Parses an incoming FCM payload (from NotificationProcessor) into an AppNotification.
AppNotification? appNotificationFromFcmPayload({
  String? title,
  String? body,
  required Map<String, dynamic> data,
  DateTime? sentTime,
  String? fallbackId,
}) {
  final kind = (data['kind'] ?? '').toString().trim().toUpperCase();
  final donationId = (data['donationId'] ?? '').toString().trim();
  final conversationId = (data['conversationId'] ?? '').toString().trim();
  final distributionId = (data['distributionId'] ?? '').toString().trim();
  final rawTitle = (title ?? data['title'] ?? '').toString().trim();
  final rawBody = (body ?? data['body'] ?? '').toString().trim();

  if (rawTitle.isEmpty &&
      rawBody.isEmpty &&
      kind.isEmpty &&
      donationId.isEmpty &&
      conversationId.isEmpty &&
      distributionId.isEmpty) {
    return null;
  }

  final NotificationTargetType targetType;
  final String targetId;
  final String defaultTitle;
  String? targetTitle;

  if (kind == 'NEW_MESSAGE' || conversationId.isNotEmpty) {
    targetType = NotificationTargetType.chat;
    targetId = conversationId.isNotEmpty ? conversationId : donationId;
    defaultTitle = 'New pickup message';
    targetTitle = rawTitle.isNotEmpty ? rawTitle : 'Pickup chat';
  } else if (kind == 'DISTRIBUTION_SCHEDULED' || distributionId.isNotEmpty) {
    targetType = NotificationTargetType.event;
    targetId = distributionId;
    defaultTitle = 'Upcoming food distribution';
    targetTitle = rawBody.contains(',') ? rawBody.split(',').first.trim() : rawTitle;
  } else {
    targetType = NotificationTargetType.food;
    targetId = donationId;
    defaultTitle = 'New food near you';
    if (rawBody.contains(', pick up ')) {
      targetTitle = rawBody.split(', pick up ').first.trim();
    } else if (rawTitle.isNotEmpty && rawTitle != 'New food near you') {
      targetTitle = rawTitle;
    }
  }

  final createdAt = sentTime ?? DateTime.now();
  final rawNotificationId = (data['notificationId'] ?? fallbackId ?? '').toString().trim();
  final notificationId = rawNotificationId.isNotEmpty
      ? rawNotificationId
      : 'fcm-${createdAt.microsecondsSinceEpoch}';

  return AppNotification(
    notificationId: notificationId,
    title: rawTitle.isNotEmpty ? rawTitle : defaultTitle,
    message: rawBody.isNotEmpty ? rawBody : defaultTitle,
    createdAt: createdAt,
    isRead: false,
    targetType: targetType,
    targetId: targetId,
    targetTitle: targetTitle,
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM received: ${message.messageId} data=${message.data}');
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  GlobalKey<NavigatorState>? _navigatorKey;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<User?>? _authSub;

  String? _lastSyncedUid;
  String? _activeUserTopic;
  final Set<String> _activeAreaTopics = <String>{};
  final Set<String> _activeOrgTopics = <String>{};
  final Set<String> _ownDonationIds = <String>{};

  static String _normalizeId(String id) => id.replaceAll('-', '').trim().toLowerCase();

  // Remember donations posted by this device so the donor does not get a self-alert
  // when their own PostFood event broadcasts to their area topic.
  void markOwnDonation(String donationId) {
    final normalized = _normalizeId(donationId);
    if (normalized.isNotEmpty) {
      _ownDonationIds.add(normalized);
    }
  }

  bool isOwnDonation(String? donationId) {
    if (donationId == null || donationId.trim().isEmpty) return false;
    return _ownDonationIds.contains(_normalizeId(donationId));
  }

  @visibleForTesting
  void clearOwnDonations() => _ownDonationIds.clear();

  Future<void> initialize({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    _messengerKey = messengerKey;
    _navigatorKey = navigatorKey;
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
    }

    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleOpenedMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('FCM getInitialMessage failed: $e');
    }

    final auth = AuthService();
    _authSub = auth.userChanges.listen((user) {
      unawaited(_syncForUser(user));
    });
    await _syncForUser(auth.currentUser);
  }

  Future<void> subscribeToDonation(String donationId) async {
    if (!_initialized || donationId.trim().isEmpty) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(fcmTopic('donation', donationId));
    } catch (e) {
      debugPrint('FCM subscribeToDonation failed: $e');
    }
  }

  Future<void> subscribeToAreaPostalCode(String postalCode) async {
    if (!_initialized) return;
    final area = areaCodeFromPostalCode(postalCode);
    if (area == null) return;
    final topic = fcmTopic('area', area);
    if (_activeAreaTopics.contains(topic)) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      _activeAreaTopics.add(topic);
    } catch (e) {
      debugPrint('FCM subscribeToAreaPostalCode failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final donationId = message.data['donationId']?.toString();
    final kind = (message.data['kind'] ?? '').toString().trim().toUpperCase();
    if (kind == 'FOOD_AVAILABLE' && isOwnDonation(donationId)) {
      debugPrint('Suppressed self FOOD_AVAILABLE push for donation $donationId');
      return;
    }

    final notification = appNotificationFromFcmPayload(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      sentTime: message.sentTime,
      fallbackId: message.messageId,
    );
    if (notification == null) return;

    NotificationService.recordIncoming(notification);
    _showForegroundBanner(notification);
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final donationId = message.data['donationId']?.toString();
    final kind = (message.data['kind'] ?? '').toString().trim().toUpperCase();
    if (kind == 'FOOD_AVAILABLE' && isOwnDonation(donationId)) {
      return;
    }

    final notification = appNotificationFromFcmPayload(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      sentTime: message.sentTime,
      fallbackId: message.messageId,
    );
    if (notification != null) {
      NotificationService.recordIncoming(notification);
    }
    _openNotificationsScreen();
  }

  void _showForegroundBanner(AppNotification notification) {
    final messenger = _messengerKey?.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ZhColors.primary,
          duration: const Duration(seconds: 5),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ZhColors.onPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ZhColors.onPrimary),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            textColor: ZhColors.onPrimary,
            onPressed: _openNotificationsScreen,
          ),
        ),
      );
  }

  void _openNotificationsScreen() {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _syncForUser(User? user) async {
    final uid = user?.uid;
    final uidChanged = _lastSyncedUid != uid;
    if (uidChanged) {
      _lastSyncedUid = uid;
      NotificationService.clearSession();
    }

    final messaging = FirebaseMessaging.instance;

    // 1. Update user-<uid> topic subscription.
    final nextUserTopic = uid != null ? fcmTopic('user', uid) : null;
    if (_activeUserTopic != null && _activeUserTopic != nextUserTopic) {
      try {
        await messaging.unsubscribeFromTopic(_activeUserTopic!);
      } catch (e) {
        debugPrint('FCM unsubscribe old user topic failed: $e');
      }
      _activeUserTopic = null;
    }
    if (nextUserTopic != null && _activeUserTopic != nextUserTopic) {
      try {
        await messaging.subscribeToTopic(nextUserTopic);
        _activeUserTopic = nextUserTopic;
      } catch (e) {
        debugPrint('FCM subscribe user topic failed: $e');
      }
    }

    // 2. Determine area & followed-organization topics from Cloud SQL profile.
    final desiredAreaTopics = <String>{};
    final desiredOrgTopics = <String>{};

    if (user != null && !user.isAnonymous) {
      try {
        final prefs = await AccountSettingsService.connected().load();
        final area = areaCodeFromPostalCode(prefs.postalCode) ?? defaultAreaCode;
        desiredAreaTopics.add(fcmTopic('area', area));
        for (final org in prefs.followedOrganizations) {
          if (org.organizationId.trim().isNotEmpty) {
            desiredOrgTopics.add(fcmTopic('org', org.organizationId));
          }
        }
      } catch (e) {
        debugPrint('Could not load user profile for FCM topics: $e');
        desiredAreaTopics.add(fcmTopic('area', defaultAreaCode));
      }
    } else {
      desiredAreaTopics.add(fcmTopic('area', defaultAreaCode));
    }

    await _reconcileTopics(messaging, _activeAreaTopics, desiredAreaTopics);
    await _reconcileTopics(messaging, _activeOrgTopics, desiredOrgTopics);

    // 3. Load any Cloud SQL Notification rows waiting for this signed-in user.
    if (user != null && !user.isAnonymous) {
      await NotificationService.syncFromDatabase();
    }
  }

  Future<void> _reconcileTopics(
    FirebaseMessaging messaging,
    Set<String> active,
    Set<String> desired,
  ) async {
    final toRemove = active.difference(desired).toList();
    for (final topic in toRemove) {
      try {
        await messaging.unsubscribeFromTopic(topic);
        active.remove(topic);
      } catch (e) {
        debugPrint('FCM unsubscribe $topic failed: $e');
      }
    }

    final toAdd = desired.difference(active).toList();
    for (final topic in toAdd) {
      try {
        await messaging.subscribeToTopic(topic);
        active.add(topic);
      } catch (e) {
        debugPrint('FCM subscribe $topic failed: $e');
      }
    }
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _authSub?.cancel();
    _initialized = false;
  }
}
