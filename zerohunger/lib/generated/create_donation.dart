part of 'zerohunger.dart';

class CreateDonationVariablesBuilder {
  Optional<String> _donationId = Optional.optional(nativeFromJson, nativeToJson);
  String donationTitle;
  String pickupTime;
  BigInt itemQuantities;
  BigInt statusId;
  Optional<BigInt> _eventId = Optional.optional(bigIntFromJson, bigIntToJson);

  final FirebaseDataConnect _dataConnect;
  CreateDonationVariablesBuilder donationId(String? t) {
   _donationId.value = t;
   return this;
  }
  CreateDonationVariablesBuilder eventId(BigInt? t) {
   _eventId.value = t;
   return this;
  }

  CreateDonationVariablesBuilder(this._dataConnect, {required  this.donationTitle,required  this.pickupTime,required  this.itemQuantities,required  this.statusId,});
  Deserializer<CreateDonationData> dataDeserializer = (dynamic json)  => CreateDonationData.fromJson(jsonDecode(json));
  Serializer<CreateDonationVariables> varsSerializer = (CreateDonationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateDonationData, CreateDonationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateDonationData, CreateDonationVariables> ref() {
    CreateDonationVariables vars= CreateDonationVariables(donationId: _donationId,donationTitle: donationTitle,pickupTime: pickupTime,itemQuantities: itemQuantities,statusId: statusId,eventId: _eventId,);
    return _dataConnect.mutation("CreateDonation", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateDonationAvailableStatus {
  final BigInt statusId;
  CreateDonationAvailableStatus.fromJson(dynamic json):
  
  statusId = bigIntFromJson(json['statusId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateDonationAvailableStatus otherTyped = other as CreateDonationAvailableStatus;
    return statusId == otherTyped.statusId;
    
  }
  @override
  int get hashCode => statusId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['statusId'] = bigIntToJson(statusId);
    return json;
  }

  CreateDonationAvailableStatus({
    required this.statusId,
  });
}

@immutable
class CreateDonationDonationInsert {
  final String donationId;
  CreateDonationDonationInsert.fromJson(dynamic json):
  
  donationId = nativeFromJson<String>(json['donationId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateDonationDonationInsert otherTyped = other as CreateDonationDonationInsert;
    return donationId == otherTyped.donationId;
    
  }
  @override
  int get hashCode => donationId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['donationId'] = nativeToJson<String>(donationId);
    return json;
  }

  CreateDonationDonationInsert({
    required this.donationId,
  });
}

@immutable
class CreateDonationData {
  final CreateDonationAvailableStatus available_status;
  final CreateDonationDonationInsert donation_insert;
  CreateDonationData.fromJson(dynamic json):
  
  available_status = CreateDonationAvailableStatus.fromJson(json['available_status']),
  donation_insert = CreateDonationDonationInsert.fromJson(json['donation_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateDonationData otherTyped = other as CreateDonationData;
    return available_status == otherTyped.available_status && 
    donation_insert == otherTyped.donation_insert;
    
  }
  @override
  int get hashCode => Object.hashAll([available_status.hashCode, donation_insert.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['available_status'] = available_status.toJson();
    json['donation_insert'] = donation_insert.toJson();
    return json;
  }

  CreateDonationData({
    required this.available_status,
    required this.donation_insert,
  });
}

@immutable
class CreateDonationVariables {
  late final Optional<String>donationId;
  final String donationTitle;
  final String pickupTime;
  final BigInt itemQuantities;
  final BigInt statusId;
  late final Optional<BigInt>eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateDonationVariables.fromJson(Map<String, dynamic> json):
  
  donationTitle = nativeFromJson<String>(json['donationTitle']),
  pickupTime = nativeFromJson<String>(json['pickupTime']),
  itemQuantities = bigIntFromJson(json['itemQuantities']),
  statusId = bigIntFromJson(json['statusId']) {
  
  
    donationId = Optional.optional(nativeFromJson, nativeToJson);
    donationId.value = json['donationId'] == null ? null : nativeFromJson<String>(json['donationId']);
  
  
  
  
  
  
    eventId = Optional.optional(bigIntFromJson, bigIntToJson);
    eventId.value = json['eventId'] == null ? null : bigIntFromJson(json['eventId']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateDonationVariables otherTyped = other as CreateDonationVariables;
    return donationId == otherTyped.donationId && 
    donationTitle == otherTyped.donationTitle && 
    pickupTime == otherTyped.pickupTime && 
    itemQuantities == otherTyped.itemQuantities && 
    statusId == otherTyped.statusId && 
    eventId == otherTyped.eventId;
    
  }
  @override
  int get hashCode => Object.hashAll([donationId.hashCode, donationTitle.hashCode, pickupTime.hashCode, itemQuantities.hashCode, statusId.hashCode, eventId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(donationId.state == OptionalState.set) {
      json['donationId'] = donationId.toJson();
    }
    json['donationTitle'] = nativeToJson<String>(donationTitle);
    json['pickupTime'] = nativeToJson<String>(pickupTime);
    json['itemQuantities'] = bigIntToJson(itemQuantities);
    json['statusId'] = bigIntToJson(statusId);
    if(eventId.state == OptionalState.set) {
      json['eventId'] = eventId.toJson();
    }
    return json;
  }

  CreateDonationVariables({
    required this.donationId,
    required this.donationTitle,
    required this.pickupTime,
    required this.itemQuantities,
    required this.statusId,
    required this.eventId,
  });
}

