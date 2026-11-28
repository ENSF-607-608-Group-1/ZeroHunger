part of 'zerohunger.dart';

// ---------------------------------------------------------------------------
// ListMyConversations
// ---------------------------------------------------------------------------

class ListMyConversationsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  ListMyConversationsVariablesBuilder(this._dataConnect);

  Deserializer<ListMyConversationsData> dataDeserializer = (dynamic json) =>
      ListMyConversationsData.fromJson(jsonDecode(json));

  Future<QueryResult<ListMyConversationsData, void>> execute() => ref().execute();

  QueryRef<ListMyConversationsData, void> ref() {
    return _dataConnect.query(
      "ListMyConversations",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class ListMyConversationsUser {
  final BigInt userId;
  final String authUid;
  final String? firstName;
  final String? lastName;
  final String? userRole;

  const ListMyConversationsUser({
    required this.userId,
    required this.authUid,
    this.firstName,
    this.lastName,
    this.userRole,
  });

  ListMyConversationsUser.fromJson(dynamic json)
      : userId = bigIntFromJson(json['userId']),
        authUid = json['authUid'] == null ? '' : nativeFromJson<String>(json['authUid']),
        firstName = json['firstName'] == null ? null : nativeFromJson<String>(json['firstName']),
        lastName = json['lastName'] == null ? null : nativeFromJson<String>(json['lastName']),
        userRole = json['userRole'] == null ? null : nativeFromJson<String>(json['userRole']);

  String get displayName {
    final full = [firstName?.trim() ?? '', lastName?.trim() ?? '']
        .where((part) => part.isNotEmpty)
        .join(' ');
    return full;
  }
}

@immutable
class ListMyConversationsMember {
  final ListMyConversationsUser user;

  const ListMyConversationsMember({required this.user});

  ListMyConversationsMember.fromJson(dynamic json)
      : user = ListMyConversationsUser.fromJson(json['user']);
}

@immutable
class ListMyConversationsMessage {
  final BigInt messageId;
  final String content;
  final Timestamp sentAt;
  final Timestamp? readAt;
  final ListMyConversationsUser sender;

  const ListMyConversationsMessage({
    required this.messageId,
    required this.content,
    required this.sentAt,
    this.readAt,
    required this.sender,
  });

  ListMyConversationsMessage.fromJson(dynamic json)
      : messageId = bigIntFromJson(json['messageId']),
        content = json['content'] == null ? '' : nativeFromJson<String>(json['content']),
        sentAt = Timestamp.fromJson(json['sentAt']),
        readAt = json['readAt'] == null ? null : Timestamp.fromJson(json['readAt']),
        sender = ListMyConversationsUser.fromJson(json['sender']);
}

@immutable
class ListMyConversationsConversation {
  final BigInt conversationId;
  final String conversationType;
  final Timestamp createdAt;
  final List<ListMyConversationsMember> members;
  final List<ListMyConversationsMessage> messages;

  const ListMyConversationsConversation({
    required this.conversationId,
    required this.conversationType,
    required this.createdAt,
    required this.members,
    required this.messages,
  });

  ListMyConversationsConversation.fromJson(dynamic json)
      : conversationId = bigIntFromJson(json['conversationId']),
        conversationType = json['conversationType'] == null
            ? 'PICKUP'
            : nativeFromJson<String>(json['conversationType']),
        createdAt = Timestamp.fromJson(json['createdAt']),
        members = ((json['userConversations_on_conversation'] as List<dynamic>?) ?? const [])
            .map((e) => ListMyConversationsMember.fromJson(e))
            .toList(),
        messages = ((json['messagess_on_conversation'] as List<dynamic>?) ??
                (json['messages_on_conversation'] as List<dynamic>?) ??
                const [])
            .map((e) => ListMyConversationsMessage.fromJson(e))
            .toList();
}

@immutable
class ListMyConversationsUserConversation {
  final ListMyConversationsConversation conversation;

  const ListMyConversationsUserConversation({required this.conversation});

  ListMyConversationsUserConversation.fromJson(dynamic json)
      : conversation = ListMyConversationsConversation.fromJson(json['conversation']);
}

@immutable
class ListMyConversationsData {
  final List<ListMyConversationsUserConversation> userConversations;

  const ListMyConversationsData({required this.userConversations});

  ListMyConversationsData.fromJson(dynamic json)
      : userConversations = ((json['userConversations'] as List<dynamic>?) ?? const [])
            .map((e) => ListMyConversationsUserConversation.fromJson(e))
            .toList();
}

// ---------------------------------------------------------------------------
// GetDonationDonor
// ---------------------------------------------------------------------------

class GetDonationDonorVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  final String donationId;

  GetDonationDonorVariablesBuilder(this._dataConnect, {required this.donationId});

  Deserializer<GetDonationDonorData> dataDeserializer = (dynamic json) =>
      GetDonationDonorData.fromJson(jsonDecode(json));

  Serializer<GetDonationDonorVariables> varsSerializer =
      (GetDonationDonorVariables vars) => jsonEncode(vars.toJson());

  Future<QueryResult<GetDonationDonorData, GetDonationDonorVariables>> execute() =>
      ref().execute();

  QueryRef<GetDonationDonorData, GetDonationDonorVariables> ref() {
    return _dataConnect.query(
      "GetDonationDonor",
      dataDeserializer,
      varsSerializer,
      GetDonationDonorVariables(donationId: donationId),
    );
  }
}

@immutable
class GetDonationDonorVariables {
  final String donationId;
  const GetDonationDonorVariables({required this.donationId});

  Map<String, dynamic> toJson() => {'donationId': nativeToJson<String>(donationId)};
}

@immutable
class GetDonationDonorActivity {
  final ListMyConversationsUser user;
  const GetDonationDonorActivity({required this.user});

  GetDonationDonorActivity.fromJson(dynamic json)
      : user = ListMyConversationsUser.fromJson(json['user']);
}

@immutable
class GetDonationDonorData {
  final List<GetDonationDonorActivity> userActivities;
  const GetDonationDonorData({required this.userActivities});

  GetDonationDonorData.fromJson(dynamic json)
      : userActivities = ((json['userActivities'] as List<dynamic>?) ?? const [])
            .map((e) => GetDonationDonorActivity.fromJson(e))
            .toList();
}

// ---------------------------------------------------------------------------
// CreateConversation
// ---------------------------------------------------------------------------

class CreateConversationVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  final String conversationType;

  CreateConversationVariablesBuilder(this._dataConnect, {required this.conversationType});

  Deserializer<CreateConversationData> dataDeserializer = (dynamic json) =>
      CreateConversationData.fromJson(jsonDecode(json));

  Serializer<CreateConversationVariables> varsSerializer =
      (CreateConversationVariables vars) => jsonEncode(vars.toJson());

  Future<OperationResult<CreateConversationData, CreateConversationVariables>> execute() =>
      ref().execute();

  MutationRef<CreateConversationData, CreateConversationVariables> ref() {
    return _dataConnect.mutation(
      "CreateConversation",
      dataDeserializer,
      varsSerializer,
      CreateConversationVariables(conversationType: conversationType),
    );
  }
}

