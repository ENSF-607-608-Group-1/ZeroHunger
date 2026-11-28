// chat_service.dart
// Event-driven pickup chats between a donor and a recipient who claimed a donation.
//
// Follows the MessagingProcessor architecture:
//   Claim food -> api-claimFood -> ClaimProcessor (unique reservationId + pickupCode)
//     -> Pub/Sub food-claimed -> MessagingProcessor.onFoodClaimed -> MessageSent
//     + Cloud SQL Conversations / UserConversation / Messages persistence
//   Send message -> api-sendMessage -> Pub/Sub send-message
//     -> MessagingProcessor.onSendMessage -> MessageSent -> NotificationProcessor (FCM)
//     + Cloud SQL Messages / Notification persistence

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart' show DataConnectError;
import 'package:flutter/foundation.dart';

import '../generated/zerohunger.dart';
import 'query_service.dart';
import 'zero_hunger_api.dart';

// Maximum message length specified for pickup chat.
const int maxChatMessageLength = 1000;

const String _pickupMetaPrefix = '[PICKUP_META]';

// Formats a 6-digit pickup code as "615 318" for easy reading.
String formatPickupCode(String code) {
  final cleaned = code.trim();
  if (cleaned.length == 6) {
    return '${cleaned.substring(0, 3)} ${cleaned.substring(3)}';
  }
  return cleaned;
}

// Structured metadata stored in the opening system message of a Cloud SQL PICKUP conversation
// so donor and recipient both see the unique reservationId, pickupCode, and donation context
// without altering the deployed database schema.
class PickupChatMeta {
  final String reservationId;
  final String donationId;
  final String donationTitle;
  final String? pickupCode;
  final DateTime? pickupStart;
  final DateTime? pickupEnd;
  final String? donorAuthUid;
  final String? recipientAuthUid;

  const PickupChatMeta({
    required this.reservationId,
    required this.donationId,
    required this.donationTitle,
    this.pickupCode,
    this.pickupStart,
    this.pickupEnd,
    this.donorAuthUid,
    this.recipientAuthUid,
  });

  Map<String, dynamic> toJson() => {
        'reservationId': reservationId,
        'donationId': donationId,
        'donationTitle': donationTitle,
        if (pickupCode != null && pickupCode!.isNotEmpty) 'pickupCode': pickupCode,
        if (pickupStart != null) 'pickupStart': pickupStart!.toUtc().toIso8601String(),
        if (pickupEnd != null) 'pickupEnd': pickupEnd!.toUtc().toIso8601String(),
        if (donorAuthUid != null && donorAuthUid!.isNotEmpty) 'donorAuthUid': donorAuthUid,
        if (recipientAuthUid != null && recipientAuthUid!.isNotEmpty)
          'recipientAuthUid': recipientAuthUid,
      };

  factory PickupChatMeta.fromJson(Map<String, dynamic> json) => PickupChatMeta(
        reservationId: (json['reservationId'] ?? '').toString(),
        donationId: (json['donationId'] ?? '').toString(),
        donationTitle: (json['donationTitle'] ?? 'Pickup chat').toString(),
        pickupCode: json['pickupCode']?.toString(),
        pickupStart: json['pickupStart'] != null
            ? DateTime.tryParse(json['pickupStart'].toString())
            : null,
        pickupEnd: json['pickupEnd'] != null
            ? DateTime.tryParse(json['pickupEnd'].toString())
            : null,
        donorAuthUid: json['donorAuthUid']?.toString(),
        recipientAuthUid: json['recipientAuthUid']?.toString(),
      );
}

// Encodes the opening system message stored in Cloud SQL Messages.content.
String encodePickupMetaMessage(PickupChatMeta meta, {String? systemText}) {
  final code = meta.pickupCode;
  final defaultText = (code != null && code.isNotEmpty)
      ? 'Pickup chat opened for ${meta.donationTitle}. Pickup code: ${formatPickupCode(code)}. Show this code to the donor at pickup.'
      : 'Pickup chat opened for ${meta.donationTitle}. Use it to arrange the pickup.';
  final body = (systemText != null && systemText.trim().isNotEmpty)
      ? systemText.trim()
      : defaultText;
  return '$_pickupMetaPrefix${jsonEncode(meta.toJson())}\n$body';
}

