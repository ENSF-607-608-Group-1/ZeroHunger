library zerohunger_data_connect;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'list_available_donations.dart';

part 'list_organizations.dart';

part 'list_food_categories.dart';

part 'list_allergens.dart';

part 'get_current_user.dart';

part 'create_current_user.dart';


String? bigIntToJson(BigInt? value) {
  return value?.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}






class ZerohungerConnector {
  
  
  ListAvailableDonationsVariablesBuilder listAvailableDonations () {
    return ListAvailableDonationsVariablesBuilder(dataConnect, );
  }
  
  
  ListOrganizationsVariablesBuilder listOrganizations () {
    return ListOrganizationsVariablesBuilder(dataConnect, );
  }
  
  
  ListFoodCategoriesVariablesBuilder listFoodCategories () {
    return ListFoodCategoriesVariablesBuilder(dataConnect, );
  }
  
  
  ListAllergensVariablesBuilder listAllergens () {
    return ListAllergensVariablesBuilder(dataConnect, );
  }
  
  
  GetCurrentUserVariablesBuilder getCurrentUser () {
    return GetCurrentUserVariablesBuilder(dataConnect, );
  }
  
  
  CreateCurrentUserVariablesBuilder createCurrentUser () {
    return CreateCurrentUserVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'zerohunger',
    'zerohunger-bbd36-service',
  );

  ZerohungerConnector({required this.dataConnect});
  static ZerohungerConnector get instance {
    
    return ZerohungerConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
