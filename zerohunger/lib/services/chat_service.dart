// chat_service.dart
// Pickup chats between a donor and a recipient who claimed a donation.
//
// Each claim (reservation) has its own pickup chat thread, keyed by reservationId
// (also called conversationId). A donor with multiple recipients claiming from the
// same donation gets one separate thread per recipient.
//
// The Cloud Function sends messages, but the schema cannot load chat history yet.

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
  static final Map<String, PickupChatThread> _sharedStore = {};
  static int _sharedCounter = 100;

  ChatService({
    List<PickupChatThread>? initialThreads,
    this.api,
    this.simulatedDelay = const Duration(milliseconds: 250),
  })
      : _store = initialThreads != null
            ? {for (final thread in initialThreads) thread.conversationId: thread}
            : _sharedStore,
        _useLocalData = initialThreads != null;

  final Map<String, PickupChatThread> _store;
  final ZeroHungerApi? api;
  final bool _useLocalData;
  final Duration simulatedDelay;

  // Lists all pickup chats the current user is part of, newest activity first.
  // Pass donationId to show only chats for one specific donation (e.g. from My donations).
  Future<List<PickupChatThread>> myChats({String? donationId}) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    if (!_useLocalData) return const [];
    final threads = _store.values
        .where((t) => donationId == null || t.donationId == donationId)
        .map((t) => t.copyWith(messages: List<ChatMessage>.unmodifiable(t.messages)))
        .toList();
    threads.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    return threads;
  }

  // Total unread count across all pickup chats (useful for badges).
  Future<int> totalUnreadCount() async {
    if (!_useLocalData) return 0;
    return _store.values.fold<int>(0, (sum, t) => sum + t.unreadCount);
  }

  // Loads a specific chat by conversationId (e.g. reservationId) and marks it read.
  // Creates an in-memory context for a chat opened directly from a successful claim.
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
      messages: const [],
    );
    _store[conversationId] = created;
    return created.copyWith(messages: List<ChatMessage>.unmodifiable(created.messages));
  }

  // Sends a message in the given pickup chat (trimmed, up to 1,000 characters).
  // Production sends through the callable API; injected test threads stay local.
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

    final messageId = _useLocalData
        ? 'msg-${++_sharedCounter}'
        : (await (api ?? ZeroHungerApi()).sendMessage(
            conversationId: conversationId,
            text: trimmed,
          ))
            .messageId;
    final message = ChatMessage(
      messageId: messageId,
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
