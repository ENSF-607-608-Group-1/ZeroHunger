# zerohunger_data_connector SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ZerohungerConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### ListAvailableDonations
#### Required Arguments
```dart
// No required arguments
ZerohungerConnector.instance.listAvailableDonations().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAvailableDonationsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.listAvailableDonations();
ListAvailableDonationsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ZerohungerConnector.instance.listAvailableDonations().ref();
ref.execute();

ref.subscribe(...);
```


### ListDonationStatuses
#### Required Arguments
```dart
// No required arguments
ZerohungerConnector.instance.listDonationStatuses().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListDonationStatusesData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.listDonationStatuses();
ListDonationStatusesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ZerohungerConnector.instance.listDonationStatuses().ref();
ref.execute();

ref.subscribe(...);
```


### ListDistributionEvents
#### Required Arguments
```dart
Timestamp asOf = ...;
ZerohungerConnector.instance.listDistributionEvents(
  asOf: asOf,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListDistributionEventsData, ListDistributionEventsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.listDistributionEvents(
  asOf: asOf,
);
ListDistributionEventsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
Timestamp asOf = ...;

final ref = ZerohungerConnector.instance.listDistributionEvents(
  asOf: asOf,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListOrganizations
#### Required Arguments
```dart
// No required arguments
ZerohungerConnector.instance.listOrganizations().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListOrganizationsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.listOrganizations();
ListOrganizationsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ZerohungerConnector.instance.listOrganizations().ref();
ref.execute();

ref.subscribe(...);
```


### ListFoodCategories
#### Required Arguments
```dart
// No required arguments
ZerohungerConnector.instance.listFoodCategories().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListFoodCategoriesData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.listFoodCategories();
ListFoodCategoriesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ZerohungerConnector.instance.listFoodCategories().ref();
ref.execute();

ref.subscribe(...);
```


### ListAllergens
#### Required Arguments
```dart
// No required arguments
ZerohungerConnector.instance.listAllergens().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAllergensData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.listAllergens();
ListAllergensData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ZerohungerConnector.instance.listAllergens().ref();
ref.execute();

ref.subscribe(...);
```


### ListMyActivity
#### Required Arguments
```dart
// No required arguments
ZerohungerConnector.instance.listMyActivity().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListMyActivityData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.listMyActivity();
ListMyActivityData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ZerohungerConnector.instance.listMyActivity().ref();
ref.execute();

ref.subscribe(...);
```


### GetCurrentUser
#### Required Arguments
```dart
// No required arguments
ZerohungerConnector.instance.getCurrentUser().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetCurrentUserData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.getCurrentUser();
GetCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ZerohungerConnector.instance.getCurrentUser().ref();
ref.execute();

