part of 'zerohunger.dart';

class ListOrganizationsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListOrganizationsVariablesBuilder(this._dataConnect, );
  Deserializer<ListOrganizationsData> dataDeserializer = (dynamic json)  => ListOrganizationsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListOrganizationsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListOrganizationsData, void> ref() {
    
    return _dataConnect.query("ListOrganizations", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListOrganizationsOrganizations {
  final BigInt orgId;
  final String orgName;
  final String orgPrimaryEmail;
  final String? street;
  final ListOrganizationsOrganizationsPostalCode? postalCode;
  ListOrganizationsOrganizations.fromJson(dynamic json):
  
  orgId = bigIntFromJson(json['orgId']),
  orgName = nativeFromJson<String>(json['orgName']),
  orgPrimaryEmail = nativeFromJson<String>(json['orgPrimaryEmail']),
  street = json['street'] == null ? null : nativeFromJson<String>(json['street']),
  postalCode = json['postalCode'] == null ? null : ListOrganizationsOrganizationsPostalCode.fromJson(json['postalCode']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListOrganizationsOrganizations otherTyped = other as ListOrganizationsOrganizations;
    return orgId == otherTyped.orgId && 
    orgName == otherTyped.orgName && 
    orgPrimaryEmail == otherTyped.orgPrimaryEmail && 
    street == otherTyped.street && 
    postalCode == otherTyped.postalCode;
    
  }
  @override
  int get hashCode => Object.hashAll([orgId.hashCode, orgName.hashCode, orgPrimaryEmail.hashCode, street.hashCode, postalCode.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = bigIntToJson(orgId);
    json['orgName'] = nativeToJson<String>(orgName);
    json['orgPrimaryEmail'] = nativeToJson<String>(orgPrimaryEmail);
    if (street != null) {
      json['street'] = nativeToJson<String?>(street);
    }
    if (postalCode != null) {
      json['postalCode'] = postalCode!.toJson();
    }
    return json;
  }

  ListOrganizationsOrganizations({
    required this.orgId,
    required this.orgName,
    required this.orgPrimaryEmail,
    this.street,
    this.postalCode,
  });
}

@immutable
class ListOrganizationsOrganizationsPostalCode {
  final String code;
  final String? city;
  final String? province;
  ListOrganizationsOrganizationsPostalCode.fromJson(dynamic json):
  
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

    final ListOrganizationsOrganizationsPostalCode otherTyped = other as ListOrganizationsOrganizationsPostalCode;
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

  ListOrganizationsOrganizationsPostalCode({
    required this.code,
    this.city,
    this.province,
  });
}

@immutable
class ListOrganizationsData {
  final List<ListOrganizationsOrganizations> organizations;
  ListOrganizationsData.fromJson(dynamic json):
  
  organizations = (json['organizations'] as List<dynamic>)
        .map((e) => ListOrganizationsOrganizations.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListOrganizationsData otherTyped = other as ListOrganizationsData;
    return organizations == otherTyped.organizations;
    
  }
  @override
  int get hashCode => organizations.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organizations'] = organizations.map((e) => e.toJson()).toList();
    return json;
  }

  ListOrganizationsData({
    required this.organizations,
  });
}

