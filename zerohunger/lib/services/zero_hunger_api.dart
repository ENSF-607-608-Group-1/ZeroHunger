// zero_hunger_api.dart
// The app's side of the callable API (functions/src/api/zeroHungerApi.ts)
//
//   screen ──postFood()──> api-postFood (Cloud Function) ──PostFood──> Listing processor
//   screen ──claimFood()──> api-claimFood ──> Claim processor, which answers with the reservation
//
// Each method sends a request and gets back a Submitted (donationId, correlationId)
// Submitted means "accepted", not "live yet": the Listing processor does the rest a moment later
// claimFood is different: it waits and gets back a ClaimResult (request-reply)
// We never send donorId: the cloud_functions package adds the signed-in user's token,
// and the function takes the user ID from that

import 'package:cloud_functions/cloud_functions.dart';

//the same as FOOD_CATEGORIES and ALLERGENS in types.ts
// Screens can use these lists to show the choices
const foodCategoryOptions = ['HALAL', 'VEGAN', 'VEGETARIAN', 'UNCOOKED', 'GRAIN'];
const allergenOptions = [
  'PEANUTS', 'TREE_NUTS', 'MILK', 'EGGS', 'WHEAT', 'SOY',
  'SESAME', 'FISH', 'SHELLFISH', 'MUSTARD', 'SULPHITES',
];

// One food item in a donation, e.g. 6 portions of rice
class FoodItem {
  final String name;              // e.g. "Rice"
  final List<String> categories;  // from foodCategoryOptions, e.g. ["HALAL", "VEGAN"]
  final List<String> allergens;   // from allergenOptions, or empty
  final int quantity;             // e.g. 6
  final String unit;              // e.g. "portions" or "kg"

  const FoodItem({
    required this.name,
    this.categories = const [],
    this.allergens = const [],
    required this.quantity,
    required this.unit,
  });

  // The shape api-postFood expects for one item.
  Map<String, dynamic> toJson() => {
        'name': name,
        'categories': categories,
        'allergens': allergens,
        'quantity': quantity,
        'unit': unit,
      };
}

// Where to pick the food up.
class PickupAddress {
  final String line1;       // e.g. "2500 University Dr NW"
  final String city;        // e.g. "Calgary"
  final String province;    // e.g. "AB"
  final String postalCode;  // e.g. "T2N 1N4"

  const PickupAddress({
    required this.line1,
    required this.city,
    required this.province,
    required this.postalCode,
  });

  Map<String, dynamic> toJson() => {
        'line1': line1,
        'city': city,
        'province': province,
        'postalCode': postalCode,
      };
}

// What every call answers.
class Submitted {
  final String donationId;     // the donation this is about (a new one for postFood)
  final String correlationId;  // search the logs for this to follow what happened next

  const Submitted(this.donationId, this.correlationId);
}

// One item to claim, e.g. 2 portions of the rice.
class ClaimItem {
  final String itemId;  // the item's ID in the donation
  final int quantity;   // how many, 1 or more

  const ClaimItem({required this.itemId, required this.quantity});

  // The shape api-claimFood expects for one item.
  Map<String, dynamic> toJson() => {'itemId': itemId, 'quantity': quantity};
}

// What claimFood answers instead: the reservation.
class ClaimResult {
  final String reservationId;
  final String donationId;
  final int quantityReserved;   // all the items added up
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final String pickupCode;      // 6 digits, shown to the donor at pickup
  final String correlationId;   // search the logs for this

  const ClaimResult({
    required this.reservationId,
    required this.donationId,
    required this.quantityReserved,
    required this.pickupStart,
    required this.pickupEnd,
    required this.pickupCode,
    required this.correlationId,
  });

  // Reads api-claimFood's answer.
  factory ClaimResult.fromJson(Map<String, dynamic> json) => ClaimResult(
        reservationId: json['reservationId'] as String,
        donationId: json['donationId'] as String,
        quantityReserved: (json['quantityReserved'] as num).toInt(),
        pickupStart: DateTime.parse(json['pickupStart'] as String),
        pickupEnd: DateTime.parse(json['pickupEnd'] as String),
        pickupCode: json['pickupCode'] as String,
        correlationId: json['correlationId'] as String,
      );
}

