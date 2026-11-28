part of 'zerohunger.dart';

class CreateLocationVariablesBuilder {
  String street;
  BigInt postalCodeId;
  Optional<BigInt> _userId = Optional.optional(bigIntFromJson, bigIntToJson);
  Optional<BigInt> _orgId = Optional.optional(bigIntFromJson, bigIntToJson);

  final FirebaseDataConnect _dataConnect;  CreateLocationVariablesBuilder userId(BigInt? t) {
   _userId.value = t;
   return this;
  }
  CreateLocationVariablesBuilder orgId(BigInt? t) {
   _orgId.value = t;
   return this;
  }

  CreateLocationVariablesBuilder(this._dataConnect, {required  this.street,required  this.postalCodeId,});
  Deserializer<CreateLocationData> dataDeserializer = (dynamic json)  => CreateLocationData.fromJson(jsonDecode(json));
  Serializer<CreateLocationVariables> varsSerializer = (CreateLocationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateLocationData, CreateLocationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateLocationData, CreateLocationVariables> ref() {
    CreateLocationVariables vars= CreateLocationVariables(street: street,postalCodeId: postalCodeId,userId: _userId,orgId: _orgId,);
    return _dataConnect.mutation("CreateLocation", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateLocationLocationsInsert {
  final BigInt locationId;
  CreateLocationLocationsInsert.fromJson(dynamic json):
  
  locationId = bigIntFromJson(json['locationId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLocationLocationsInsert otherTyped = other as CreateLocationLocationsInsert;
    return locationId == otherTyped.locationId;
    
  }
  @override
  int get hashCode => locationId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['locationId'] = bigIntToJson(locationId);
    return json;
  }

  CreateLocationLocationsInsert({
    required this.locationId,
  });
}

@immutable
class CreateLocationData {
  final CreateLocationLocationsInsert locations_insert;
  CreateLocationData.fromJson(dynamic json):
  
  locations_insert = CreateLocationLocationsInsert.fromJson(json['locations_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLocationData otherTyped = other as CreateLocationData;
    return locations_insert == otherTyped.locations_insert;
    
  }
  @override
  int get hashCode => locations_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['locations_insert'] = locations_insert.toJson();
    return json;
  }

  CreateLocationData({
    required this.locations_insert,
  });
}

@immutable
class CreateLocationVariables {
  final String street;
  final BigInt postalCodeId;
  late final Optional<BigInt>userId;
  late final Optional<BigInt>orgId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateLocationVariables.fromJson(Map<String, dynamic> json):
  
  street = nativeFromJson<String>(json['street']),
  postalCodeId = bigIntFromJson(json['postalCodeId']) {
  
  
  
  
    userId = Optional.optional(bigIntFromJson, bigIntToJson);
    userId.value = json['userId'] == null ? null : bigIntFromJson(json['userId']);
  
  
    orgId = Optional.optional(bigIntFromJson, bigIntToJson);
    orgId.value = json['orgId'] == null ? null : bigIntFromJson(json['orgId']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLocationVariables otherTyped = other as CreateLocationVariables;
    return street == otherTyped.street && 
    postalCodeId == otherTyped.postalCodeId && 
    userId == otherTyped.userId && 
    orgId == otherTyped.orgId;
    
  }
  @override
  int get hashCode => Object.hashAll([street.hashCode, postalCodeId.hashCode, userId.hashCode, orgId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['street'] = nativeToJson<String>(street);
    json['postalCodeId'] = bigIntToJson(postalCodeId);
    if(userId.state == OptionalState.set) {
      json['userId'] = userId.toJson();
    }
    if(orgId.state == OptionalState.set) {
      json['orgId'] = orgId.toJson();
    }
    return json;
  }

  CreateLocationVariables({
    required this.street,
    required this.postalCodeId,
    required this.userId,
    required this.orgId,
  });
}

