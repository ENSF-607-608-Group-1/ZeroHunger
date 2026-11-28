part of 'zerohunger.dart';

class CreateCurrentUserVariablesBuilder {
  Optional<String> _firstName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _lastName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _phoneNumber = Optional.optional(nativeFromJson, nativeToJson);
  String userRole;
  Optional<String> _street = Optional.optional(nativeFromJson, nativeToJson);
  Optional<BigInt> _postalCodeId = Optional.optional(bigIntFromJson, bigIntToJson);

  final FirebaseDataConnect _dataConnect;
  CreateCurrentUserVariablesBuilder firstName(String? t) {
   _firstName.value = t;
   return this;
  }
  CreateCurrentUserVariablesBuilder lastName(String? t) {
   _lastName.value = t;
   return this;
  }
  CreateCurrentUserVariablesBuilder phoneNumber(String? t) {
   _phoneNumber.value = t;
   return this;
  }
  CreateCurrentUserVariablesBuilder street(String? t) {
   _street.value = t;
   return this;
  }
  CreateCurrentUserVariablesBuilder postalCodeId(BigInt? t) {
   _postalCodeId.value = t;
   return this;
  }

  CreateCurrentUserVariablesBuilder(this._dataConnect, {required  this.userRole,});
  Deserializer<CreateCurrentUserData> dataDeserializer = (dynamic json)  => CreateCurrentUserData.fromJson(jsonDecode(json));
  Serializer<CreateCurrentUserVariables> varsSerializer = (CreateCurrentUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateCurrentUserData, CreateCurrentUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateCurrentUserData, CreateCurrentUserVariables> ref() {
    CreateCurrentUserVariables vars= CreateCurrentUserVariables(firstName: _firstName,lastName: _lastName,phoneNumber: _phoneNumber,userRole: userRole,street: _street,postalCodeId: _postalCodeId,);
    return _dataConnect.mutation("CreateCurrentUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateCurrentUserUserInsert {
  final BigInt userId;
  CreateCurrentUserUserInsert.fromJson(dynamic json):
  
  userId = bigIntFromJson(json['userId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateCurrentUserUserInsert otherTyped = other as CreateCurrentUserUserInsert;
    return userId == otherTyped.userId;
    
  }
  @override
  int get hashCode => userId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = bigIntToJson(userId);
    return json;
  }

  CreateCurrentUserUserInsert({
    required this.userId,
  });
}

@immutable
class CreateCurrentUserData {
  final CreateCurrentUserUserInsert user_insert;
  CreateCurrentUserData.fromJson(dynamic json):
  
  user_insert = CreateCurrentUserUserInsert.fromJson(json['user_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateCurrentUserData otherTyped = other as CreateCurrentUserData;
    return user_insert == otherTyped.user_insert;
    
  }
  @override
  int get hashCode => user_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_insert'] = user_insert.toJson();
    return json;
  }

  CreateCurrentUserData({
    required this.user_insert,
  });
}

@immutable
class CreateCurrentUserVariables {
  late final Optional<String>firstName;
  late final Optional<String>lastName;
  late final Optional<String>phoneNumber;
  final String userRole;
  late final Optional<String>street;
  late final Optional<BigInt>postalCodeId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateCurrentUserVariables.fromJson(Map<String, dynamic> json):
  
  userRole = nativeFromJson<String>(json['userRole']) {
  
  
    firstName = Optional.optional(nativeFromJson, nativeToJson);
    firstName.value = json['firstName'] == null ? null : nativeFromJson<String>(json['firstName']);
  
  
    lastName = Optional.optional(nativeFromJson, nativeToJson);
    lastName.value = json['lastName'] == null ? null : nativeFromJson<String>(json['lastName']);
  
  
    phoneNumber = Optional.optional(nativeFromJson, nativeToJson);
    phoneNumber.value = json['phoneNumber'] == null ? null : nativeFromJson<String>(json['phoneNumber']);
  
  
  
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

    final CreateCurrentUserVariables otherTyped = other as CreateCurrentUserVariables;
    return firstName == otherTyped.firstName && 
    lastName == otherTyped.lastName && 
    phoneNumber == otherTyped.phoneNumber && 
    userRole == otherTyped.userRole && 
    street == otherTyped.street && 
    postalCodeId == otherTyped.postalCodeId;
    
  }
  @override
  int get hashCode => Object.hashAll([firstName.hashCode, lastName.hashCode, phoneNumber.hashCode, userRole.hashCode, street.hashCode, postalCodeId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(firstName.state == OptionalState.set) {
      json['firstName'] = firstName.toJson();
    }
    if(lastName.state == OptionalState.set) {
      json['lastName'] = lastName.toJson();
    }
    if(phoneNumber.state == OptionalState.set) {
      json['phoneNumber'] = phoneNumber.toJson();
    }
    json['userRole'] = nativeToJson<String>(userRole);
    if(street.state == OptionalState.set) {
      json['street'] = street.toJson();
    }
    if(postalCodeId.state == OptionalState.set) {
      json['postalCodeId'] = postalCodeId.toJson();
    }
    return json;
  }

  CreateCurrentUserVariables({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.userRole,
    required this.street,
    required this.postalCodeId,
  });
}