// A call that failed, with a message we can show the user
class ApiException implements Exception {
  final String code;     // e.g. "permission-denied"
  final String message;  // e.g. "Create an account to do this."

  const ApiException(this.code, this.message);

  @override
  String toString() => message;
}

class ZeroHungerApi {
  // Our functions run in us-central1 (setGlobalOptions in index.ts).
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  // api-postFood: a donor posts food. Guests get "permission-denied".
  Future<Submitted> postFood({
    required String title,
    String description = '',
    required List<FoodItem> items,
    required PickupAddress address,
    required DateTime pickupStart,
    required DateTime pickupEnd,
  }) {
    return _call('api-postFood', {
      'title': title,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'address': address.toJson(),
      'pickupStart': pickupStart.toUtc().toIso8601String(),
      'pickupEnd': pickupEnd.toUtc().toIso8601String(),
    });
  }

  // api-updateQuantity: a donor sets how much food is left.
  Future<Submitted> updateQuantity({required String donationId, required int newQuantity}) {
    return _call('api-updateQuantity', {
      'donationId': donationId,
      'newQuantity': newQuantity,
    });
  }

  // api-cancelOrRescheduleDonation with CANCEL: a donor cancels a donation.
  Future<Submitted> cancelDonation({required String donationId, String? reason}) {
    return _call('api-cancelOrRescheduleDonation', {
      'donationId': donationId,
      'action': 'CANCEL',
      'reason': ?reason,// left out if null
    });
  }

  // api-cancelOrRescheduleDonation with RESCHEDULE: a donor moves the pickup time.
  Future<Submitted> rescheduleDonation({
    required String donationId,
    required DateTime newPickupStart,
    required DateTime newPickupEnd,
  }) {
    return _call('api-cancelOrRescheduleDonation', {
      'donationId': donationId,
      'action': 'RESCHEDULE',
      'newPickupStart': newPickupStart.toUtc().toIso8601String(),
      'newPickupEnd': newPickupEnd.toUtc().toIso8601String(),
    });
  }

  // api-claimFood: a recipient (guests too) claims some of a donation's items.
  // Waits for the reservation, so the screen can show the pickup code straight away.
  Future<ClaimResult> claimFood({
    required String donationId,
    required List<ClaimItem> items,
    String? note,
  }) async {
    final answer = await _answer('api-claimFood', {
      'donationId': donationId,
      'items': items.map((item) => item.toJson()).toList(),
      'note': ?note,// left out if null
    });
    return ClaimResult.fromJson(answer);
  }

  // Calls one function by name and turns its answer into a Submitted.
  // If the function says no, throws an ApiException with words for the user.
  Future<Submitted> _call(String name, Map<String, dynamic> data) async {
    final answer = await _answer(name, data);
    return Submitted(answer['donationId'] as String, answer['correlationId'] as String);
  }

  // Calls one function by name and returns its answer as a map (used by _call and claimFood).
  Future<Map<String, dynamic>> _answer(String name, Map<String, dynamic> data) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      final code = e.code.toLowerCase().replaceAll('_', '-'); // e.g. "permission-denied"
      throw ApiException(code, _friendly(code, e.message));
    }
  }

  // Turns error into words (for the user tbh)
  String _friendly(String code, String? message) {
    switch (code) {
      case 'unauthenticated':
        return 'Please sign in and try again.';
      case 'permission-denied':
        return 'Create an account to do this.';
      case 'invalid-argument':
        return message ?? 'Something in the form is not right.'; // e.g. "title is missing"
      case 'not-found':
        return 'This food is no longer listed.';
      case 'failed-precondition':
        return message ?? 'This food cannot be claimed right now.'; // e.g. "not enough left"
      case 'unavailable':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}