ref.subscribe(...);
```


### GetPostalCodeByCode
#### Required Arguments
```dart
String code = ...;
ZerohungerConnector.instance.getPostalCodeByCode(
  code: code,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetPostalCodeByCodeData, GetPostalCodeByCodeVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.getPostalCodeByCode(
  code: code,
);
GetPostalCodeByCodeData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String code = ...;

final ref = ZerohungerConnector.instance.getPostalCodeByCode(
  code: code,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetOrganizationByPrimaryEmail
#### Required Arguments
```dart
String orgPrimaryEmail = ...;
ZerohungerConnector.instance.getOrganizationByPrimaryEmail(
  orgPrimaryEmail: orgPrimaryEmail,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetOrganizationByPrimaryEmailData, GetOrganizationByPrimaryEmailVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ZerohungerConnector.instance.getOrganizationByPrimaryEmail(
  orgPrimaryEmail: orgPrimaryEmail,
);
GetOrganizationByPrimaryEmailData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgPrimaryEmail = ...;

final ref = ZerohungerConnector.instance.getOrganizationByPrimaryEmail(
  orgPrimaryEmail: orgPrimaryEmail,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateDonation
#### Required Arguments
```dart
String donationTitle = ...;
String pickupTime = ...;
BigInt itemQuantities = ...;
BigInt statusId = ...;
ZerohungerConnector.instance.createDonation(
  donationTitle: donationTitle,
  pickupTime: pickupTime,
  itemQuantities: itemQuantities,
  statusId: statusId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateDonation, we created `CreateDonationBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateDonationVariablesBuilder {
  ...
 
  CreateDonationVariablesBuilder donationId(String? t) {
   _donationId.value = t;
   return this;
  }
  CreateDonationVariablesBuilder eventId(BigInt? t) {
   _eventId.value = t;
   return this;
  }

  ...
}
ZerohungerConnector.instance.createDonation(
  donationTitle: donationTitle,
  pickupTime: pickupTime,
  itemQuantities: itemQuantities,
  statusId: statusId,
)
.donationId(donationId)
.eventId(eventId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateDonationData, CreateDonationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.createDonation(
  donationTitle: donationTitle,
  pickupTime: pickupTime,
  itemQuantities: itemQuantities,
  statusId: statusId,
);
CreateDonationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String donationTitle = ...;
String pickupTime = ...;
BigInt itemQuantities = ...;
BigInt statusId = ...;

final ref = ZerohungerConnector.instance.createDonation(
  donationTitle: donationTitle,
  pickupTime: pickupTime,
  itemQuantities: itemQuantities,
  statusId: statusId,
).ref();
ref.execute();
```


### CreatePostalCode
#### Required Arguments
```dart
String code = ...;
ZerohungerConnector.instance.createPostalCode(
  code: code,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreatePostalCode, we created `CreatePostalCodeBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreatePostalCodeVariablesBuilder {
  ...
   CreatePostalCodeVariablesBuilder city(String? t) {
   _city.value = t;
   return this;
  }
  CreatePostalCodeVariablesBuilder province(String? t) {
   _province.value = t;
   return this;
  }

  ...
}
ZerohungerConnector.instance.createPostalCode(
  code: code,
)
.city(city)
.province(province)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreatePostalCodeData, CreatePostalCodeVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.createPostalCode(
  code: code,
);
CreatePostalCodeData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String code = ...;

final ref = ZerohungerConnector.instance.createPostalCode(
  code: code,
).ref();
ref.execute();
```


### CreateCurrentUser
#### Required Arguments
```dart
String userRole = ...;
ZerohungerConnector.instance.createCurrentUser(
  userRole: userRole,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateCurrentUser, we created `CreateCurrentUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateCurrentUserVariablesBuilder {
  ...
 
  CreateCurrentUserVariablesBuilder firstName(String? t) {
   _firstName.value = t;
   return this;
  }
  CreateCurrentUserVariablesBuilder lastName(String? t) {
   _lastName.value = t;
   return this;
  }
  CreateCurrentUserVariablesBuilder phoneNumber(String? t) {
   _phoneNumber.value = t;
   return this;
  }
  CreateCurrentUserVariablesBuilder street(String? t) {
   _street.value = t;
   return this;
  }
  CreateCurrentUserVariablesBuilder postalCodeId(BigInt? t) {
   _postalCodeId.value = t;
   return this;
  }

  ...
}
ZerohungerConnector.instance.createCurrentUser(
  userRole: userRole,
)
.firstName(firstName)
.lastName(lastName)
.phoneNumber(phoneNumber)
.street(street)
.postalCodeId(postalCodeId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateCurrentUserData, CreateCurrentUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.createCurrentUser(
  userRole: userRole,
);
CreateCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userRole = ...;

final ref = ZerohungerConnector.instance.createCurrentUser(
  userRole: userRole,
).ref();
ref.execute();
```


### UpdateCurrentUser
#### Required Arguments
```dart
// No required arguments
ZerohungerConnector.instance.updateCurrentUser().execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateCurrentUser, we created `UpdateCurrentUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateCurrentUserVariablesBuilder {
  ...
 
  UpdateCurrentUserVariablesBuilder firstName(String? t) {
   _firstName.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder lastName(String? t) {
   _lastName.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder phoneNumber(String? t) {
   _phoneNumber.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder userRole(String? t) {
   _userRole.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder street(String? t) {
   _street.value = t;
   return this;
  }
  UpdateCurrentUserVariablesBuilder postalCodeId(BigInt? t) {
   _postalCodeId.value = t;
   return this;
  }

  ...
}
ZerohungerConnector.instance.updateCurrentUser()
.firstName(firstName)
.lastName(lastName)
.phoneNumber(phoneNumber)
.userRole(userRole)
.street(street)
.postalCodeId(postalCodeId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateCurrentUserData, UpdateCurrentUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.updateCurrentUser();
UpdateCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ZerohungerConnector.instance.updateCurrentUser().ref();
ref.execute();
```


### UpdateCurrentUserRole
#### Required Arguments
```dart
String userRole = ...;
ZerohungerConnector.instance.updateCurrentUserRole(
  userRole: userRole,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateCurrentUserRoleData, UpdateCurrentUserRoleVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.updateCurrentUserRole(
  userRole: userRole,
);
UpdateCurrentUserRoleData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userRole = ...;

final ref = ZerohungerConnector.instance.updateCurrentUserRole(
  userRole: userRole,
).ref();
ref.execute();
```


### CreateOrganization
#### Required Arguments
```dart
String orgName = ...;
String orgPrimaryEmail = ...;
ZerohungerConnector.instance.createOrganization(
  orgName: orgName,
  orgPrimaryEmail: orgPrimaryEmail,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateOrganization, we created `CreateOrganizationBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateOrganizationVariablesBuilder {
  ...
   CreateOrganizationVariablesBuilder street(String? t) {
   _street.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder postalCodeId(BigInt? t) {
   _postalCodeId.value = t;
   return this;
  }

  ...
}
ZerohungerConnector.instance.createOrganization(
  orgName: orgName,
  orgPrimaryEmail: orgPrimaryEmail,
)
.street(street)
.postalCodeId(postalCodeId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateOrganizationData, CreateOrganizationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.createOrganization(
  orgName: orgName,
  orgPrimaryEmail: orgPrimaryEmail,
);
CreateOrganizationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgName = ...;
String orgPrimaryEmail = ...;

final ref = ZerohungerConnector.instance.createOrganization(
  orgName: orgName,
  orgPrimaryEmail: orgPrimaryEmail,
).ref();
ref.execute();
```


### LinkUserToOrganization
#### Required Arguments
```dart
BigInt userId = ...;
BigInt orgId = ...;
String memberRole = ...;
ZerohungerConnector.instance.linkUserToOrganization(
  userId: userId,
  orgId: orgId,
  memberRole: memberRole,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<LinkUserToOrganizationData, LinkUserToOrganizationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.linkUserToOrganization(
  userId: userId,
  orgId: orgId,
  memberRole: memberRole,
);
LinkUserToOrganizationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
BigInt userId = ...;
BigInt orgId = ...;
String memberRole = ...;

final ref = ZerohungerConnector.instance.linkUserToOrganization(
  userId: userId,
  orgId: orgId,
  memberRole: memberRole,
).ref();
ref.execute();
```


### CreateLocation
#### Required Arguments
```dart
String street = ...;
BigInt postalCodeId = ...;
ZerohungerConnector.instance.createLocation(
  street: street,
  postalCodeId: postalCodeId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateLocation, we created `CreateLocationBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateLocationVariablesBuilder {
  ...
   CreateLocationVariablesBuilder userId(BigInt? t) {
   _userId.value = t;
   return this;
  }
  CreateLocationVariablesBuilder orgId(BigInt? t) {
   _orgId.value = t;
   return this;
  }

  ...
}
ZerohungerConnector.instance.createLocation(
  street: street,
  postalCodeId: postalCodeId,
)
.userId(userId)
.orgId(orgId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateLocationData, CreateLocationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.createLocation(
  street: street,
  postalCodeId: postalCodeId,
);
CreateLocationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String street = ...;
BigInt postalCodeId = ...;

final ref = ZerohungerConnector.instance.createLocation(
  street: street,
  postalCodeId: postalCodeId,
).ref();
ref.execute();
```


### CreateUserPreferences
#### Required Arguments
```dart
BigInt userId = ...;
ZerohungerConnector.instance.createUserPreferences(
  userId: userId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateUserPreferences, we created `CreateUserPreferencesBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateUserPreferencesVariablesBuilder {
  ...
   CreateUserPreferencesVariablesBuilder radiusSearch(int? t) {
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

  ...
}
ZerohungerConnector.instance.createUserPreferences(
  userId: userId,
)
.radiusSearch(radiusSearch)
.notificationPreference(notificationPreference)
.alertSetting(alertSetting)
.locationId(locationId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateUserPreferencesData, CreateUserPreferencesVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.createUserPreferences(
  userId: userId,
);
CreateUserPreferencesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
BigInt userId = ...;

final ref = ZerohungerConnector.instance.createUserPreferences(
  userId: userId,
).ref();
ref.execute();
```


### UpdateCurrentUserRole
#### Required Arguments
```dart
String userRole = ...;
ZerohungerConnector.instance.updateCurrentUserRole(
  userRole: userRole,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateCurrentUserRoleData, UpdateCurrentUserRoleVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ZerohungerConnector.instance.updateCurrentUserRole(
  userRole: userRole,
);
UpdateCurrentUserRoleData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userRole = ...;

final ref = ZerohungerConnector.instance.updateCurrentUserRole(
  userRole: userRole,
).ref();
ref.execute();
```

