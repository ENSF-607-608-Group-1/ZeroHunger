part of 'zerohunger.dart';

class CreateOrganizationVariablesBuilder {
  String orgName;
  String orgPrimaryEmail;
  Optional<String> _street = Optional.optional(nativeFromJson, nativeToJson);
  Optional<BigInt> _postalCodeId = Optional.optional(bigIntFromJson, bigIntToJson);

  final FirebaseDataConnect _dataConnect;  CreateOrganizationVariablesBuilder street(String? t) {
   _street.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder postalCodeId(BigInt? t) {
   _postalCodeId.value = t;
   return this;
  }

  CreateOrganizationVariablesBuilder(this._dataConnect, {required  this.orgName,required  this.orgPrimaryEmail,});
  Deserializer<CreateOrganizationData> dataDeserializer = (dynamic json)  => CreateOrganizationData.fromJson(jsonDecode(json));
  Serializer<CreateOrganizationVariables> varsSerializer = (CreateOrganizationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateOrganizationData, CreateOrganizationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateOrganizationData, CreateOrganizationVariables> ref() {
    CreateOrganizationVariables vars= CreateOrganizationVariables(orgName: orgName,orgPrimaryEmail: orgPrimaryEmail,street: _street,postalCodeId: _postalCodeId,);
    return _dataConnect.mutation("CreateOrganization", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateOrganizationOrganizationInsert {
  final BigInt orgId;
  CreateOrganizationOrganizationInsert.fromJson(dynamic json):
  
  orgId = bigIntFromJson(json['orgId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationOrganizationInsert otherTyped = other as CreateOrganizationOrganizationInsert;
    return orgId == otherTyped.orgId;
    
  }
  @override
  int get hashCode => orgId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = bigIntToJson(orgId);
    return json;
  }

  CreateOrganizationOrganizationInsert({
    required this.orgId,
  });
}

@immutable
class CreateOrganizationData {
  final CreateOrganizationOrganizationInsert organization_insert;
  CreateOrganizationData.fromJson(dynamic json):
  
  organization_insert = CreateOrganizationOrganizationInsert.fromJson(json['organization_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationData otherTyped = other as CreateOrganizationData;
    return organization_insert == otherTyped.organization_insert;
    
  }
  @override
  int get hashCode => organization_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organization_insert'] = organization_insert.toJson();
    return json;
  }

  CreateOrganizationData({
    required this.organization_insert,
  });
}

@immutable
class CreateOrganizationVariables {
  final String orgName;
  final String orgPrimaryEmail;
  late final Optional<String>street;
  late final Optional<BigInt>postalCodeId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateOrganizationVariables.fromJson(Map<String, dynamic> json):
  
  orgName = nativeFromJson<String>(json['orgName']),
  orgPrimaryEmail = nativeFromJson<String>(json['orgPrimaryEmail']) {
  
  
  
  
    street = Optional.optional(nativeFromJson, nativeToJson);
    street.value = json['street'] == null ? null : nativeFromJson<String>(json['street']);
  
  
    postalCodeId = Optional.optional(bigIntFromJson, bigIntToJson);
    postalCodeId.value = json['postalCodeId'] == null ? null : bigIntFromJson(json['postalCodeId']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationVariables otherTyped = other as CreateOrganizationVariables;
    return orgName == otherTyped.orgName && 
    orgPrimaryEmail == otherTyped.orgPrimaryEmail && 
    street == otherTyped.street && 
    postalCodeId == otherTyped.postalCodeId;
    
  }
  @override
  int get hashCode => Object.hashAll([orgName.hashCode, orgPrimaryEmail.hashCode, street.hashCode, postalCodeId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgName'] = nativeToJson<String>(orgName);
    json['orgPrimaryEmail'] = nativeToJson<String>(orgPrimaryEmail);
    if(street.state == OptionalState.set) {
      json['street'] = street.toJson();
    }
    if(postalCodeId.state == OptionalState.set) {
      json['postalCodeId'] = postalCodeId.toJson();
    }
    return json;
  }

  CreateOrganizationVariables({
    required this.orgName,
    required this.orgPrimaryEmail,
    required this.street,
    required this.postalCodeId,
  });
}

