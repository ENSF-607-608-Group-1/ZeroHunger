part of 'zerohunger.dart';

class GetCurrentUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetCurrentUserVariablesBuilder(this._dataConnect, );
  Deserializer<GetCurrentUserData> dataDeserializer = (dynamic json)  => GetCurrentUserData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetCurrentUserData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetCurrentUserData, void> ref() {
    
    return _dataConnect.query("GetCurrentUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetCurrentUserUsers {
  final BigInt userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final bool isActive;
  final String userRole;
  final String? street;
  final GetCurrentUserUsersPostalCode? postalCode;
  final List<GetCurrentUserUsersUserOrganizationsOnUser> userOrganizations_on_user;
  final GetCurrentUserUsersUserPreferencesOnUser? userPreferences_on_user;
  GetCurrentUserUsers.fromJson(dynamic json):
  
  userId = bigIntFromJson(json['userId']),
  firstName = json['firstName'] == null ? null : nativeFromJson<String>(json['firstName']),
  lastName = json['lastName'] == null ? null : nativeFromJson<String>(json['lastName']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  phoneNumber = json['phoneNumber'] == null ? null : nativeFromJson<String>(json['phoneNumber']),
  isActive = nativeFromJson<bool>(json['isActive']),
  userRole = nativeFromJson<String>(json['userRole']),
  street = json['street'] == null ? null : nativeFromJson<String>(json['street']),
  postalCode = json['postalCode'] == null ? null : GetCurrentUserUsersPostalCode.fromJson(json['postalCode']),
  userOrganizations_on_user = (json['userOrganizations_on_user'] as List<dynamic>)
        .map((e) => GetCurrentUserUsersUserOrganizationsOnUser.fromJson(e))
        .toList(),
  userPreferences_on_user = json['userPreferences_on_user'] == null ? null : GetCurrentUserUsersUserPreferencesOnUser.fromJson(json['userPreferences_on_user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserUsers otherTyped = other as GetCurrentUserUsers;
    return userId == otherTyped.userId && 
    firstName == otherTyped.firstName && 
    lastName == otherTyped.lastName && 
    email == otherTyped.email && 
    phoneNumber == otherTyped.phoneNumber && 
    isActive == otherTyped.isActive && 
    userRole == otherTyped.userRole && 
    street == otherTyped.street && 
    postalCode == otherTyped.postalCode && 
    userOrganizations_on_user == otherTyped.userOrganizations_on_user && 
    userPreferences_on_user == otherTyped.userPreferences_on_user;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, firstName.hashCode, lastName.hashCode, email.hashCode, phoneNumber.hashCode, isActive.hashCode, userRole.hashCode, street.hashCode, postalCode.hashCode, userOrganizations_on_user.hashCode, userPreferences_on_user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = bigIntToJson(userId);
    if (firstName != null) {
      json['firstName'] = nativeToJson<String?>(firstName);
    }
    if (lastName != null) {
      json['lastName'] = nativeToJson<String?>(lastName);
    }
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    if (phoneNumber != null) {
      json['phoneNumber'] = nativeToJson<String?>(phoneNumber);
    }
    json['isActive'] = nativeToJson<bool>(isActive);
    json['userRole'] = nativeToJson<String>(userRole);
    if (street != null) {
      json['street'] = nativeToJson<String?>(street);
    }
    if (postalCode != null) {
      json['postalCode'] = postalCode!.toJson();
    }
    json['userOrganizations_on_user'] = userOrganizations_on_user.map((e) => e.toJson()).toList();
    if (userPreferences_on_user != null) {
      json['userPreferences_on_user'] = userPreferences_on_user!.toJson();
    }
    return json;
  }

  GetCurrentUserUsers({
    required this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    required this.isActive,
    required this.userRole,
    this.street,
    this.postalCode,
    required this.userOrganizations_on_user,
    this.userPreferences_on_user,
  });
}

@immutable
class GetCurrentUserUsersPostalCode {
  final BigInt postalCodeId;
  final String code;
  final String? city;
  final String? province;
  GetCurrentUserUsersPostalCode.fromJson(dynamic json):
  
  postalCodeId = bigIntFromJson(json['postalCodeId']),
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

    final GetCurrentUserUsersPostalCode otherTyped = other as GetCurrentUserUsersPostalCode;
    return postalCodeId == otherTyped.postalCodeId && 
    code == otherTyped.code && 
    city == otherTyped.city && 
    province == otherTyped.province;
    
  }
  @override
  int get hashCode => Object.hashAll([postalCodeId.hashCode, code.hashCode, city.hashCode, province.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['postalCodeId'] = bigIntToJson(postalCodeId);
    json['code'] = nativeToJson<String>(code);
    if (city != null) {
      json['city'] = nativeToJson<String?>(city);
    }
    if (province != null) {
      json['province'] = nativeToJson<String?>(province);
    }
    return json;
  }

  GetCurrentUserUsersPostalCode({
    required this.postalCodeId,
    required this.code,
    this.city,
    this.province,
  });
}

@immutable
class GetCurrentUserUsersUserOrganizationsOnUser {
  final String memberRole;
  final GetCurrentUserUsersUserOrganizationsOnUserOrganization organization;
  GetCurrentUserUsersUserOrganizationsOnUser.fromJson(dynamic json):
  
  memberRole = nativeFromJson<String>(json['memberRole']),
  organization = GetCurrentUserUsersUserOrganizationsOnUserOrganization.fromJson(json['organization']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserUsersUserOrganizationsOnUser otherTyped = other as GetCurrentUserUsersUserOrganizationsOnUser;
    return memberRole == otherTyped.memberRole && 
    organization == otherTyped.organization;
    
  }
  @override
  int get hashCode => Object.hashAll([memberRole.hashCode, organization.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['memberRole'] = nativeToJson<String>(memberRole);
    json['organization'] = organization.toJson();
    return json;
  }

  GetCurrentUserUsersUserOrganizationsOnUser({
    required this.memberRole,
    required this.organization,
  });
}

@immutable
class GetCurrentUserUsersUserOrganizationsOnUserOrganization {
  final BigInt orgId;
  final String orgName;
  final String orgPrimaryEmail;
  final String? street;
  final GetCurrentUserUsersUserOrganizationsOnUserOrganizationPostalCode? postalCode;
  GetCurrentUserUsersUserOrganizationsOnUserOrganization.fromJson(dynamic json):
  
  orgId = bigIntFromJson(json['orgId']),
  orgName = nativeFromJson<String>(json['orgName']),
  orgPrimaryEmail = nativeFromJson<String>(json['orgPrimaryEmail']),
  street = json['street'] == null ? null : nativeFromJson<String>(json['street']),
  postalCode = json['postalCode'] == null ? null : GetCurrentUserUsersUserOrganizationsOnUserOrganizationPostalCode.fromJson(json['postalCode']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserUsersUserOrganizationsOnUserOrganization otherTyped = other as GetCurrentUserUsersUserOrganizationsOnUserOrganization;
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

  GetCurrentUserUsersUserOrganizationsOnUserOrganization({
    required this.orgId,
    required this.orgName,
    required this.orgPrimaryEmail,
    this.street,
    this.postalCode,
  });
}

@immutable
class GetCurrentUserUsersUserOrganizationsOnUserOrganizationPostalCode {
  final String code;
  final String? city;
  final String? province;
  GetCurrentUserUsersUserOrganizationsOnUserOrganizationPostalCode.fromJson(dynamic json):
  
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

    final GetCurrentUserUsersUserOrganizationsOnUserOrganizationPostalCode otherTyped = other as GetCurrentUserUsersUserOrganizationsOnUserOrganizationPostalCode;
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

  GetCurrentUserUsersUserOrganizationsOnUserOrganizationPostalCode({
    required this.code,
    this.city,
    this.province,
  });
}

@immutable
class GetCurrentUserUsersUserPreferencesOnUser {
  final BigInt profileId;
  final int? radiusSearch;
  final String? notificationPreference;
  final String? alertSetting;
  final BigInt? locationId;
  GetCurrentUserUsersUserPreferencesOnUser.fromJson(dynamic json):
  
  profileId = bigIntFromJson(json['profileId']),
  radiusSearch = json['radiusSearch'] == null ? null : nativeFromJson<int>(json['radiusSearch']),
  notificationPreference = json['notificationPreference'] == null ? null : nativeFromJson<String>(json['notificationPreference']),
  alertSetting = json['alertSetting'] == null ? null : nativeFromJson<String>(json['alertSetting']),
  locationId = json['locationId'] == null ? null : bigIntFromJson(json['locationId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserUsersUserPreferencesOnUser otherTyped = other as GetCurrentUserUsersUserPreferencesOnUser;
    return profileId == otherTyped.profileId && 
    radiusSearch == otherTyped.radiusSearch && 
    notificationPreference == otherTyped.notificationPreference && 
    alertSetting == otherTyped.alertSetting && 
    locationId == otherTyped.locationId;
    
  }
  @override
  int get hashCode => Object.hashAll([profileId.hashCode, radiusSearch.hashCode, notificationPreference.hashCode, alertSetting.hashCode, locationId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['profileId'] = bigIntToJson(profileId);
    if (radiusSearch != null) {
      json['radiusSearch'] = nativeToJson<int?>(radiusSearch);
    }
    if (notificationPreference != null) {
      json['notificationPreference'] = nativeToJson<String?>(notificationPreference);
    }
    if (alertSetting != null) {
      json['alertSetting'] = nativeToJson<String?>(alertSetting);
    }
    if (locationId != null) {
      json['locationId'] = bigIntToJson(locationId);
    }
    return json;
  }

  GetCurrentUserUsersUserPreferencesOnUser({
    required this.profileId,
    this.radiusSearch,
    this.notificationPreference,
    this.alertSetting,
    this.locationId,
  });
}

@immutable
class GetCurrentUserData {
  final List<GetCurrentUserUsers> users;
  GetCurrentUserData.fromJson(dynamic json):
  
  users = (json['users'] as List<dynamic>)
        .map((e) => GetCurrentUserUsers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserData otherTyped = other as GetCurrentUserData;
    return users == otherTyped.users;
    
  }
  @override
  int get hashCode => users.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  GetCurrentUserData({
    required this.users,
  });
}

