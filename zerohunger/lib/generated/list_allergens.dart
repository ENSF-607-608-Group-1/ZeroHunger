part of 'zerohunger.dart';

class ListAllergensVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListAllergensVariablesBuilder(this._dataConnect, );
  Deserializer<ListAllergensData> dataDeserializer = (dynamic json)  => ListAllergensData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListAllergensData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListAllergensData, void> ref() {
    
    return _dataConnect.query("ListAllergens", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListAllergensAllergens {
  final BigInt allergenId;
  final String name;
  final String? description;
  ListAllergensAllergens.fromJson(dynamic json):
  
  allergenId = bigIntFromJson(json['allergenId']),
  name = nativeFromJson<String>(json['name']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllergensAllergens otherTyped = other as ListAllergensAllergens;
    return allergenId == otherTyped.allergenId && 
    name == otherTyped.name && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll([allergenId.hashCode, name.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['allergenId'] = bigIntToJson(allergenId);
    json['name'] = nativeToJson<String>(name);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    return json;
  }

  ListAllergensAllergens({
    required this.allergenId,
    required this.name,
    this.description,
  });
}

@immutable
class ListAllergensData {
  final List<ListAllergensAllergens> allergens;
  ListAllergensData.fromJson(dynamic json):
  
  allergens = (json['allergens'] as List<dynamic>)
        .map((e) => ListAllergensAllergens.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllergensData otherTyped = other as ListAllergensData;
    return allergens == otherTyped.allergens;
    
  }
  @override
  int get hashCode => allergens.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['allergens'] = allergens.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllergensData({
    required this.allergens,
  });
}

