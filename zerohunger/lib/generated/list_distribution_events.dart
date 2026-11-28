part of 'zerohunger.dart';

class ListDistributionEventsVariablesBuilder {
  Timestamp asOf;

  final FirebaseDataConnect _dataConnect;
  ListDistributionEventsVariablesBuilder(this._dataConnect, {required  this.asOf,});
  Deserializer<ListDistributionEventsData> dataDeserializer = (dynamic json)  => ListDistributionEventsData.fromJson(jsonDecode(json));
  Serializer<ListDistributionEventsVariables> varsSerializer = (ListDistributionEventsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListDistributionEventsData, ListDistributionEventsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListDistributionEventsData, ListDistributionEventsVariables> ref() {
    ListDistributionEventsVariables vars= ListDistributionEventsVariables(asOf: asOf,);
    return _dataConnect.query("ListDistributionEvents", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListDistributionEventsDistributionEvents {
  final BigInt eventId;
  final String eventType;
  final Timestamp timeStart;
  final Timestamp timeEnd;
  final ListDistributionEventsDistributionEventsLocation location;
  ListDistributionEventsDistributionEvents.fromJson(dynamic json):
  
  eventId = bigIntFromJson(json['eventId']),
  eventType = nativeFromJson<String>(json['eventType']),
  timeStart = Timestamp.fromJson(json['timeStart']),
  timeEnd = Timestamp.fromJson(json['timeEnd']),
  location = ListDistributionEventsDistributionEventsLocation.fromJson(json['location']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDistributionEventsDistributionEvents otherTyped = other as ListDistributionEventsDistributionEvents;
    return eventId == otherTyped.eventId && 
    eventType == otherTyped.eventType && 
    timeStart == otherTyped.timeStart && 
    timeEnd == otherTyped.timeEnd && 
    location == otherTyped.location;
    
  }
  @override
  int get hashCode => Object.hashAll([eventId.hashCode, eventType.hashCode, timeStart.hashCode, timeEnd.hashCode, location.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = bigIntToJson(eventId);
    json['eventType'] = nativeToJson<String>(eventType);
    json['timeStart'] = timeStart.toJson();
    json['timeEnd'] = timeEnd.toJson();
    json['location'] = location.toJson();
    return json;
  }

  ListDistributionEventsDistributionEvents({
    required this.eventId,
    required this.eventType,
    required this.timeStart,
    required this.timeEnd,
    required this.location,
  });
}

@immutable
class ListDistributionEventsDistributionEventsLocation {
  final String street;
  final ListDistributionEventsDistributionEventsLocationPostalCode postalCode;
  final ListDistributionEventsDistributionEventsLocationOrganization? organization;
  ListDistributionEventsDistributionEventsLocation.fromJson(dynamic json):
  
  street = nativeFromJson<String>(json['street']),
  postalCode = ListDistributionEventsDistributionEventsLocationPostalCode.fromJson(json['postalCode']),
  organization = json['organization'] == null ? null : ListDistributionEventsDistributionEventsLocationOrganization.fromJson(json['organization']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDistributionEventsDistributionEventsLocation otherTyped = other as ListDistributionEventsDistributionEventsLocation;
    return street == otherTyped.street && 
    postalCode == otherTyped.postalCode && 
    organization == otherTyped.organization;
    
  }
  @override
  int get hashCode => Object.hashAll([street.hashCode, postalCode.hashCode, organization.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['street'] = nativeToJson<String>(street);
    json['postalCode'] = postalCode.toJson();
    if (organization != null) {
      json['organization'] = organization!.toJson();
    }
    return json;
  }

  ListDistributionEventsDistributionEventsLocation({
    required this.street,
    required this.postalCode,
    this.organization,
  });
}

@immutable
class ListDistributionEventsDistributionEventsLocationPostalCode {
  final String code;
  final String? city;
  final String? province;
  ListDistributionEventsDistributionEventsLocationPostalCode.fromJson(dynamic json):
  
  code = nativeFromJson<String>(json['code']),
  city = json['city'] == null ? null : nativeFromJson<String>(json['city']),
  province = json['province'] == null ? null : nativeFromJson<String>(json['province']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDistributionEventsDistributionEventsLocationPostalCode otherTyped = other as ListDistributionEventsDistributionEventsLocationPostalCode;
    return code == otherTyped.code && 
    city == otherTyped.city && 
    province == otherTyped.province;
    
  }
  @override
  int get hashCode => Object.hashAll([code.hashCode, city.hashCode, province.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['code'] = nativeToJson<String>(code);
    if (city != null) {
      json['city'] = nativeToJson<String?>(city);
    }
    if (province != null) {
      json['province'] = nativeToJson<String?>(province);
    }
    return json;
  }

  ListDistributionEventsDistributionEventsLocationPostalCode({
    required this.code,
    this.city,
    this.province,
  });
}

@immutable
class ListDistributionEventsDistributionEventsLocationOrganization {
  final String orgName;
  ListDistributionEventsDistributionEventsLocationOrganization.fromJson(dynamic json):
  
  orgName = nativeFromJson<String>(json['orgName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDistributionEventsDistributionEventsLocationOrganization otherTyped = other as ListDistributionEventsDistributionEventsLocationOrganization;
    return orgName == otherTyped.orgName;
    
  }
  @override
  int get hashCode => orgName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgName'] = nativeToJson<String>(orgName);
    return json;
  }

  ListDistributionEventsDistributionEventsLocationOrganization({
    required this.orgName,
  });
}

@immutable
class ListDistributionEventsData {
  final List<ListDistributionEventsDistributionEvents> distributionEvents;
  ListDistributionEventsData.fromJson(dynamic json):
  
  distributionEvents = (json['distributionEvents'] as List<dynamic>)
        .map((e) => ListDistributionEventsDistributionEvents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDistributionEventsData otherTyped = other as ListDistributionEventsData;
    return distributionEvents == otherTyped.distributionEvents;
    
  }
  @override
  int get hashCode => distributionEvents.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['distributionEvents'] = distributionEvents.map((e) => e.toJson()).toList();
    return json;
  }

  ListDistributionEventsData({
    required this.distributionEvents,
  });
}

@immutable
class ListDistributionEventsVariables {
  final Timestamp asOf;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListDistributionEventsVariables.fromJson(Map<String, dynamic> json):
  
  asOf = Timestamp.fromJson(json['asOf']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDistributionEventsVariables otherTyped = other as ListDistributionEventsVariables;
    return asOf == otherTyped.asOf;
    
  }
  @override
  int get hashCode => asOf.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['asOf'] = asOf.toJson();
    return json;
  }

  ListDistributionEventsVariables({
    required this.asOf,
  });
}

