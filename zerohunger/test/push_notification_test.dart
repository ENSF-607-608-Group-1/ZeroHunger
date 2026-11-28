import 'package:firebase_data_connect/firebase_data_connect.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';

import 'package:zerohunger/generated/zerohunger.dart';
import 'package:zerohunger/services/notification_service.dart';
import 'package:zerohunger/services/push_notification_service.dart';

void main() {
  setUp(() {
    NotificationService.clearSession();
    PushNotificationService.instance.clearOwnDonations();
  });

  tearDown(() {
    NotificationService.clearSession();
    PushNotificationService.instance.clearOwnDonations();
  });

  group('FCM topic and postal area helpers', () {
    test('fcmTopic sanitizes IDs to match NotificationProcessor', () {
      expect(fcmTopic('area', 'T3A'), 'area-T3A');
      expect(fcmTopic('user', 'uid/with space'), 'user-uid_with_space');
      expect(fcmTopic('donation', '47e8682f-77cb-4a24-8871-8cb7f69eaf6b'),
          'donation-47e8682f-77cb-4a24-8871-8cb7f69eaf6b');
    });

    test('areaCodeFromPostalCode extracts normalized Canadian FSA', () {
      expect(areaCodeFromPostalCode('t3a1l1'), 'T3A');
      expect(areaCodeFromPostalCode('T2N 1N4'), 'T2N');
      expect(areaCodeFromPostalCode('  t2g '), 'T2G');
      expect(areaCodeFromPostalCode('12345'), isNull);
      expect(areaCodeFromPostalCode(''), isNull);
      expect(areaCodeFromPostalCode(null), isNull);
    });
  });

  group('appNotificationFromFcmPayload', () {
    test('maps FOOD_AVAILABLE event to food notification with extracted title', () {
      final sent = DateTime.utc(2026, 4, 10, 18, 0);
      final item = appNotificationFromFcmPayload(
        title: 'New food near you',
        body: 'Fresh Rice and Curry, pick up 2:00 PM - 4:00 PM',
        data: const {
          'kind': 'FOOD_AVAILABLE',
          'donationId': '47e8682f-77cb-4a24-8871-8cb7f69eaf6b',
          'notificationId': 'notif-123',
        },
        sentTime: sent,
      );

      expect(item, isNotNull);
      expect(item!.notificationId, 'notif-123');
      expect(item.title, 'New food near you');
      expect(item.message, 'Fresh Rice and Curry, pick up 2:00 PM - 4:00 PM');
      expect(item.targetType, NotificationTargetType.food);
      expect(item.targetId, '47e8682f-77cb-4a24-8871-8cb7f69eaf6b');
      expect(item.targetTitle, 'Fresh Rice and Curry');
      expect(item.isRead, isFalse);
      expect(item.createdAt, sent);
    });

    test('maps NEW_MESSAGE event to chat notification', () {
      final item = appNotificationFromFcmPayload(
        title: 'New message',
        body: 'Alex: See you at 3pm',
        data: const {
          'kind': 'NEW_MESSAGE',
          'conversationId': 'conv-42',
          'notificationId': 'notif-chat-1',
        },
      );

      expect(item, isNotNull);
      expect(item!.targetType, NotificationTargetType.chat);
      expect(item.targetId, 'conv-42');
    });

    test('maps DISTRIBUTION_SCHEDULED event to event notification', () {
      final item = appNotificationFromFcmPayload(
        title: 'Upcoming food distribution',
        body: 'Weekend Pantry, starts Saturday',
        data: const {
          'kind': 'DISTRIBUTION_SCHEDULED',
          'distributionId': 'dist-7',
          'notificationId': 'notif-dist-7',
        },
      );

      expect(item, isNotNull);
      expect(item!.targetType, NotificationTargetType.event);
      expect(item.targetId, 'dist-7');
      expect(item.targetTitle, 'Weekend Pantry');
    });
  });

  group('Own-donation suppression', () {
    test('matches hyphenated and unhyphenated donation UUIDs', () {
      PushNotificationService.instance
          .markOwnDonation('47e8682f-77cb-4a24-8871-8cb7f69eaf6b');

      expect(
        PushNotificationService.instance
            .isOwnDonation('47e8682f-77cb-4a24-8871-8cb7f69eaf6b'),
        isTrue,
      );
      expect(
        PushNotificationService.instance
            .isOwnDonation('47e8682f77cb4a2488718cb7f69eaf6b'),
        isTrue,
      );
      expect(
        PushNotificationService.instance.isOwnDonation('other-donation-id'),
        isFalse,
      );
    });
  });

  group('NotificationService database mapping and merging', () {
    test('maps Cloud SQL Notification rows and tracks read IDs', () {
      final records = [
        ListMyNotificationsNotifications(
          notificationId: BigInt.from(10),
          title: 'New food near you',
          content: 'Warm Soup • Pickup at 5:00 PM (4 available)',
          createdAt: Timestamp(0, 1775840000),
        ),
        ListMyNotificationsNotifications(
          notificationId: BigInt.from(11),
          title: 'Community Food Fair',
          content: 'Saturday morning distribution at community hall',
          createdAt: Timestamp(0, 1775840500),
          eventId: BigInt.from(3),
        ),
      ];

      final mapped = NotificationService.fromDatabaseRecords(
        records,
        readIds: const {'db-10'},
      );

      expect(mapped, hasLength(2));
      expect(mapped[0].notificationId, 'db-10');
      expect(mapped[0].targetType, NotificationTargetType.food);
      expect(mapped[0].targetTitle, 'Warm Soup');
      expect(mapped[0].isRead, isTrue);

      expect(mapped[1].notificationId, 'db-11');
      expect(mapped[1].targetType, NotificationTargetType.event);
      expect(mapped[1].targetId, '3');
      expect(mapped[1].isRead, isFalse);
    });

    test('mergeNotifications deduplicates matching live FCM and Cloud SQL food alerts', () {
      final now = DateTime.utc(2026, 4, 10, 18, 0);
      final live = [
        AppNotification(
          notificationId: 'fcm-1',
          title: 'New food near you',
          message: 'Warm Soup, pick up 5:00 PM - 7:00 PM',
          createdAt: now,
          isRead: false,
          targetType: NotificationTargetType.food,
          targetId: 'don-uuid-1',
          targetTitle: 'Warm Soup',
        ),
      ];
      final db = [
        AppNotification(
          notificationId: 'db-10',
          title: 'New food near you',
          message: 'Warm Soup • Pickup at 5:00 PM (4 available)',
          createdAt: now.add(const Duration(seconds: 20)),
          isRead: false,
          targetType: NotificationTargetType.food,
          targetId: 'db-10',
          targetTitle: 'Warm Soup',
        ),
        AppNotification(
          notificationId: 'db-9',
          title: 'New food near you',
          message: 'Fresh Bread • Pickup at 3:00 PM (6 available)',
          createdAt: now.subtract(const Duration(hours: 1)),
          isRead: false,
          targetType: NotificationTargetType.food,
          targetId: 'db-9',
          targetTitle: 'Fresh Bread',
        ),
      ];

      final merged = NotificationService.mergeNotifications(live, db);
      expect(merged.map((n) => n.notificationId).toList(), ['fcm-1', 'db-9']);
    });

    test('recordIncoming updates shared unread count live', () {
      final service = NotificationService(simulatedDelay: Duration.zero);
      expect(service.unreadCount, 0);

      NotificationService.recordIncoming(
        AppNotification(
          notificationId: 'fcm-live-1',
          title: 'New food near you',
          message: 'Fresh Fruit, pick up 4:00 PM',
          createdAt: DateTime.utc(2026, 4, 10, 19, 0),
          isRead: false,
          targetType: NotificationTargetType.food,
          targetId: 'don-fruit',
          targetTitle: 'Fresh Fruit',
        ),
      );

      expect(service.unreadCount, 1);
    });
  });
}
