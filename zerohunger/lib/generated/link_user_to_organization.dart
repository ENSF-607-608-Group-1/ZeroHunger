part of 'zerohunger.dart';

class LinkUserToOrganizationVariablesBuilder {
  BigInt userId;
  BigInt orgId;
  String memberRole;

  final FirebaseDataConnect _dataConnect;
  LinkUserToOrganizationVariablesBuilder(this._dataConnect, {required  this.userId,required  this.orgId,required  this.memberRole,});
  Deserializer<LinkUserToOrganizationData> dataDeserializer = (dynamic json)  => LinkUserToOrganizationData.fromJson(jsonDecode(json));
  Serializer<LinkUserToOrganizationVariables> varsSerializer = (LinkUserToOrganizationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<LinkUserToOrganizationData, LinkUserToOrganizationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<LinkUserToOrganizationData, LinkUserToOrganizationVariables> ref() {
    LinkUserToOrganizationVariables vars= LinkUserToOrganizationVariables(userId: userId,orgId: orgId,memberRole: memberRole,);
    return _dataConnect.mutation("LinkUserToOrganization", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class LinkUserToOrganizationUserOrganizationUpsert {
  final BigInt userUserId;
  final BigInt organizationOrgId;
  LinkUserToOrganizationUserOrganizationUpsert.fromJson(dynamic json):
  
  userUserId = bigIntFromJson(json['userUserId']),
  organizationOrgId = bigIntFromJson(json['organizationOrgId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LinkUserToOrganizationUserOrganizationUpsert otherTyped = other as LinkUserToOrganizationUserOrganizationUpsert;
    return userUserId == otherTyped.userUserId && 
    organizationOrgId == otherTyped.organizationOrgId;
    
  }
  @override
  int get hashCode => Object.hashAll([userUserId.hashCode, organizationOrgId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userUserId'] = bigIntToJson(userUserId);
    json['organizationOrgId'] = bigIntToJson(organizationOrgId);
    return json;
  }

  LinkUserToOrganizationUserOrganizationUpsert({
    required this.userUserId,
    required this.organizationOrgId,
  });
}

@immutable
class LinkUserToOrganizationData {
  final LinkUserToOrganizationUserOrganizationUpsert userOrganization_upsert;
  LinkUserToOrganizationData.fromJson(dynamic json):
  
  userOrganization_upsert = LinkUserToOrganizationUserOrganizationUpsert.fromJson(json['userOrganization_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LinkUserToOrganizationData otherTyped = other as LinkUserToOrganizationData;
    return userOrganization_upsert == otherTyped.userOrganization_upsert;
    
  }
  @override
  int get hashCode => userOrganization_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userOrganization_upsert'] = userOrganization_upsert.toJson();
    return json;
  }

  LinkUserToOrganizationData({
    required this.userOrganization_upsert,
  });
}

@immutable
class LinkUserToOrganizationVariables {
  final BigInt userId;
  final BigInt orgId;
  final String memberRole;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  LinkUserToOrganizationVariables.fromJson(Map<String, dynamic> json):
  
  userId = bigIntFromJson(json['userId']),
  orgId = bigIntFromJson(json['orgId']),
  memberRole = nativeFromJson<String>(json['memberRole']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LinkUserToOrganizationVariables otherTyped = other as LinkUserToOrganizationVariables;
    return userId == otherTyped.userId && 
    orgId == otherTyped.orgId && 
    memberRole == otherTyped.memberRole;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, orgId.hashCode, memberRole.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = bigIntToJson(userId);
    json['orgId'] = bigIntToJson(orgId);
    json['memberRole'] = nativeToJson<String>(memberRole);
    return json;
  }

  LinkUserToOrganizationVariables({
    required this.userId,
    required this.orgId,
    required this.memberRole,
  });
}