@immutable
class CreateConversationVariables {
  final String conversationType;
  const CreateConversationVariables({required this.conversationType});

  Map<String, dynamic> toJson() => {
        'conversationType': nativeToJson<String>(conversationType),
      };
}

@immutable
class CreateConversationKey {
  final BigInt conversationId;
  const CreateConversationKey({required this.conversationId});

  CreateConversationKey.fromJson(dynamic json)
      : conversationId = bigIntFromJson(json['conversationId']);
}

@immutable
class CreateConversationData {
  final CreateConversationKey conversations_insert;
  const CreateConversationData({required this.conversations_insert});

  CreateConversationData.fromJson(dynamic json)
      : conversations_insert = CreateConversationKey.fromJson(json['conversations_insert']);
}

// ---------------------------------------------------------------------------
// AddConversationMember
// ---------------------------------------------------------------------------

class AddConversationMemberVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  final BigInt userId;
  final BigInt conversationId;

  AddConversationMemberVariablesBuilder(
    this._dataConnect, {
    required this.userId,
    required this.conversationId,
  });

  Deserializer<AddConversationMemberData> dataDeserializer = (dynamic json) =>
      AddConversationMemberData.fromJson(jsonDecode(json));

  Serializer<AddConversationMemberVariables> varsSerializer =
      (AddConversationMemberVariables vars) => jsonEncode(vars.toJson());

  Future<OperationResult<AddConversationMemberData, AddConversationMemberVariables>> execute() =>
      ref().execute();

  MutationRef<AddConversationMemberData, AddConversationMemberVariables> ref() {
    return _dataConnect.mutation(
      "AddConversationMember",
      dataDeserializer,
      varsSerializer,
      AddConversationMemberVariables(userId: userId, conversationId: conversationId),
    );
  }
}

@immutable
class AddConversationMemberVariables {
  final BigInt userId;
  final BigInt conversationId;

  const AddConversationMemberVariables({
    required this.userId,
    required this.conversationId,
  });

  Map<String, dynamic> toJson() => {
        'userId': bigIntToJson(userId),
        'conversationId': bigIntToJson(conversationId),
      };
}

@immutable
class AddConversationMemberData {
  const AddConversationMemberData();
  AddConversationMemberData.fromJson(dynamic _);
}

// ---------------------------------------------------------------------------
// SendChatMessage
// ---------------------------------------------------------------------------

class SendChatMessageVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  final BigInt senderId;
  final BigInt conversationId;
  final String content;

  SendChatMessageVariablesBuilder(
    this._dataConnect, {
    required this.senderId,
    required this.conversationId,
    required this.content,
  });

  Deserializer<SendChatMessageData> dataDeserializer = (dynamic json) =>
      SendChatMessageData.fromJson(jsonDecode(json));

  Serializer<SendChatMessageVariables> varsSerializer =
      (SendChatMessageVariables vars) => jsonEncode(vars.toJson());

  Future<OperationResult<SendChatMessageData, SendChatMessageVariables>> execute() =>
      ref().execute();

  MutationRef<SendChatMessageData, SendChatMessageVariables> ref() {
    return _dataConnect.mutation(
      "SendChatMessage",
      dataDeserializer,
      varsSerializer,
      SendChatMessageVariables(
        senderId: senderId,
        conversationId: conversationId,
        content: content,
      ),
    );
  }
}

@immutable
class SendChatMessageVariables {
  final BigInt senderId;
  final BigInt conversationId;
  final String content;

  const SendChatMessageVariables({
    required this.senderId,
    required this.conversationId,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'senderId': bigIntToJson(senderId),
        'conversationId': bigIntToJson(conversationId),
        'content': nativeToJson<String>(content),
      };
}

@immutable
class SendChatMessageKey {
  final BigInt messageId;
  const SendChatMessageKey({required this.messageId});

  SendChatMessageKey.fromJson(dynamic json)
      : messageId = bigIntFromJson(json['messageId']);
}

@immutable
class SendChatMessageData {
  final SendChatMessageKey messages_insert;
  const SendChatMessageData({required this.messages_insert});

  SendChatMessageData.fromJson(dynamic json)
      : messages_insert = SendChatMessageKey.fromJson(json['messages_insert']);
}

// ---------------------------------------------------------------------------
// CreateNotificationForUser
// ---------------------------------------------------------------------------

class CreateNotificationForUserVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  final BigInt userId;
  final String title;
  final String content;
  Optional<BigInt> _eventId = Optional.optional(bigIntFromJson, bigIntToJson);

  CreateNotificationForUserVariablesBuilder(
    this._dataConnect, {
    required this.userId,
    required this.title,
    required this.content,
  });

  CreateNotificationForUserVariablesBuilder eventId(BigInt? value) {
    _eventId.value = value;
    return this;
  }

  Deserializer<CreateNotificationForUserData> dataDeserializer = (dynamic json) =>
      CreateNotificationForUserData.fromJson(jsonDecode(json));

  Serializer<CreateNotificationForUserVariables> varsSerializer =
      (CreateNotificationForUserVariables vars) => jsonEncode(vars.toJson());

  Future<OperationResult<CreateNotificationForUserData, CreateNotificationForUserVariables>>
      execute() => ref().execute();

  MutationRef<CreateNotificationForUserData, CreateNotificationForUserVariables> ref() {
    return _dataConnect.mutation(
      "CreateNotificationForUser",
      dataDeserializer,
      varsSerializer,
      CreateNotificationForUserVariables(
        userId: userId,
        title: title,
        content: content,
        eventId: _eventId,
      ),
    );
  }
}

@immutable
class CreateNotificationForUserVariables {
  final BigInt userId;
  final String title;
  final String content;
  final Optional<BigInt> eventId;

  const CreateNotificationForUserVariables({
    required this.userId,
    required this.title,
    required this.content,
    required this.eventId,
  });

  Map<String, dynamic> toJson() => {
        'userId': bigIntToJson(userId),
        'title': nativeToJson<String>(title),
        'content': nativeToJson<String>(content),
        if (eventId.state == OptionalState.set) 'eventId': eventId.toJson(),
      };
}

@immutable
class CreateNotificationForUserData {
  const CreateNotificationForUserData();
  CreateNotificationForUserData.fromJson(dynamic _);
}

// ---------------------------------------------------------------------------
// RecordClaimActivity
// ---------------------------------------------------------------------------

class RecordClaimActivityVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  final BigInt userId;
  final String donationId;

  RecordClaimActivityVariablesBuilder(
    this._dataConnect, {
    required this.userId,
    required this.donationId,
  });

  Deserializer<RecordClaimActivityData> dataDeserializer = (dynamic json) =>
      RecordClaimActivityData.fromJson(jsonDecode(json));

  Serializer<RecordClaimActivityVariables> varsSerializer =
      (RecordClaimActivityVariables vars) => jsonEncode(vars.toJson());

  Future<OperationResult<RecordClaimActivityData, RecordClaimActivityVariables>> execute() =>
      ref().execute();

  MutationRef<RecordClaimActivityData, RecordClaimActivityVariables> ref() {
    return _dataConnect.mutation(
      "RecordClaimActivity",
      dataDeserializer,
      varsSerializer,
      RecordClaimActivityVariables(userId: userId, donationId: donationId),
    );
  }
}

@immutable
class RecordClaimActivityVariables {
  final BigInt userId;
  final String donationId;

  const RecordClaimActivityVariables({
    required this.userId,
    required this.donationId,
  });

  Map<String, dynamic> toJson() => {
        'userId': bigIntToJson(userId),
        'donationId': nativeToJson<String>(donationId),
      };
}

@immutable
class RecordClaimActivityData {
  const RecordClaimActivityData();
  RecordClaimActivityData.fromJson(dynamic _);
}
