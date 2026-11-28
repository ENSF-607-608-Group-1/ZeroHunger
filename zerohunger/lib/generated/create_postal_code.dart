part of 'zerohunger.dart';

class CreatePostalCodeVariablesBuilder {
  String code;
  Optional<String> _city = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _province = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreatePostalCodeVariablesBuilder city(String? t) {
   _city.value = t;
   return this;
  }
  CreatePostalCodeVariablesBuilder province(String? t) {
   _province.value = t;
   return this;
  }

  CreatePostalCodeVariablesBuilder(this._dataConnect, {required  this.code,});
  Deserializer<CreatePostalCodeData> dataDeserializer = (dynamic json)  => CreatePostalCodeData.fromJson(jsonDecode(json));
  Serializer<CreatePostalCodeVariables> varsSerializer = (CreatePostalCodeVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreatePostalCodeData, CreatePostalCodeVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreatePostalCodeData, CreatePostalCodeVariables> ref() {
    CreatePostalCodeVariables vars= CreatePostalCodeVariables(code: code,city: _city,province: _province,);
    return _dataConnect.mutation("CreatePostalCode", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreatePostalCodePostalCodeInsert {
  final BigInt postalCodeId;
  CreatePostalCodePostalCodeInsert.fromJson(dynamic json):
  
  postalCodeId = bigIntFromJson(json['postalCodeId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreatePostalCodePostalCodeInsert otherTyped = other as CreatePostalCodePostalCodeInsert;
    return postalCodeId == otherTyped.postalCodeId;
    
  }
  @override
  int get hashCode => postalCodeId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['postalCodeId'] = bigIntToJson(postalCodeId);
    return json;
  }

  CreatePostalCodePostalCodeInsert({
    required this.postalCodeId,
  });
}

@immutable
class CreatePostalCodeData {
  final CreatePostalCodePostalCodeInsert postalCode_insert;
  CreatePostalCodeData.fromJson(dynamic json):
  
  postalCode_insert = CreatePostalCodePostalCodeInsert.fromJson(json['postalCode_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreatePostalCodeData otherTyped = other as CreatePostalCodeData;
    return postalCode_insert == otherTyped.postalCode_insert;
    
  }
  @override
  int get hashCode => postalCode_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['postalCode_insert'] = postalCode_insert.toJson();
    return json;
  }

  CreatePostalCodeData({
    required this.postalCode_insert,
  });
}

@immutable
class CreatePostalCodeVariables {
  final String code;
  late final Optional<String>city;
  late final Optional<String>province;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreatePostalCodeVariables.fromJson(Map<String, dynamic> json):
  
  code = nativeFromJson<String>(json['code']) {
  
  
  
    city = Optional.optional(nativeFromJson, nativeToJson);
    city.value = json['city'] == null ? null : nativeFromJson<String>(json['city']);
  
  
    province = Optional.optional(nativeFromJson, nativeToJson);
    province.value = json['province'] == null ? null : nativeFromJson<String>(json['province']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreatePostalCodeVariables otherTyped = other as CreatePostalCodeVariables;
    return code == otherTyped.code && 
    city == otherTyped.city && 
    province == otherTyped.province;
    
  }
  @override
  int get hashCode => Object.hashAll([code.hashCode, city.hashCode, province.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['code'] = nativeToJson<String>(code);
    if(city.state == OptionalState.set) {
      json['city'] = city.toJson();
    }
    if(province.state == OptionalState.set) {
      json['province'] = province.toJson();
    }
    return json;
  }

  CreatePostalCodeVariables({
    required this.code,
    required this.city,
    required this.province,
  });
}

