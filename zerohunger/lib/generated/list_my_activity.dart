part of 'zerohunger.dart';

class ListMyActivityVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListMyActivityVariablesBuilder(this._dataConnect, );
  Deserializer<ListMyActivityData> dataDeserializer = (dynamic json)  => ListMyActivityData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMyActivityData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListMyActivityData, void> ref() {
    
    return _dataConnect.query("ListMyActivity", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMyActivityUserActivities {
  final BigInt activityId;
  final String activityType;
  final Timestamp occurredAt;
  final ListMyActivityUserActivitiesDonation? donation;
  final ListMyActivityUserActivitiesEvent? event;
  ListMyActivityUserActivities.fromJson(dynamic json):
  
  activityId = bigIntFromJson(json['activityId']),
  activityType = nativeFromJson<String>(json['activityType']),
  occurredAt = Timestamp.fromJson(json['occurredAt']),
  donation = json['donation'] == null ? null : ListMyActivityUserActivitiesDonation.fromJson(json['donation']),
  event = json['event'] == null ? null : ListMyActivityUserActivitiesEvent.fromJson(json['event']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyActivityUserActivities otherTyped = other as ListMyActivityUserActivities;
    return activityId == otherTyped.activityId && 
    activityType == otherTyped.activityType && 
    occurredAt == otherTyped.occurredAt && 
    donation == otherTyped.donation && 
    event == otherTyped.event;
    
  }
  @override
  int get hashCode => Object.hashAll([activityId.hashCode, activityType.hashCode, occurredAt.hashCode, donation.hashCode, event.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['activityId'] = bigIntToJson(activityId);
    json['activityType'] = nativeToJson<String>(activityType);
    json['occurredAt'] = occurredAt.toJson();
    if (donation != null) {
      json['donation'] = donation!.toJson();
    }
    if (event != null) {
      json['event'] = event!.toJson();
    }
    return json;
  }

  ListMyActivityUserActivities({
    required this.activityId,
    required this.activityType,
    required this.occurredAt,
    this.donation,
    this.event,
  });
}

@immutable
class ListMyActivityUserActivitiesDonation {
  final String donationTitle;
  final BigInt itemQuantities;
  final ListMyActivityUserActivitiesDonationStatus status;
  ListMyActivityUserActivitiesDonation.fromJson(dynamic json):
  
  donationTitle = nativeFromJson<String>(json['donationTitle']),
  itemQuantities = bigIntFromJson(json['itemQuantities']),
  status = ListMyActivityUserActivitiesDonationStatus.fromJson(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyActivityUserActivitiesDonation otherTyped = other as ListMyActivityUserActivitiesDonation;
    return donationTitle == otherTyped.donationTitle && 
    itemQuantities == otherTyped.itemQuantities && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([donationTitle.hashCode, itemQuantities.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['donationTitle'] = nativeToJson<String>(donationTitle);
    json['itemQuantities'] = bigIntToJson(itemQuantities);
    json['status'] = status.toJson();
    return json;
  }

  ListMyActivityUserActivitiesDonation({
    required this.donationTitle,
    required this.itemQuantities,
    required this.status,
  });
}

@immutable
class ListMyActivityUserActivitiesDonationStatus {
  final String name;
  ListMyActivityUserActivitiesDonationStatus.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyActivityUserActivitiesDonationStatus otherTyped = other as ListMyActivityUserActivitiesDonationStatus;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ListMyActivityUserActivitiesDonationStatus({
    required this.name,
  });
}

@immutable
class ListMyActivityUserActivitiesEvent {
  final String eventType;
  ListMyActivityUserActivitiesEvent.fromJson(dynamic json):
  
  eventType = nativeFromJson<String>(json['eventType']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyActivityUserActivitiesEvent otherTyped = other as ListMyActivityUserActivitiesEvent;
    return eventType == otherTyped.eventType;
    
  }
  @override
  int get hashCode => eventType.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventType'] = nativeToJson<String>(eventType);
    return json;
  }

  ListMyActivityUserActivitiesEvent({
    required this.eventType,
  });
}

@immutable
class ListMyActivityData {
  final List<ListMyActivityUserActivities> userActivities;
  ListMyActivityData.fromJson(dynamic json):
  
  userActivities = (json['userActivities'] as List<dynamic>)
        .map((e) => ListMyActivityUserActivities.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyActivityData otherTyped = other as ListMyActivityData;
    return userActivities == otherTyped.userActivities;
    
  }
  @override
  int get hashCode => userActivities.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userActivities'] = userActivities.map((e) => e.toJson()).toList();
    return json;
  }

  ListMyActivityData({
    required this.userActivities,
  });
}

