part of 'zerohunger.dart';

class UpdateCurrentUserVariablesBuilder {
  Optional<String> _firstName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _lastName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _phoneNumber = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _userRole = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _street = Optional.optional(nativeFromJson, nativeToJson);
  Optional<BigInt> _postalCodeId = Optional.optional(bigIntFromJson, bigIntToJson);

  final FirebaseDataConnect _dataConnect;
  UpdateCurrentUserVariablesBuilder firstName(String? t) {
   _firstName.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder lastName(String? t) {
   _lastName.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder phoneNumber(String? t) {
   _phoneNumber.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder userRole(String? t) {
   _userRole.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder street(String? t) {
   _street.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder postalCodeId(BigInt? t) {
   _postalCodeId.value = t;
   return this;
  }

  UpdateCurrentUserVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateCurrentUserData> dataDeserializer = (dynamic json)  => UpdateCurrentUserData.fromJson(jsonDecode(json));
  Serializer<UpdateCurrentUserVariables> varsSerializer = (UpdateCurrentUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateCurrentUserData, UpdateCurrentUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateCurrentUserData, UpdateCurrentUserVariables> ref() {
    UpdateCurrentUserVariables vars= UpdateCurrentUserVariables(firstName: _firstName,lastName: _lastName,phoneNumber: _phoneNumber,userRole: _userRole,street: _street,postalCodeId: _postalCodeId,);
    return _dataConnect.mutation("UpdateCurrentUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateCurrentUserUserUpdate {
  final BigInt userId;
  UpdateCurrentUserUserUpdate.fromJson(dynamic json):
  
  userId = bigIntFromJson(json['userId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserUserUpdate otherTyped = other as UpdateCurrentUserUserUpdate;
    return userId == otherTyped.userId;
    
  }
  @override
  int get hashCode => userId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = bigIntToJson(userId);
    return json;
  }

  UpdateCurrentUserUserUpdate({
    required this.userId,
  });
}

@immutable
class UpdateCurrentUserData {
  final UpdateCurrentUserUserUpdate? user_update;
  UpdateCurrentUserData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateCurrentUserUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserData otherTyped = other as UpdateCurrentUserData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateCurrentUserData({
    this.user_update,
  });
}

@immutable
class UpdateCurrentUserVariables {
  late final Optional<String>firstName;
  late final Optional<String>lastName;
  late final Optional<String>phoneNumber;
  late final Optional<String>userRole;
  late final Optional<String>street;
  late final Optional<BigInt>postalCodeId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateCurrentUserVariables.fromJson(Map<String, dynamic> json) {
  
  
    firstName = Optional.optional(nativeFromJson, nativeToJson);
    firstName.value = json['firstName'] == null ? null : nativeFromJson<String>(json['firstName']);
  
  
    lastName = Optional.optional(nativeFromJson, nativeToJson);
    lastName.value = json['lastName'] == null ? null : nativeFromJson<String>(json['lastName']);
  
  
    phoneNumber = Optional.optional(nativeFromJson, nativeToJson);
    phoneNumber.value = json['phoneNumber'] == null ? null : nativeFromJson<String>(json['phoneNumber']);
  
  
    userRole = Optional.optional(nativeFromJson, nativeToJson);
    userRole.value = json['userRole'] == null ? null : nativeFromJson<String>(json['userRole']);
  
  
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

    final UpdateCurrentUserVariables otherTyped = other as UpdateCurrentUserVariables;
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
    if(userRole.state == OptionalState.set) {
      json['userRole'] = userRole.toJson();
    }
    if(street.state == OptionalState.set) {
      json['street'] = street.toJson();
    }
    if(postalCodeId.state == OptionalState.set) {
      json['postalCodeId'] = postalCodeId.toJson();
    }
    return json;
  }

  UpdateCurrentUserVariables({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.userRole,
    required this.street,
    required this.postalCodeId,
  });
}

