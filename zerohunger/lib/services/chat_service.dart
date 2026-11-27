// chat_service.dart
// Pickup chats between a donor and a recipient who claimed a donation.
//
// Each claim (reservation) has its own pickup chat thread, keyed by reservationId
// (also called conversationId). A donor with multiple recipients claiming from the
// same donation gets one separate thread per recipient.
//
// TODO: Review when database & Messaging processor are complete. Replace the
//   in-memory store below with real cloud queries / Cloud Functions calls
//   (screens only talk to ChatService, so real backend wiring changes this file only).

import 'query_service.dart';
import 'zero_hunger_api.dart';

// Maximum message length specified for pickup chat.
const int maxChatMessageLength = 1000;

// The signed-in user's side of a pickup chat.
enum ChatRole {
  recipient, // current user claimed the food and is chatting with the donor
  donor,     // current user posted the food and is chatting with a recipient
}

// Who sent a single message in a pickup chat.
enum ChatSender {
  me,     // sent by the current user
  other,  // sent by the donor or recipient on the other side
  system, // automated message from the app, e.g. "Pickup chat opened"
}

// One message inside a pickup chat thread.
class ChatMessage {
  final String messageId;
  final String conversationId;
  final ChatSender sender;
  final String senderName; // e.g. "You", "Maya Patel", or "Zero Hunger"
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.sender,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });
}

// One pickup chat thread between a donor and one specific recipient for one donation.
class PickupChatThread {
  final String conversationId; // same as reservationId
  final String donationId;
  final String donationTitle;  // e.g. "Rice and stew"
  final String otherPartyName; // e.g. "Maya Patel" or "Alex Chen"
  final ChatRole myRole;
  final ReservationStatus status;
  final String? pickupCode;
  final DateTime? pickupStart;
  final DateTime? pickupEnd;
  final PickupAddress? address;
  final int unreadCount;
  final List<ChatMessage> messages;

  const PickupChatThread({
    required this.conversationId,
    required this.donationId,
    required this.donationTitle,
    required this.otherPartyName,
    required this.myRole,
    required this.status,
    this.pickupCode,
    this.pickupStart,
    this.pickupEnd,
    this.address,
    this.unreadCount = 0,
    this.messages = const [],
  });

  // Label describing who the other person in this chat is.
  String get otherPartyRoleLabel => myRole == ChatRole.recipient ? 'Donor' : 'Recipient';

  // The most recent message in the thread, if any.
  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  // Timestamp used to sort chats newest-first.
  DateTime get lastActivityAt =>
      messages.isNotEmpty ? messages.last.sentAt : (pickupStart ?? DateTime.fromMillisecondsSinceEpoch(0));

  bool get isUpcoming => status == ReservationStatus.active || status == ReservationStatus.rescheduled;

  PickupChatThread copyWith({
    String? donationTitle,
    String? otherPartyName,
    ReservationStatus? status,
    String? pickupCode,
    DateTime? pickupStart,
    DateTime? pickupEnd,
    PickupAddress? address,
    int? unreadCount,
    List<ChatMessage>? messages,
  }) {
    return PickupChatThread(
      conversationId: conversationId,
      donationId: donationId,
      donationTitle: donationTitle ?? this.donationTitle,
      otherPartyName: otherPartyName ?? this.otherPartyName,
      myRole: myRole,
      status: status ?? this.status,
      pickupCode: pickupCode ?? this.pickupCode,
      pickupStart: pickupStart ?? this.pickupStart,
      pickupEnd: pickupEnd ?? this.pickupEnd,
      address: address ?? this.address,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }
}

class ChatService {
  // Shared in-memory store for the running app so messages sent from Reservations
  // or Donations immediately show up in the Home chat list and vice versa.
  static final Map<String, PickupChatThread> _sharedStore = _seedThreads();
  static int _sharedCounter = 100;

  ChatService({List<PickupChatThread>? initialThreads, this.simulatedDelay = const Duration(milliseconds: 250)})
      : _store = initialThreads != null
            ? {for (final thread in initialThreads) thread.conversationId: thread}
            : _sharedStore;

  final Map<String, PickupChatThread> _store;
  final Duration simulatedDelay;

  // Lists all pickup chats the current user is part of, newest activity first.
  // Pass donationId to show only chats for one specific donation (e.g. from My donations).
  Future<List<PickupChatThread>> myChats({String? donationId}) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    final threads = _store.values
        .where((t) => donationId == null || t.donationId == donationId)
        .map((t) => t.copyWith(messages: List<ChatMessage>.unmodifiable(t.messages)))
        .toList();
    threads.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    return threads;
  }

