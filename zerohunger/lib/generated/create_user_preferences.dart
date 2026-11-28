part of 'zerohunger.dart';

class CreateUserPreferencesVariablesBuilder {
  BigInt userId;
  Optional<int> _radiusSearch = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _notificationPreference = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _alertSetting = Optional.optional(nativeFromJson, nativeToJson);
  Optional<BigInt> _locationId = Optional.optional(bigIntFromJson, bigIntToJson);

  final FirebaseDataConnect _dataConnect;  CreateUserPreferencesVariablesBuilder radiusSearch(int? t) {
   _radiusSearch.value = t;
   return this;
  }
  CreateUserPreferencesVariablesBuilder notificationPreference(String? t) {
   _notificationPreference.value = t;
   return this;
  }
  CreateUserPreferencesVariablesBuilder alertSetting(String? t) {
   _alertSetting.value = t;
   return this;
  }
  CreateUserPreferencesVariablesBuilder locationId(BigInt? t) {
   _locationId.value = t;
   return this;
  }

  CreateUserPreferencesVariablesBuilder(this._dataConnect, {required  this.userId,});
  Deserializer<CreateUserPreferencesData> dataDeserializer = (dynamic json)  => CreateUserPreferencesData.fromJson(jsonDecode(json));
  Serializer<CreateUserPreferencesVariables> varsSerializer = (CreateUserPreferencesVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateUserPreferencesData, CreateUserPreferencesVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateUserPreferencesData, CreateUserPreferencesVariables> ref() {
    CreateUserPreferencesVariables vars= CreateUserPreferencesVariables(userId: userId,radiusSearch: _radiusSearch,notificationPreference: _notificationPreference,alertSetting: _alertSetting,locationId: _locationId,);
    return _dataConnect.mutation("CreateUserPreferences", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateUserPreferencesUserPreferencesInsert {
  final BigInt profileId;
  CreateUserPreferencesUserPreferencesInsert.fromJson(dynamic json):
  
  profileId = bigIntFromJson(json['profileId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserPreferencesUserPreferencesInsert otherTyped = other as CreateUserPreferencesUserPreferencesInsert;
    return profileId == otherTyped.profileId;
    
  }
  @override
  int get hashCode => profileId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['profileId'] = bigIntToJson(profileId);
    return json;
  }

  CreateUserPreferencesUserPreferencesInsert({
    required this.profileId,
  });
}

@immutable
class CreateUserPreferencesData {
  final CreateUserPreferencesUserPreferencesInsert userPreferences_insert;
  CreateUserPreferencesData.fromJson(dynamic json):
  
  userPreferences_insert = CreateUserPreferencesUserPreferencesInsert.fromJson(json['userPreferences_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserPreferencesData otherTyped = other as CreateUserPreferencesData;
    return userPreferences_insert == otherTyped.userPreferences_insert;
    
  }
  @override
  int get hashCode => userPreferences_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userPreferences_insert'] = userPreferences_insert.toJson();
    return json;
  }

  CreateUserPreferencesData({
    required this.userPreferences_insert,
  });
}

@immutable
class CreateUserPreferencesVariables {
  final BigInt userId;
  late final Optional<int>radiusSearch;
  late final Optional<String>notificationPreference;
  late final Optional<String>alertSetting;
  late final Optional<BigInt>locationId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateUserPreferencesVariables.fromJson(Map<String, dynamic> json):
  
  userId = bigIntFromJson(json['userId']) {
  
  
  
    radiusSearch = Optional.optional(nativeFromJson, nativeToJson);
    radiusSearch.value = json['radiusSearch'] == null ? null : nativeFromJson<int>(json['radiusSearch']);
  
  
    notificationPreference = Optional.optional(nativeFromJson, nativeToJson);
    notificationPreference.value = json['notificationPreference'] == null ? null : nativeFromJson<String>(json['notificationPreference']);
  
  
    alertSetting = Optional.optional(nativeFromJson, nativeToJson);
    alertSetting.value = json['alertSetting'] == null ? null : nativeFromJson<String>(json['alertSetting']);
  
  
    locationId = Optional.optional(bigIntFromJson, bigIntToJson);
    locationId.value = json['locationId'] == null ? null : bigIntFromJson(json['locationId']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserPreferencesVariables otherTyped = other as CreateUserPreferencesVariables;
    return userId == otherTyped.userId && 
    radiusSearch == otherTyped.radiusSearch && 
    notificationPreference == otherTyped.notificationPreference && 
    alertSetting == otherTyped.alertSetting && 
    locationId == otherTyped.locationId;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, radiusSearch.hashCode, notificationPreference.hashCode, alertSetting.hashCode, locationId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = bigIntToJson(userId);
    if(radiusSearch.state == OptionalState.set) {
      json['radiusSearch'] = radiusSearch.toJson();
    }
    if(notificationPreference.state == OptionalState.set) {
      json['notificationPreference'] = notificationPreference.toJson();
    }
    if(alertSetting.state == OptionalState.set) {
      json['alertSetting'] = alertSetting.toJson();
    }
    if(locationId.state == OptionalState.set) {
      json['locationId'] = locationId.toJson();
    }
    return json;
  }

  CreateUserPreferencesVariables({
    required this.userId,
    required this.radiusSearch,
    required this.notificationPreference,
    required this.alertSetting,
    required this.locationId,
  });
}

