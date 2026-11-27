part of 'zerohunger.dart';

class ListDonationsByStatusVariablesBuilder {
  BigInt statusId;

  final FirebaseDataConnect _dataConnect;
  ListDonationsByStatusVariablesBuilder(this._dataConnect, {required  this.statusId,});
  Deserializer<ListDonationsByStatusData> dataDeserializer = (dynamic json)  => ListDonationsByStatusData.fromJson(jsonDecode(json));
  Serializer<ListDonationsByStatusVariables> varsSerializer = (ListDonationsByStatusVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListDonationsByStatusData, ListDonationsByStatusVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListDonationsByStatusData, ListDonationsByStatusVariables> ref() {
    ListDonationsByStatusVariables vars= ListDonationsByStatusVariables(statusId: statusId,);
    return _dataConnect.query("ListDonationsByStatus", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListDonationsByStatusDonations {
  final String donationId;
  final String donationTitle;
  final String pickupTime;
  final BigInt itemQuantities;
  final Timestamp updatedAt;
  final ListDonationsByStatusDonationsStatus status;
  final ListDonationsByStatusDonationsEvent? event;
  ListDonationsByStatusDonations.fromJson(dynamic json):
  
  donationId = nativeFromJson<String>(json['donationId']),
  donationTitle = nativeFromJson<String>(json['donationTitle']),
  pickupTime = nativeFromJson<String>(json['pickupTime']),
  itemQuantities = bigIntFromJson(json['itemQuantities']),
  updatedAt = Timestamp.fromJson(json['updatedAt']),
  status = ListDonationsByStatusDonationsStatus.fromJson(json['status']),
  event = json['event'] == null ? null : ListDonationsByStatusDonationsEvent.fromJson(json['event']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDonationsByStatusDonations otherTyped = other as ListDonationsByStatusDonations;
    return donationId == otherTyped.donationId && 
    donationTitle == otherTyped.donationTitle && 
    pickupTime == otherTyped.pickupTime && 
    itemQuantities == otherTyped.itemQuantities && 
    updatedAt == otherTyped.updatedAt && 
    status == otherTyped.status && 
    event == otherTyped.event;
    
  }
  @override
  int get hashCode => Object.hashAll([donationId.hashCode, donationTitle.hashCode, pickupTime.hashCode, itemQuantities.hashCode, updatedAt.hashCode, status.hashCode, event.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['donationId'] = nativeToJson<String>(donationId);
    json['donationTitle'] = nativeToJson<String>(donationTitle);
    json['pickupTime'] = nativeToJson<String>(pickupTime);
    json['itemQuantities'] = bigIntToJson(itemQuantities);
    json['updatedAt'] = updatedAt.toJson();
    json['status'] = status.toJson();
    if (event != null) {
      json['event'] = event!.toJson();
    }
    return json;
  }

  ListDonationsByStatusDonations({
    required this.donationId,
    required this.donationTitle,
    required this.pickupTime,
    required this.itemQuantities,
    required this.updatedAt,
    required this.status,
    this.event,
  });
}

@immutable
class ListDonationsByStatusDonationsStatus {
  final String name;
  ListDonationsByStatusDonationsStatus.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDonationsByStatusDonationsStatus otherTyped = other as ListDonationsByStatusDonationsStatus;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ListDonationsByStatusDonationsStatus({
    required this.name,
  });
}

@immutable
class ListDonationsByStatusDonationsEvent {
  final BigInt eventId;
  final String eventType;
  final Timestamp timeStart;
  final Timestamp timeEnd;
  ListDonationsByStatusDonationsEvent.fromJson(dynamic json):
  
  eventId = bigIntFromJson(json['eventId']),
  eventType = nativeFromJson<String>(json['eventType']),
  timeStart = Timestamp.fromJson(json['timeStart']),
  timeEnd = Timestamp.fromJson(json['timeEnd']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDonationsByStatusDonationsEvent otherTyped = other as ListDonationsByStatusDonationsEvent;
    return eventId == otherTyped.eventId && 
    eventType == otherTyped.eventType && 
    timeStart == otherTyped.timeStart && 
    timeEnd == otherTyped.timeEnd;
    
  }
  @override
  int get hashCode => Object.hashAll([eventId.hashCode, eventType.hashCode, timeStart.hashCode, timeEnd.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = bigIntToJson(eventId);
    json['eventType'] = nativeToJson<String>(eventType);
    json['timeStart'] = timeStart.toJson();
    json['timeEnd'] = timeEnd.toJson();
    return json;
  }

  ListDonationsByStatusDonationsEvent({
    required this.eventId,
    required this.eventType,
    required this.timeStart,
    required this.timeEnd,
  });
}

@immutable
class ListDonationsByStatusData {
  final List<ListDonationsByStatusDonations> donations;
  ListDonationsByStatusData.fromJson(dynamic json):
  
  donations = (json['donations'] as List<dynamic>)
        .map((e) => ListDonationsByStatusDonations.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDonationsByStatusData otherTyped = other as ListDonationsByStatusData;
    return donations == otherTyped.donations;
    
  }
  @override
  int get hashCode => donations.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['donations'] = donations.map((e) => e.toJson()).toList();
    return json;
  }

  ListDonationsByStatusData({
    required this.donations,
  });
}

@immutable
class ListDonationsByStatusVariables {
  final BigInt statusId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListDonationsByStatusVariables.fromJson(Map<String, dynamic> json):
  
  statusId = bigIntFromJson(json['statusId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDonationsByStatusVariables otherTyped = other as ListDonationsByStatusVariables;
    return statusId == otherTyped.statusId;
    
  }
  @override
  int get hashCode => statusId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['statusId'] = bigIntToJson(statusId);
    return json;
  }

  ListDonationsByStatusVariables({
    required this.statusId,
  });
}

