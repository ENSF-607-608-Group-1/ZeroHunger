part of 'zerohunger.dart';

class CreateCurrentUserVariablesBuilder {
  Optional<String> _firstName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _lastName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _phoneNumber = Optional.optional(nativeFromJson, nativeToJson);

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

  CreateCurrentUserVariablesBuilder(this._dataConnect, );
  Deserializer<CreateCurrentUserData> dataDeserializer = (dynamic json)  => CreateCurrentUserData.fromJson(jsonDecode(json));
  Serializer<CreateCurrentUserVariables> varsSerializer = (CreateCurrentUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateCurrentUserData, CreateCurrentUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateCurrentUserData, CreateCurrentUserVariables> ref() {
    CreateCurrentUserVariables vars= CreateCurrentUserVariables(firstName: _firstName,lastName: _lastName,phoneNumber: _phoneNumber,);
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
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateCurrentUserVariables.fromJson(Map<String, dynamic> json) {
  
  
    firstName = Optional.optional(nativeFromJson, nativeToJson);
    firstName.value = json['firstName'] == null ? null : nativeFromJson<String>(json['firstName']);
  
  
    lastName = Optional.optional(nativeFromJson, nativeToJson);
    lastName.value = json['lastName'] == null ? null : nativeFromJson<String>(json['lastName']);
  
  
    phoneNumber = Optional.optional(nativeFromJson, nativeToJson);
    phoneNumber.value = json['phoneNumber'] == null ? null : nativeFromJson<String>(json['phoneNumber']);
  
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
    phoneNumber == otherTyped.phoneNumber;
    
  }
  @override
  int get hashCode => Object.hashAll([firstName.hashCode, lastName.hashCode, phoneNumber.hashCode]);
  

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
    return json;
  }

  CreateCurrentUserVariables({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  });
}

