part of 'zerohunger.dart';

class CreateDonationVariablesBuilder {
  String donationTitle;
  String pickupTime;
  BigInt itemQuantities;
  BigInt statusId;
  Optional<BigInt> _eventId = Optional.optional(bigIntFromJson, bigIntToJson);

  final FirebaseDataConnect _dataConnect;  CreateDonationVariablesBuilder eventId(BigInt? t) {
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
    CreateDonationVariables vars= CreateDonationVariables(donationTitle: donationTitle,pickupTime: pickupTime,itemQuantities: itemQuantities,statusId: statusId,eventId: _eventId,);
    return _dataConnect.mutation("CreateDonation", dataDeserializer, varsSerializer, vars);
  }
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
  final CreateDonationDonationInsert donation_insert;
  CreateDonationData.fromJson(dynamic json):
  
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
    return donation_insert == otherTyped.donation_insert;
    
  }
  @override
  int get hashCode => donation_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['donation_insert'] = donation_insert.toJson();
    return json;
  }

  CreateDonationData({
    required this.donation_insert,
  });
}

@immutable
class CreateDonationVariables {
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
    return donationTitle == otherTyped.donationTitle && 
    pickupTime == otherTyped.pickupTime && 
    itemQuantities == otherTyped.itemQuantities && 
    statusId == otherTyped.statusId && 
    eventId == otherTyped.eventId;
    
  }
  @override
  int get hashCode => Object.hashAll([donationTitle.hashCode, pickupTime.hashCode, itemQuantities.hashCode, statusId.hashCode, eventId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
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
    required this.donationTitle,
    required this.pickupTime,
    required this.itemQuantities,
    required this.statusId,
    required this.eventId,
  });
}