// Decodes an opening system message; returns null if the message is a normal chat message.
({PickupChatMeta meta, String displayText})? parsePickupMetaMessage(String content) {
  if (!content.startsWith(_pickupMetaPrefix)) return null;
  final newlineIndex = content.indexOf('\n');
  final jsonPart = (newlineIndex == -1
          ? content.substring(_pickupMetaPrefix.length)
          : content.substring(_pickupMetaPrefix.length, newlineIndex))
      .trim();
  final body = newlineIndex == -1 ? '' : content.substring(newlineIndex + 1).trim();
  try {
    final decoded = jsonDecode(jsonPart);
    if (decoded is! Map<String, dynamic>) return null;
    final meta = PickupChatMeta.fromJson(decoded);
    final displayText = body.isNotEmpty
        ? body
        : 'Pickup chat opened. Use it to arrange the pickup.';
    return (meta: meta, displayText: displayText);
  } catch (_) {
    return null;
  }
}

class DonationDonorInfo {
  final BigInt userId;
  final String authUid;
  final String displayName;

  const DonationDonorInfo({
    required this.userId,
    required this.authUid,
    required this.displayName,
  });
}

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
  final String senderName; // e.g. "You", "Alex Taylor", or "Zero Hunger"
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
  final String conversationId; // unique reservationId (UUID) matching MessagingProcessor
  final String donationId;
  final String donationTitle;  // e.g. "Rice and stew"
  final String otherPartyName; // e.g. "Alex Taylor"
  final ChatRole myRole;
  final ReservationStatus status;
  final String? pickupCode;
  final DateTime? pickupStart;
  final DateTime? pickupEnd;
  final PickupAddress? address;
  final int unreadCount;
  final List<ChatMessage> messages;
  final BigInt? dbConversationId;   // Cloud SQL Conversations.ConversationID
  final String? otherPartyAuthUid;  // Firebase Auth UID for FCM push routing
  final BigInt? otherPartyUserId;   // Cloud SQL Users.UserID for Notification persistence

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
    this.dbConversationId,
    this.otherPartyAuthUid,
    this.otherPartyUserId,
  });

  // Label describing who the other person in this chat is.
  String get otherPartyRoleLabel => myRole == ChatRole.recipient ? 'Donor' : 'Recipient';

  // Short readable version of the unique reservation ID for display at the top of the chat.
  String get shortReservationId {
    final cleaned = conversationId.replaceAll('-', '').trim();
    if (cleaned.length >= 8) {
      return cleaned.substring(0, 8).toUpperCase();
    }
    return conversationId.toUpperCase();
  }

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
    BigInt? dbConversationId,
    String? otherPartyAuthUid,
    BigInt? otherPartyUserId,
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
      dbConversationId: dbConversationId ?? this.dbConversationId,
      otherPartyAuthUid: otherPartyAuthUid ?? this.otherPartyAuthUid,
      otherPartyUserId: otherPartyUserId ?? this.otherPartyUserId,
    );
  }
}

class ChatService {
  static final Map<String, PickupChatThread> _sharedStore = {};
  static int _sharedCounter = 100;
  static final ValueNotifier<int> _updatesNotifier = ValueNotifier<int>(0);

  // Lets open chat screens auto-refresh when an incoming FCM message arrives.
  static ValueListenable<int> get updatesListenable => _updatesNotifier;

  static void notifyIncomingUpdate() {
    _updatesNotifier.value++;
  }

  static void clearSession() {
    _sharedStore.clear();
    _updatesNotifier.value++;
  }

  ChatService({
    List<PickupChatThread>? initialThreads,
    this.api,
    this.simulatedDelay = const Duration(milliseconds: 250),
  })  : _store = initialThreads != null
            ? {for (final thread in initialThreads) thread.conversationId: thread}
            : _sharedStore,
        _useLocalData = initialThreads != null,
        _isConnected = false,
        _connectorOverride = null;

  ChatService.connected({
    ZerohungerConnector? connector,
    this.api,
    this.simulatedDelay = Duration.zero,
  })  : _store = _sharedStore,
        _useLocalData = false,
        _isConnected = true,
        _connectorOverride = connector;

  final Map<String, PickupChatThread> _store;
  final ZeroHungerApi? api;
  final bool _useLocalData;
  final bool _isConnected;
  final ZerohungerConnector? _connectorOverride;
  final Duration simulatedDelay;

  bool get isConnected => _isConnected;

