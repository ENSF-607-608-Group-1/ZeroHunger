part of 'zerohunger.dart';

class ListFoodCategoriesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListFoodCategoriesVariablesBuilder(this._dataConnect, );
  Deserializer<ListFoodCategoriesData> dataDeserializer = (dynamic json)  => ListFoodCategoriesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListFoodCategoriesData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListFoodCategoriesData, void> ref() {
    
    return _dataConnect.query("ListFoodCategories", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListFoodCategoriesFoodCategories {
  final BigInt categoryId;
  final String categoryName;
  final String? description;
  ListFoodCategoriesFoodCategories.fromJson(dynamic json):
  
  categoryId = bigIntFromJson(json['categoryId']),
  categoryName = nativeFromJson<String>(json['categoryName']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListFoodCategoriesFoodCategories otherTyped = other as ListFoodCategoriesFoodCategories;
    return categoryId == otherTyped.categoryId && 
    categoryName == otherTyped.categoryName && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll([categoryId.hashCode, categoryName.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['categoryId'] = bigIntToJson(categoryId);
    json['categoryName'] = nativeToJson<String>(categoryName);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    return json;
  }

  ListFoodCategoriesFoodCategories({
    required this.categoryId,
    required this.categoryName,
    this.description,
  });
}

@immutable
class ListFoodCategoriesData {
  final List<ListFoodCategoriesFoodCategories> foodCategories;
  ListFoodCategoriesData.fromJson(dynamic json):
  
  foodCategories = (json['foodCategories'] as List<dynamic>)
        .map((e) => ListFoodCategoriesFoodCategories.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListFoodCategoriesData otherTyped = other as ListFoodCategoriesData;
    return foodCategories == otherTyped.foodCategories;
    
  }
  @override
  int get hashCode => foodCategories.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['foodCategories'] = foodCategories.map((e) => e.toJson()).toList();
    return json;
  }

  ListFoodCategoriesData({
    required this.foodCategories,
  });
}

