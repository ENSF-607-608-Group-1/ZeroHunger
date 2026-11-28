# Basic Usage

```dart
ZerohungerConnector.instance.ListAvailableDonations().execute();
ZerohungerConnector.instance.ListDonationStatuses().execute();
ZerohungerConnector.instance.ListDistributionEvents(listDistributionEventsVariables).execute();
ZerohungerConnector.instance.ListOrganizations().execute();
ZerohungerConnector.instance.ListFoodCategories().execute();
ZerohungerConnector.instance.ListAllergens().execute();
ZerohungerConnector.instance.ListMyActivity().execute();
ZerohungerConnector.instance.CreateDonation(createDonationVariables).execute();
ZerohungerConnector.instance.GetCurrentUser().execute();
ZerohungerConnector.instance.CreateCurrentUser(createCurrentUserVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await ZerohungerConnector.instance.CreateCurrentUser({ ... })
.firstName(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

