part of 'zerohunger.dart';

class GetOrganizationByPrimaryEmailVariablesBuilder {
  String orgPrimaryEmail;

  final FirebaseDataConnect _dataConnect;
  GetOrganizationByPrimaryEmailVariablesBuilder(this._dataConnect, {required  this.orgPrimaryEmail,});
  Deserializer<GetOrganizationByPrimaryEmailData> dataDeserializer = (dynamic json)  => GetOrganizationByPrimaryEmailData.fromJson(jsonDecode(json));
  Serializer<GetOrganizationByPrimaryEmailVariables> varsSerializer = (GetOrganizationByPrimaryEmailVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetOrganizationByPrimaryEmailData, GetOrganizationByPrimaryEmailVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetOrganizationByPrimaryEmailData, GetOrganizationByPrimaryEmailVariables> ref() {
    GetOrganizationByPrimaryEmailVariables vars= GetOrganizationByPrimaryEmailVariables(orgPrimaryEmail: orgPrimaryEmail,);
    return _dataConnect.query("GetOrganizationByPrimaryEmail", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetOrganizationByPrimaryEmailOrganizations {
  final BigInt orgId;
  final String orgName;
  final String orgPrimaryEmail;
  GetOrganizationByPrimaryEmailOrganizations.fromJson(dynamic json):
  
  orgId = bigIntFromJson(json['orgId']),
  orgName = nativeFromJson<String>(json['orgName']),
  orgPrimaryEmail = nativeFromJson<String>(json['orgPrimaryEmail']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationByPrimaryEmailOrganizations otherTyped = other as GetOrganizationByPrimaryEmailOrganizations;
    return orgId == otherTyped.orgId && 
    orgName == otherTyped.orgName && 
    orgPrimaryEmail == otherTyped.orgPrimaryEmail;
    
  }
  @override
  int get hashCode => Object.hashAll([orgId.hashCode, orgName.hashCode, orgPrimaryEmail.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = bigIntToJson(orgId);
    json['orgName'] = nativeToJson<String>(orgName);
    json['orgPrimaryEmail'] = nativeToJson<String>(orgPrimaryEmail);
    return json;
  }

  GetOrganizationByPrimaryEmailOrganizations({
    required this.orgId,
    required this.orgName,
    required this.orgPrimaryEmail,
  });
}

@immutable
class GetOrganizationByPrimaryEmailData {
  final List<GetOrganizationByPrimaryEmailOrganizations> organizations;
  GetOrganizationByPrimaryEmailData.fromJson(dynamic json):
  
  organizations = (json['organizations'] as List<dynamic>)
        .map((e) => GetOrganizationByPrimaryEmailOrganizations.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationByPrimaryEmailData otherTyped = other as GetOrganizationByPrimaryEmailData;
    return organizations == otherTyped.organizations;
    
  }
  @override
  int get hashCode => organizations.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organizations'] = organizations.map((e) => e.toJson()).toList();
    return json;
  }

  GetOrganizationByPrimaryEmailData({
    required this.organizations,
  });
}

@immutable
class GetOrganizationByPrimaryEmailVariables {
  final String orgPrimaryEmail;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetOrganizationByPrimaryEmailVariables.fromJson(Map<String, dynamic> json):
  
  orgPrimaryEmail = nativeFromJson<String>(json['orgPrimaryEmail']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationByPrimaryEmailVariables otherTyped = other as GetOrganizationByPrimaryEmailVariables;
    return orgPrimaryEmail == otherTyped.orgPrimaryEmail;
    
  }
  @override
  int get hashCode => orgPrimaryEmail.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgPrimaryEmail'] = nativeToJson<String>(orgPrimaryEmail);
    return json;
  }

  GetOrganizationByPrimaryEmailVariables({
    required this.orgPrimaryEmail,
  });
}