  // Resolves the donor who posted a donation (from Cloud SQL UserActivity 'FOOD_POSTED').
  Future<DonationDonorInfo?> resolveDonationDonor(String donationId) async {
    final activeConnector = _connectorOverride ?? ZerohungerConnector.instance;
    try {
      final result = await activeConnector
          .getDonationDonor(donationId: donationId)
          .execute();
      if (result.data.userActivities.isEmpty) return null;
      final donor = result.data.userActivities.first.user;
      return DonationDonorInfo(
        userId: donor.userId,
        authUid: donor.authUid,
        displayName: donor.displayName.isNotEmpty ? donor.displayName : 'Donor',
      );
    } on DataConnectError catch (e) {
      if (_isOperationMissing(e)) return null;
      debugPrint('Could not look up donation donor: $e');
      return null;
    } catch (e) {
      debugPrint('Could not look up donation donor: $e');
      return null;
    }
  }

  // Creates the pickup chat immediately after api-claimFood succeeds (matching MessagingProcessor.onFoodClaimed)
  // and persists Conversations + UserConversation + opening Messages + UserActivity + Notification in Cloud SQL.
  Future<PickupChatThread> createPickupChatForClaim({
    required ClaimResult claim,
    required Donation donation,
    DonationDonorInfo? donor,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid;

    final meta = PickupChatMeta(
      reservationId: claim.reservationId,
      donationId: claim.donationId,
      donationTitle: donation.title,
      pickupCode: claim.pickupCode,
      pickupStart: claim.pickupStart,
      pickupEnd: claim.pickupEnd,
      donorAuthUid: donor?.authUid,
      recipientAuthUid: currentUid,
    );
    final encodedOpening = encodePickupMetaMessage(meta);
    final parsedOpening = parsePickupMetaMessage(encodedOpening)!;

    BigInt? dbConversationId;
    if (_isConnected && currentUser != null && !currentUser.isAnonymous) {
      dbConversationId = await _persistPickupConversation(
        meta: meta,
        encodedOpening: encodedOpening,
        donor: donor,
      );
    }

    final openingMessage = ChatMessage(
      messageId: 'sys-${claim.reservationId}',
      conversationId: claim.reservationId,
      sender: ChatSender.system,
      senderName: 'Zero Hunger',
      text: parsedOpening.displayText,
      sentAt: DateTime.now(),
    );

    final thread = PickupChatThread(
      conversationId: claim.reservationId,
      donationId: claim.donationId,
      donationTitle: donation.title,
      otherPartyName: donor?.displayName ?? 'Donor',
      myRole: ChatRole.recipient,
      status: ReservationStatus.active,
      pickupCode: claim.pickupCode,
      pickupStart: claim.pickupStart,
      pickupEnd: claim.pickupEnd,
      address: donation.address,
      unreadCount: 0,
      messages: [openingMessage],
      dbConversationId: dbConversationId,
      otherPartyAuthUid: donor?.authUid,
      otherPartyUserId: donor?.userId,
    );

    _store[thread.conversationId] = thread;
    notifyIncomingUpdate();
    return thread;
  }

  Future<BigInt?> _persistPickupConversation({
    required PickupChatMeta meta,
    required String encodedOpening,
    DonationDonorInfo? donor,
  }) async {
    final activeConnector = _connectorOverride ?? ZerohungerConnector.instance;
    try {
      final meResult = await activeConnector.getCurrentUser().execute();
      if (meResult.data.users.isEmpty) return null;
      final myUserId = meResult.data.users.first.userId;

      final convResult = await activeConnector
          .createConversation(conversationType: 'PICKUP')
          .execute();
      final dbConvId = convResult.data.conversations_insert.conversationId;

      await activeConnector
          .addConversationMember(userId: myUserId, conversationId: dbConvId)
          .execute();

      if (donor != null && donor.userId != myUserId) {
        await activeConnector
            .addConversationMember(userId: donor.userId, conversationId: dbConvId)
            .execute();
      }

      await activeConnector
          .sendChatMessage(
            senderId: myUserId,
            conversationId: dbConvId,
            content: encodedOpening,
          )
          .execute();

      try {
        await activeConnector
            .recordClaimActivity(userId: myUserId, donationId: meta.donationId)
            .execute();
      } catch (e) {
        debugPrint('RecordClaimActivity skipped: $e');
      }

      if (donor != null && donor.userId != myUserId) {
        final codeDisplay = meta.pickupCode != null
            ? ' • Pickup code: ${formatPickupCode(meta.pickupCode!)}'
            : '';
        try {
          await activeConnector
              .createNotificationForUser(
                userId: donor.userId,
                title: 'Your food was claimed',
                content:
                    'Someone claimed ${meta.donationTitle}$codeDisplay. Open pickup chat to coordinate.',
              )
              .execute();
        } catch (e) {
          debugPrint('Donor claim notification skipped: $e');
        }
      }

      return dbConvId;
    } on DataConnectError catch (e) {
      if (_isOperationMissing(e)) return null;
      debugPrint('Could not persist pickup conversation: $e');
      return null;
    } catch (e) {
      debugPrint('Could not persist pickup conversation: $e');
      return null;
    }
  }

  // Maps Cloud SQL ListMyConversations records into PickupChatThread models.
  static List<PickupChatThread> fromDatabaseConversations(
    List<ListMyConversationsUserConversation> records, {
    required String currentAuthUid,
  }) {
    final threads = <PickupChatThread>[];
    final seenDbIds = <BigInt>{};

    for (final entry in records) {
      final conv = entry.conversation;
      if (!seenDbIds.add(conv.conversationId)) continue;

      PickupChatMeta? meta;
      final mappedMessages = <ChatMessage>[];

      for (final rawMsg in conv.messages) {
        final parsed = parsePickupMetaMessage(rawMsg.content);
        if (parsed != null) {
          meta ??= parsed.meta;
          mappedMessages.add(
            ChatMessage(
              messageId: 'db-${rawMsg.messageId}',
              conversationId: meta.reservationId.isNotEmpty
                  ? meta.reservationId
                  : conv.conversationId.toString(),
              sender: ChatSender.system,
              senderName: 'Zero Hunger',
              text: parsed.displayText,
              sentAt: rawMsg.sentAt.toDateTime(),
            ),
          );
          continue;
        }

        final isMe = rawMsg.sender.authUid == currentAuthUid;
        final senderName = isMe
            ? 'You'
            : (rawMsg.sender.displayName.isNotEmpty ? rawMsg.sender.displayName : 'User');
        mappedMessages.add(
          ChatMessage(
            messageId: 'db-${rawMsg.messageId}',
            conversationId: meta != null && meta.reservationId.isNotEmpty
                ? meta.reservationId
                : conv.conversationId.toString(),
            sender: isMe ? ChatSender.me : ChatSender.other,
            senderName: senderName,
            text: rawMsg.content,
            sentAt: rawMsg.sentAt.toDateTime(),
          ),
        );
      }

      ListMyConversationsUser? otherUser;
      for (final member in conv.members) {
        if (member.user.authUid != currentAuthUid) {
          otherUser = member.user;
          break;
        }
      }

      final myRole = (meta?.donorAuthUid != null && meta!.donorAuthUid == currentAuthUid)
          ? ChatRole.donor
          : ChatRole.recipient;

      final otherName = (otherUser != null && otherUser.displayName.isNotEmpty)
          ? otherUser.displayName
          : (myRole == ChatRole.recipient ? 'Donor' : 'Recipient');

      final conversationKey = (meta != null && meta.reservationId.isNotEmpty)
          ? meta.reservationId
          : conv.conversationId.toString();

      threads.add(
        PickupChatThread(
          conversationId: conversationKey,
          donationId: meta?.donationId ?? conversationKey,
          donationTitle: meta?.donationTitle ?? 'Pickup chat',
          otherPartyName: otherName,
          myRole: myRole,
          status: ReservationStatus.active,
          pickupCode: meta?.pickupCode,
          pickupStart: meta?.pickupStart,
          pickupEnd: meta?.pickupEnd,
          unreadCount: 0,
          messages: mappedMessages,
          dbConversationId: conv.conversationId,
          otherPartyAuthUid: otherUser?.authUid ??
              (myRole == ChatRole.recipient ? meta?.donorAuthUid : meta?.recipientAuthUid),
          otherPartyUserId: otherUser?.userId,
        ),
      );
    }

    threads.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    return threads;
  }

  // Lists all pickup chats the current user is part of, newest activity first.
  // Pass donationId to show only chats for one specific donation (e.g. from My donations).
  Future<List<PickupChatThread>> myChats({String? donationId}) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    if (!_useLocalData && !_isConnected) return const [];

    if (_isConnected) {
      await _syncFromDatabase();
    }

    final threads = _store.values
        .where((t) => donationId == null || uuidsMatch(t.donationId, donationId))
        .map((t) => t.copyWith(messages: List<ChatMessage>.unmodifiable(t.messages)))
        .toList();
    threads.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    return threads;
  }

