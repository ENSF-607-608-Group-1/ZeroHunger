part of 'zerohunger.dart';

class UpdateCurrentUserRoleVariablesBuilder {
  String userRole;

  final FirebaseDataConnect _dataConnect;
  UpdateCurrentUserRoleVariablesBuilder(this._dataConnect, {required  this.userRole,});
  Deserializer<UpdateCurrentUserRoleData> dataDeserializer = (dynamic json)  => UpdateCurrentUserRoleData.fromJson(jsonDecode(json));
  Serializer<UpdateCurrentUserRoleVariables> varsSerializer = (UpdateCurrentUserRoleVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateCurrentUserRoleData, UpdateCurrentUserRoleVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateCurrentUserRoleData, UpdateCurrentUserRoleVariables> ref() {
    UpdateCurrentUserRoleVariables vars= UpdateCurrentUserRoleVariables(userRole: userRole,);
    return _dataConnect.mutation("UpdateCurrentUserRole", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateCurrentUserRoleUserUpdate {
  final BigInt userId;
  UpdateCurrentUserRoleUserUpdate.fromJson(dynamic json):
  
  userId = bigIntFromJson(json['userId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserRoleUserUpdate otherTyped = other as UpdateCurrentUserRoleUserUpdate;
    return userId == otherTyped.userId;
    
  }
  @override
  int get hashCode => userId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = bigIntToJson(userId);
    return json;
  }

  UpdateCurrentUserRoleUserUpdate({
    required this.userId,
  });
}

@immutable
class UpdateCurrentUserRoleData {
  final UpdateCurrentUserRoleUserUpdate? user_update;
  UpdateCurrentUserRoleData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateCurrentUserRoleUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserRoleData otherTyped = other as UpdateCurrentUserRoleData;
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

  UpdateCurrentUserRoleData({
    this.user_update,
  });
}

@immutable
class UpdateCurrentUserRoleVariables {
  final String userRole;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateCurrentUserRoleVariables.fromJson(Map<String, dynamic> json):
  
  userRole = nativeFromJson<String>(json['userRole']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserRoleVariables otherTyped = other as UpdateCurrentUserRoleVariables;
    return userRole == otherTyped.userRole;
    
  }
  @override
  int get hashCode => userRole.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userRole'] = nativeToJson<String>(userRole);
    return json;
  }

  UpdateCurrentUserRoleVariables({
    required this.userRole,
  });
}

