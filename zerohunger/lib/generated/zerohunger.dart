library zerohunger_data_connector;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'list_available_donations.dart';

part 'list_donation_statuses.dart';

part 'list_distribution_events.dart';

part 'list_organizations.dart';

part 'list_food_categories.dart';

part 'list_allergens.dart';

part 'list_my_activity.dart';

part 'create_donation.dart';

part 'get_current_user.dart';

part 'create_current_user.dart';

part 'update_current_user_role.dart';


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
  
  
  ListDonationStatusesVariablesBuilder listDonationStatuses () {
    return ListDonationStatusesVariablesBuilder(dataConnect, );
  }
  
  
  ListDistributionEventsVariablesBuilder listDistributionEvents ({required Timestamp asOf, }) {
    return ListDistributionEventsVariablesBuilder(dataConnect, asOf: asOf,);
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
  
  
  ListMyActivityVariablesBuilder listMyActivity () {
    return ListMyActivityVariablesBuilder(dataConnect, );
  }
  
  
  CreateDonationVariablesBuilder createDonation ({required String donationTitle, required String pickupTime, required BigInt itemQuantities, required BigInt statusId, }) {
    return CreateDonationVariablesBuilder(dataConnect, donationTitle: donationTitle,pickupTime: pickupTime,itemQuantities: itemQuantities,statusId: statusId,);
  }
  
  
  GetCurrentUserVariablesBuilder getCurrentUser () {
    return GetCurrentUserVariablesBuilder(dataConnect, );
  }
  
  
  CreateCurrentUserVariablesBuilder createCurrentUser () {
    return CreateCurrentUserVariablesBuilder(dataConnect, );
  }
  
  
  UpdateCurrentUserRoleVariablesBuilder updateCurrentUserRole ({required String userRole, }) {
    return UpdateCurrentUserRoleVariablesBuilder(dataConnect, userRole: userRole,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'zerohunger',
    'zerohunger-bbd36-service-2',
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