  Future<void> _syncFromDatabase() async {
    final user = _connectorOverride == null ? FirebaseAuth.instance.currentUser : null;
    if (_connectorOverride == null && (user == null || user.isAnonymous)) {
      return;
    }
    final activeConnector = _connectorOverride ?? ZerohungerConnector.instance;
    try {
      final result = await activeConnector.listMyConversations().execute();
      final dbThreads = fromDatabaseConversations(
        result.data.userConversations,
        currentAuthUid: user?.uid ?? '',
      );
      for (final dbThread in dbThreads) {
        final existing = _store[dbThread.conversationId];
        _store[dbThread.conversationId] = dbThread.copyWith(
          address: existing?.address ?? dbThread.address,
        );
      }
    } on DataConnectError catch (e) {
      if (_isOperationMissing(e)) return;
      rethrow;
    }
  }

  // Total unread count across all pickup chats (useful for badges).
  Future<int> totalUnreadCount() async {
    if (!_useLocalData && !_isConnected) return 0;
    return _store.values.fold<int>(0, (sum, t) => sum + t.unreadCount);
  }

  // Loads a specific chat by conversationId (reservationId) and marks it read.
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

    if (_isConnected) {
      try {
        await _syncFromDatabase();
      } catch (e) {
        debugPrint('Chat refresh failed, falling back to cached thread: $e');
      }
    }

