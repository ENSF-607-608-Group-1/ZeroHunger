part of 'zerohunger.dart';

class GetPostalCodeByCodeVariablesBuilder {
  String code;

  final FirebaseDataConnect _dataConnect;
  GetPostalCodeByCodeVariablesBuilder(this._dataConnect, {required  this.code,});
  Deserializer<GetPostalCodeByCodeData> dataDeserializer = (dynamic json)  => GetPostalCodeByCodeData.fromJson(jsonDecode(json));
  Serializer<GetPostalCodeByCodeVariables> varsSerializer = (GetPostalCodeByCodeVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetPostalCodeByCodeData, GetPostalCodeByCodeVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetPostalCodeByCodeData, GetPostalCodeByCodeVariables> ref() {
    GetPostalCodeByCodeVariables vars= GetPostalCodeByCodeVariables(code: code,);
    return _dataConnect.query("GetPostalCodeByCode", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetPostalCodeByCodePostalCodes {
  final BigInt postalCodeId;
  final String code;
  final String? city;
  final String? province;
  GetPostalCodeByCodePostalCodes.fromJson(dynamic json):
  
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

    final GetPostalCodeByCodePostalCodes otherTyped = other as GetPostalCodeByCodePostalCodes;
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

  GetPostalCodeByCodePostalCodes({
    required this.postalCodeId,
    required this.code,
    this.city,
    this.province,
  });
}

@immutable
class GetPostalCodeByCodeData {
  final List<GetPostalCodeByCodePostalCodes> postalCodes;
  GetPostalCodeByCodeData.fromJson(dynamic json):
  
  postalCodes = (json['postalCodes'] as List<dynamic>)
        .map((e) => GetPostalCodeByCodePostalCodes.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPostalCodeByCodeData otherTyped = other as GetPostalCodeByCodeData;
    return postalCodes == otherTyped.postalCodes;
    
  }
  @override
  int get hashCode => postalCodes.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['postalCodes'] = postalCodes.map((e) => e.toJson()).toList();
    return json;
  }

  GetPostalCodeByCodeData({
    required this.postalCodes,
  });
}

@immutable
class GetPostalCodeByCodeVariables {
  final String code;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetPostalCodeByCodeVariables.fromJson(Map<String, dynamic> json):
  
  code = nativeFromJson<String>(json['code']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPostalCodeByCodeVariables otherTyped = other as GetPostalCodeByCodeVariables;
    return code == otherTyped.code;
    
  }
  @override
  int get hashCode => code.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['code'] = nativeToJson<String>(code);
    return json;
  }

  GetPostalCodeByCodeVariables({
    required this.code,
  });
}

