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
  GetCurrentUserUsers.fromJson(dynamic json):
  
  userId = bigIntFromJson(json['userId']),
  firstName = json['firstName'] == null ? null : nativeFromJson<String>(json['firstName']),
  lastName = json['lastName'] == null ? null : nativeFromJson<String>(json['lastName']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  phoneNumber = json['phoneNumber'] == null ? null : nativeFromJson<String>(json['phoneNumber']),
  isActive = nativeFromJson<bool>(json['isActive']),
  userRole = nativeFromJson<String>(json['userRole']),
  street = json['street'] == null ? null : nativeFromJson<String>(json['street']),
  postalCode = json['postalCode'] == null ? null : GetCurrentUserUsersPostalCode.fromJson(json['postalCode']);
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
    postalCode == otherTyped.postalCode;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, firstName.hashCode, lastName.hashCode, email.hashCode, phoneNumber.hashCode, isActive.hashCode, userRole.hashCode, street.hashCode, postalCode.hashCode]);
  

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
  });
}

@immutable
class GetCurrentUserUsersPostalCode {
  final String code;
  final String? city;
  final String? province;
  GetCurrentUserUsersPostalCode.fromJson(dynamic json):
  
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

  GetCurrentUserUsersPostalCode({
    required this.code,
    this.city,
    this.province,
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

