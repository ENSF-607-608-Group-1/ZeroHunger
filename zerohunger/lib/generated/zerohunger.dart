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

part 'create_donation.dart';

part 'get_current_user.dart';

part 'get_postal_code_by_code.dart';

part 'get_organization_by_primary_email.dart';

part 'create_postal_code.dart';

part 'create_current_user.dart';

part 'update_current_user.dart';

part 'update_current_user_role.dart';

part 'create_organization.dart';

part 'link_user_to_organization.dart';

part 'create_location.dart';

part 'create_user_preferences.dart';


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
  
  
  CreateDonationVariablesBuilder createDonation ({required String donationTitle, required String pickupTime, required BigInt itemQuantities, required BigInt statusId, }) {
    return CreateDonationVariablesBuilder(dataConnect, donationTitle: donationTitle,pickupTime: pickupTime,itemQuantities: itemQuantities,statusId: statusId,);
  }
  
  
  GetCurrentUserVariablesBuilder getCurrentUser () {
    return GetCurrentUserVariablesBuilder(dataConnect, );
  }
  
  
  GetPostalCodeByCodeVariablesBuilder getPostalCodeByCode ({required String code, }) {
    return GetPostalCodeByCodeVariablesBuilder(dataConnect, code: code,);
  }
  
  
  GetOrganizationByPrimaryEmailVariablesBuilder getOrganizationByPrimaryEmail ({required String orgPrimaryEmail, }) {
    return GetOrganizationByPrimaryEmailVariablesBuilder(dataConnect, orgPrimaryEmail: orgPrimaryEmail,);
  }
  
  
  CreatePostalCodeVariablesBuilder createPostalCode ({required String code, }) {
    return CreatePostalCodeVariablesBuilder(dataConnect, code: code,);
  }
  
  
  CreateCurrentUserVariablesBuilder createCurrentUser ({required String userRole, }) {
    return CreateCurrentUserVariablesBuilder(dataConnect, userRole: userRole,);
  }
  
  
  UpdateCurrentUserVariablesBuilder updateCurrentUser () {
    return UpdateCurrentUserVariablesBuilder(dataConnect, );
  }
  
  
  UpdateCurrentUserRoleVariablesBuilder updateCurrentUserRole ({required String userRole, }) {
    return UpdateCurrentUserRoleVariablesBuilder(dataConnect, userRole: userRole,);
  }
  
  
  CreateOrganizationVariablesBuilder createOrganization ({required String orgName, required String orgPrimaryEmail, }) {
    return CreateOrganizationVariablesBuilder(dataConnect, orgName: orgName,orgPrimaryEmail: orgPrimaryEmail,);
  }
  
  
  LinkUserToOrganizationVariablesBuilder linkUserToOrganization ({required BigInt userId, required BigInt orgId, required String memberRole, }) {
    return LinkUserToOrganizationVariablesBuilder(dataConnect, userId: userId,orgId: orgId,memberRole: memberRole,);
  }
  
  
  CreateLocationVariablesBuilder createLocation ({required String street, required BigInt postalCodeId, }) {
    return CreateLocationVariablesBuilder(dataConnect, street: street,postalCodeId: postalCodeId,);
  }
  
  
  CreateUserPreferencesVariablesBuilder createUserPreferences ({required BigInt userId, }) {
    return CreateUserPreferencesVariablesBuilder(dataConnect, userId: userId,);
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