  // Total unread count across all pickup chats (useful for badges).
  Future<int> totalUnreadCount() async {
    return _store.values.fold<int>(0, (sum, t) => sum + t.unreadCount);
  }

  // Loads a specific chat by conversationId (e.g. reservationId) and marks it read.
  // If this claim doesn't have a thread in the store yet, opens one with the
  // "Pickup chat opened" system message so any reservation or donation claim can chat right away.
  Future<PickupChatThread> openChat({
    required String conversationId,
    String? donationId,
    String? donationTitle,
    String? otherPartyName,
    ChatRole myRole = ChatRole.recipient,
    ReservationStatus status = ReservationStatus.active,
    String? pickupCode,
    DateTime? pickupStart,
    DateTime? pickupEnd,
    PickupAddress? address,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    final existing = _store[conversationId];
    if (existing != null) {
      final readThread = existing.copyWith(
        unreadCount: 0,
        donationTitle: donationTitle ?? existing.donationTitle,
        otherPartyName: otherPartyName ?? existing.otherPartyName,
        status: status,
        pickupCode: pickupCode ?? existing.pickupCode,
        pickupStart: pickupStart ?? existing.pickupStart,
        pickupEnd: pickupEnd ?? existing.pickupEnd,
        address: address ?? existing.address,
      );
      _store[conversationId] = readThread;
      return readThread.copyWith(messages: List<ChatMessage>.unmodifiable(readThread.messages));
    }

    final now = DateTime.now();
    final created = PickupChatThread(
      conversationId: conversationId,
      donationId: donationId ?? conversationId,
      donationTitle: donationTitle ?? 'Pickup chat',
      otherPartyName: otherPartyName ?? (myRole == ChatRole.recipient ? 'Donor' : 'Recipient'),
      myRole: myRole,
      status: status,
      pickupCode: pickupCode,
      pickupStart: pickupStart,
      pickupEnd: pickupEnd,
      address: address,
      unreadCount: 0,
      messages: [
        ChatMessage(
          messageId: 'sys-${++_sharedCounter}',
          conversationId: conversationId,
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: now,
        ),
      ],
    );
    _store[conversationId] = created;
    return created.copyWith(messages: List<ChatMessage>.unmodifiable(created.messages));
  }

  // Sends a message in the given pickup chat (trimmed, up to 1,000 characters).
  // TODO: Call api-sendPickupMessage when the Messaging processor is deployed.
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const ApiException('invalid-argument', 'Write a message before sending.');
    }
    if (trimmed.length > maxChatMessageLength) {
      throw const ApiException('invalid-argument', 'Messages can be up to 1,000 characters.');
    }

    final thread = _store[conversationId];
    if (thread == null) {
      throw const ApiException('not-found', 'This pickup chat could not be found.');
    }

    final message = ChatMessage(
      messageId: 'msg-${++_sharedCounter}',
      conversationId: conversationId,
      sender: ChatSender.me,
      senderName: 'You',
      text: trimmed,
      sentAt: DateTime.now(),
    );

    _store[conversationId] = thread.copyWith(
      unreadCount: 0,
      messages: [...thread.messages, message],
    );
    return message;
  }
}