    PickupChatThread? existing = _store[conversationId];
    if (existing == null) {
      for (final candidate in _store.values) {
        if (uuidsMatch(candidate.conversationId, conversationId) ||
            candidate.dbConversationId?.toString() == conversationId) {
          existing = candidate;
          break;
        }
      }
    }

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
      _store[existing.conversationId] = readThread;
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
  // Routes through api-sendMessage -> MessagingProcessor -> NotificationProcessor (FCM)
  // and persists to Cloud SQL Messages + Notification when signed in.
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

    PickupChatThread? thread = _store[conversationId];
    if (thread == null) {
      for (final candidate in _store.values) {
        if (uuidsMatch(candidate.conversationId, conversationId)) {
          thread = candidate;
          break;
        }
      }
    }
    if (thread == null) {
      throw const ApiException('not-found', 'This pickup chat could not be found.');
    }

    final String messageId;
    if (_useLocalData) {
      messageId = 'msg-${++_sharedCounter}';
    } else {
      final submitted = await (api ?? ZeroHungerApi()).sendMessage(
        conversationId: thread.conversationId,
        text: trimmed,
        donationId: thread.donationId,
        receiverId: thread.otherPartyAuthUid,
      );
      messageId = submitted.messageId;

      if (_isConnected && thread.dbConversationId != null) {
        await _persistChatMessage(thread: thread, text: trimmed);
      }
    }

    final message = ChatMessage(
      messageId: messageId,
      conversationId: thread.conversationId,
      sender: ChatSender.me,
      senderName: 'You',
      text: trimmed,
      sentAt: DateTime.now(),
    );

    _store[thread.conversationId] = thread.copyWith(
      unreadCount: 0,
      messages: [...thread.messages, message],
    );
    return message;
  }

  Future<void> _persistChatMessage({
    required PickupChatThread thread,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || thread.dbConversationId == null) return;

    final activeConnector = _connectorOverride ?? ZerohungerConnector.instance;
    try {
      final meResult = await activeConnector.getCurrentUser().execute();
      if (meResult.data.users.isEmpty) return;
      final myUserId = meResult.data.users.first.userId;

      await activeConnector
          .sendChatMessage(
            senderId: myUserId,
            conversationId: thread.dbConversationId!,
            content: text,
          )
          .execute();

      if (thread.otherPartyUserId != null && thread.otherPartyUserId != myUserId) {
        final preview = text.length > 100 ? '${text.substring(0, 97)}...' : text;
        try {
          await activeConnector
              .createNotificationForUser(
                userId: thread.otherPartyUserId!,
                title: 'New pickup message',
                content: '${thread.donationTitle} • $preview',
              )
              .execute();
        } catch (e) {
          debugPrint('Chat notification insert skipped: $e');
        }
      }
    } on DataConnectError catch (e) {
      if (_isOperationMissing(e)) return;
      debugPrint('Could not persist chat message: $e');
    } catch (e) {
      debugPrint('Could not persist chat message: $e');
    }
  }

  bool _isOperationMissing(DataConnectError e) {
    final msg = e.message ?? '';
    return msg.contains('NOT_FOUND') || msg.contains('status code of 404');
  }
}
