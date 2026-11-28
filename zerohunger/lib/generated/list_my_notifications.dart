part of 'zerohunger.dart';

class ListMyNotificationsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  ListMyNotificationsVariablesBuilder(this._dataConnect);
  Deserializer<ListMyNotificationsData> dataDeserializer = (dynamic json) =>
      ListMyNotificationsData.fromJson(jsonDecode(json));

  Future<QueryResult<ListMyNotificationsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListMyNotificationsData, void> ref() {
    return _dataConnect.query(
      "ListMyNotifications",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class ListMyNotificationsNotifications {
  final BigInt notificationId;
  final String title;
  final String content;
  final Timestamp createdAt;
  final BigInt? eventId;

  ListMyNotificationsNotifications.fromJson(dynamic json)
      : notificationId = bigIntFromJson(json['notificationId']),
        title = nativeFromJson<String>(json['title']),
        content = nativeFromJson<String>(json['content']),
        createdAt = Timestamp.fromJson(json['createdAt']),
        eventId = json['eventId'] == null ? null : bigIntFromJson(json['eventId']);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final otherTyped = other as ListMyNotificationsNotifications;
    return notificationId == otherTyped.notificationId &&
        title == otherTyped.title &&
        content == otherTyped.content &&
        createdAt == otherTyped.createdAt &&
        eventId == otherTyped.eventId;
  }

  @override
  int get hashCode =>
      Object.hashAll([notificationId.hashCode, title.hashCode, content.hashCode, createdAt.hashCode, eventId.hashCode]);

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['notificationId'] = bigIntToJson(notificationId);
    json['title'] = nativeToJson<String>(title);
    json['content'] = nativeToJson<String>(content);
    json['createdAt'] = createdAt.toJson();
    if (eventId != null) {
      json['eventId'] = bigIntToJson(eventId);
    }
    return json;
  }

  ListMyNotificationsNotifications({
    required this.notificationId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.eventId,
  });
}

@immutable
class ListMyNotificationsData {
  final List<ListMyNotificationsNotifications> notifications;

  ListMyNotificationsData.fromJson(dynamic json)
      : notifications = ((json['notifications'] as List<dynamic>?) ?? const [])
            .map((e) => ListMyNotificationsNotifications.fromJson(e))
            .toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final otherTyped = other as ListMyNotificationsData;
    return notifications == otherTyped.notifications;
  }

  @override
  int get hashCode => notifications.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.map((e) => e.toJson()).toList(),
    };
  }

  ListMyNotificationsData({required this.notifications});
}