// Sample pickup chats matching the sample reservations in query_service.dart
// plus sample donor-side chats with different recipients.
Map<String, PickupChatThread> _seedThreads() {
  final now = DateTime.now();
  DateTime ago(Duration d) => now.subtract(d);
  DateTime at(int days, int hour, [int minute = 0]) => DateTime(now.year, now.month, now.day + days, hour, minute);

  final list = <PickupChatThread>[
    // Matches sample-res-rice-and-stew in query_service.dart (Recipient view)
    PickupChatThread(
      conversationId: 'sample-res-rice-and-stew',
      donationId: 'sample-rice-and-stew',
      donationTitle: 'Rice and stew',
      otherPartyName: 'Maya Patel',
      myRole: ChatRole.recipient,
      status: ReservationStatus.active,
      pickupCode: '615318',
      pickupStart: DateTime(now.year, now.month, now.day, now.hour + 1),
      pickupEnd: DateTime(now.year, now.month, now.day, now.hour + 3),
      address: const PickupAddress(line1: '12 Sample Crescent NW', city: 'Calgary', province: 'AB', postalCode: 'T2N 1A1'),
      unreadCount: 1,
      messages: [
        ChatMessage(
          messageId: 'm-101',
          conversationId: 'sample-res-rice-and-stew',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: ago(const Duration(hours: 2, minutes: 10)),
        ),
        ChatMessage(
          messageId: 'm-102',
          conversationId: 'sample-res-rice-and-stew',
          sender: ChatSender.other,
          senderName: 'Maya Patel',
          text: 'Hi! The containers are packed and ready in the fridge. Ring bell #2 when you arrive.',
          sentAt: ago(const Duration(hours: 1, minutes: 45)),
        ),
        ChatMessage(
          messageId: 'm-103',
          conversationId: 'sample-res-rice-and-stew',
          sender: ChatSender.me,
          senderName: 'You',
          text: 'Thank you so much! I will head over right at the start of the pickup window.',
          sentAt: ago(const Duration(hours: 1, minutes: 20)),
        ),
        ChatMessage(
          messageId: 'm-104',
          conversationId: 'sample-res-rice-and-stew',
          sender: ChatSender.other,
          senderName: 'Maya Patel',
          text: 'Sounds great — bring a tote bag if you have one, there are 4 containers total.',
          sentAt: ago(const Duration(minutes: 18)),
        ),
      ],
    ),

    // Donor-side chat: Recipient #1 for donor's "Homemade lentil soup"
    PickupChatThread(
      conversationId: 'sample-donor-soup-alex',
      donationId: 'sample-donor-lentil-soup',
      donationTitle: 'Homemade lentil soup',
      otherPartyName: 'Alex Chen',
      myRole: ChatRole.donor,
      status: ReservationStatus.active,
      pickupCode: '738204',
      pickupStart: DateTime(now.year, now.month, now.day, now.hour + 2),
      pickupEnd: DateTime(now.year, now.month, now.day, now.hour + 4),
      address: const PickupAddress(line1: '2500 University Dr NW', city: 'Calgary', province: 'AB', postalCode: 'T2N 1N4'),
      unreadCount: 1,
      messages: [
        ChatMessage(
          messageId: 'm-201',
          conversationId: 'sample-donor-soup-alex',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: ago(const Duration(hours: 1, minutes: 5)),
        ),
        ChatMessage(
          messageId: 'm-202',
          conversationId: 'sample-donor-soup-alex',
          sender: ChatSender.other,
          senderName: 'Alex Chen',
          text: 'Hello! Is there visitor parking near the front entrance?',
          sentAt: ago(const Duration(minutes: 32)),
        ),
      ],
    ),

    // Donor-side chat: Recipient #2 for donor's "Homemade lentil soup" (different recipient!)
    PickupChatThread(
      conversationId: 'sample-donor-soup-priya',
      donationId: 'sample-donor-lentil-soup',
      donationTitle: 'Homemade lentil soup',
      otherPartyName: 'Priya Nair',
      myRole: ChatRole.donor,
      status: ReservationStatus.active,
      pickupCode: '849120',
      pickupStart: DateTime(now.year, now.month, now.day, now.hour + 2),
      pickupEnd: DateTime(now.year, now.month, now.day, now.hour + 4),
      address: const PickupAddress(line1: '2500 University Dr NW', city: 'Calgary', province: 'AB', postalCode: 'T2N 1N4'),
      unreadCount: 0,
      messages: [
        ChatMessage(
          messageId: 'm-251',
          conversationId: 'sample-donor-soup-priya',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: ago(const Duration(hours: 3)),
        ),
        ChatMessage(
          messageId: 'm-252',
          conversationId: 'sample-donor-soup-priya',
          sender: ChatSender.other,
          senderName: 'Priya Nair',
          text: 'Hi, I will be there around 15 minutes after pickup opens.',
          sentAt: ago(const Duration(hours: 2, minutes: 40)),
        ),
        ChatMessage(
          messageId: 'm-253',
          conversationId: 'sample-donor-soup-priya',
          sender: ChatSender.me,
          senderName: 'You',
          text: 'Perfect, see you then! Just message me when you reach the lobby.',
          sentAt: ago(const Duration(hours: 2, minutes: 30)),
        ),
      ],
    ),

    // Matches sample-res-biryani-and-raita in query_service.dart (Recipient view, Rescheduled)
    PickupChatThread(
      conversationId: 'sample-res-biryani-and-raita',
      donationId: 'sample-biryani-and-raita',
      donationTitle: 'Vegetable biryani and raita',
      otherPartyName: 'Omar Hassan',
      myRole: ChatRole.recipient,
      status: ReservationStatus.rescheduled,
      pickupCode: '482910',
      pickupStart: at(1, 12),
      pickupEnd: at(1, 14),
      address: const PickupAddress(line1: '56 Sample Road NW', city: 'Calgary', province: 'AB', postalCode: 'T3A 0A1'),
      unreadCount: 0,
      messages: [
        ChatMessage(
          messageId: 'm-301',
          conversationId: 'sample-res-biryani-and-raita',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: ago(const Duration(hours: 6)),
        ),
        ChatMessage(
          messageId: 'm-302',
          conversationId: 'sample-res-biryani-and-raita',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup time was rescheduled to Tomorrow, 12–2 pm',
          sentAt: ago(const Duration(hours: 4, minutes: 15)),
        ),
        ChatMessage(
          messageId: 'm-303',
          conversationId: 'sample-res-biryani-and-raita',
          sender: ChatSender.other,
          senderName: 'Omar Hassan',
          text: 'Sorry for moving it to tomorrow! Hope noon still works for you.',
          sentAt: ago(const Duration(hours: 4, minutes: 10)),
        ),
      ],
    ),

    // Matches sample-res-bagels-and-bread in query_service.dart (Picked up)
    PickupChatThread(
      conversationId: 'sample-res-bagels-and-bread',
      donationId: 'sample-bagels-and-bread',
      donationTitle: 'Fresh bagels and bread',
      otherPartyName: 'Sunside Bakery',
      myRole: ChatRole.recipient,
      status: ReservationStatus.pickedUp,
      pickupCode: '903421',
      pickupStart: at(-1, 17),
      pickupEnd: at(-1, 19),
      address: const PickupAddress(line1: '34 Sample Avenue SE', city: 'Calgary', province: 'AB', postalCode: 'T2G 0A1'),
      unreadCount: 0,
      messages: [
        ChatMessage(
          messageId: 'm-401',
          conversationId: 'sample-res-bagels-and-bread',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: ago(const Duration(days: 1, hours: 3)),
        ),
        ChatMessage(
          messageId: 'm-402',
          conversationId: 'sample-res-bagels-and-bread',
          sender: ChatSender.me,
          senderName: 'You',
          text: 'Outside now with code 903 421!',
          sentAt: ago(const Duration(days: 1, hours: 2)),
        ),
        ChatMessage(
          messageId: 'm-403',
          conversationId: 'sample-res-bagels-and-bread',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup completed',
          sentAt: ago(const Duration(days: 1, hours: 1, minutes: 55)),
        ),
      ],
    ),

    // Matches sample-res-pasta-sauce in query_service.dart (Cancelled)
    PickupChatThread(
      conversationId: 'sample-res-pasta-sauce',
      donationId: 'sample-pasta-sauce',
      donationTitle: 'Pasta and tomato sauce',
      otherPartyName: 'Liam Brooks',
      myRole: ChatRole.recipient,
      status: ReservationStatus.cancelled,
      pickupCode: '274815',
      pickupStart: at(-1, 14),
      pickupEnd: at(-1, 16),
      address: const PickupAddress(line1: '78 Sample Street SW', city: 'Calgary', province: 'AB', postalCode: 'T2S 1B2'),
      unreadCount: 0,
      messages: [
        ChatMessage(
          messageId: 'm-501',
          conversationId: 'sample-res-pasta-sauce',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: ago(const Duration(days: 1, hours: 8)),
        ),
        ChatMessage(
          messageId: 'm-502',
          conversationId: 'sample-res-pasta-sauce',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Donation cancelled: Donor ran out of containers before pickup.',
          sentAt: ago(const Duration(days: 1, hours: 6)),
        ),
      ],
    ),

    // Matches sample-res-sourdough-pastries in query_service.dart (Expired)
    PickupChatThread(
      conversationId: 'sample-res-sourdough-pastries',
      donationId: 'sample-sourdough-pastries',
      donationTitle: 'Sourdough and pastries',
      otherPartyName: 'Clara Morales',
      myRole: ChatRole.recipient,
      status: ReservationStatus.expired,
      pickupCode: '519034',
      pickupStart: at(-2, 10),
      pickupEnd: at(-2, 12),
      address: const PickupAddress(line1: '90 Sample Way NE', city: 'Calgary', province: 'AB', postalCode: 'T1Y 2C3'),
      unreadCount: 0,
      messages: [
        ChatMessage(
          messageId: 'm-601',
          conversationId: 'sample-res-sourdough-pastries',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: ago(const Duration(days: 2, hours: 5)),
        ),
        ChatMessage(
          messageId: 'm-602',
          conversationId: 'sample-res-sourdough-pastries',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup window expired',
          sentAt: ago(const Duration(days: 2, hours: 1)),
        ),
      ],
    ),
  ];

  return {for (final t in list) t.conversationId: t};
}
