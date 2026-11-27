# zerohunger_data_connect SDK

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

### ListDonationsByStatus
#### Required Arguments
```dart
BigInt statusId = ...;
ZerohungerConnector.instance.listDonationsByStatus(
  statusId: statusId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListDonationsByStatusData, ListDonationsByStatusVariables>`
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

final result = await ZerohungerConnector.instance.listDonationsByStatus(
  statusId: statusId,
);
ListDonationsByStatusData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
BigInt statusId = ...;

final ref = ZerohungerConnector.instance.listDonationsByStatus(
  statusId: statusId,
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

## Mutations

### CreateCurrentUser
#### Required Arguments
```dart
// No required arguments
ZerohungerConnector.instance.createCurrentUser().execute();
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

  ...
}
ZerohungerConnector.instance.createCurrentUser()
.firstName(firstName)
.lastName(lastName)
.phoneNumber(phoneNumber)
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

final result = await ZerohungerConnector.instance.createCurrentUser();
CreateCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ZerohungerConnector.instance.createCurrentUser().ref();
ref.execute();
```

