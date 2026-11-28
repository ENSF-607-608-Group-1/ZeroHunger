// zero_hunger_api.dart
// The app's side of the callable API (functions/src/api/zeroHungerApi.ts)
//
//   screen ──postFood()──> api-postFood (Cloud Function) ──PostFood──> Listing processor
//   screen ──postFood()──> CreateDonation (Data Connect)
//   screen ──claimFood()──> api-claimFood ──> Claim processor, which answers with the reservation
//   screen ──sendMessage()──> api-sendMessage ──SendMessage──> Messaging processor
//   screen ──postDistribution()──> api-postDistribution ──PostDistribution──> Distribution processor
//
// Each method sends a request and gets back a Submitted (donationId, correlationId)
// A food donation is saved before Submitted is returned; the Listing processor handles follow-up work.
// claimFood is different: it waits and gets back a ClaimResult (request-reply)
// sendMessage gets back a MessageSubmitted (messageId, correlationId)
// postDistribution gets back a DistributionSubmitted (distributionId, correlationId)
// We never send donorId: the cloud_functions package adds the signed-in user's token,
// and the function takes the user ID from that

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart'
    show DataConnectOperationError;

import '../generated/zerohunger.dart';
import 'push_notification_service.dart';

//the same as FOOD_CATEGORIES and ALLERGENS in types.ts
// Screens can use these lists to show the choices
const foodCategoryOptions = [
  'HALAL',
  'VEGAN',
  'VEGETARIAN',
  'UNCOOKED',
  'GRAIN',
];
const allergenOptions = [
  'PEANUTS',
  'TREE_NUTS',
  'MILK',
  'EGGS',
  'WHEAT',
  'SOY',
  'SESAME',
  'FISH',
  'SHELLFISH',
  'MUSTARD',
  'SULPHITES',
];

// What someone can post, the same as DistributionKind in types.ts
const distributionKindOptions = ['DISTRIBUTION', 'DONATION_EVENT'];

// One food item in a donation, e.g. 6 portions of rice
class FoodItem {
  final String name; // e.g. "Rice"
  final List<String>
  categories; // from foodCategoryOptions, e.g. ["HALAL", "VEGAN"]
  final List<String> allergens; // from allergenOptions, or empty
  final int quantity; // e.g. 6
  final String unit; // e.g. "portions" or "kg"

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
  final String line1; // e.g. "2500 University Dr NW"
  final String city; // e.g. "Calgary"
  final String province; // e.g. "AB"
  final String postalCode; // e.g. "T2N 1N4"

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
  final String
  donationId; // the donation this is about (a new one for postFood)
  final String
  correlationId; // search the logs for this to follow what happened next

  const Submitted(this.donationId, this.correlationId);
}

// One item to claim, e.g. 2 portions of the rice.
class ClaimItem {
  final String itemId; // the item's ID in the donation
  final int quantity; // how many, 1 or more

  const ClaimItem({required this.itemId, required this.quantity});

  // The shape api-claimFood expects for one item.
  Map<String, dynamic> toJson() => {'itemId': itemId, 'quantity': quantity};
}

// What claimFood answers instead: the reservation.
class ClaimResult {
  final String reservationId;
  final String donationId;
  final int quantityReserved; // all the items added up
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final String pickupCode; // 6 digits, shown to the donor at pickup
  final String correlationId; // search the logs for this

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

// What sendMessage answers: the message was accepted, Messaging saves it a moment later
class MessageSubmitted {
  final String messageId; // the new message's ID
  final String correlationId; // search the logs for this

  const MessageSubmitted(this.messageId, this.correlationId);
}

// What postDistribution answers: the event was accepted, Distribution saves it a moment later
class DistributionSubmitted {
  final String distributionId; // the new event's ID
  final String correlationId; // search the logs for this

  const DistributionSubmitted(this.distributionId, this.correlationId);
}

// A call that failed, with a message we can show the user
class ApiException implements Exception {
  final String code; // e.g. "permission-denied"
  final String message; // e.g. "Create an account to do this."

  const ApiException(this.code, this.message);

  @override
  String toString() => message;
}

// Compares UUIDs ignoring hyphens and casing (Data Connect returns 32-char hex UUIDs,
// while Cloud Functions randomUUID() returns hyphenated 36-char UUIDs).
bool uuidsMatch(String a, String b) =>
    a.replaceAll('-', '').trim().toLowerCase() ==
    b.replaceAll('-', '').trim().toLowerCase();

class DonationPersistenceException implements Exception {
  final String donationId;
  final Object cause;

  const DonationPersistenceException(this.donationId, this.cause);

  @override
  String toString() {
    if (cause case DataConnectOperationError(:final response)) {
      final errors = response.errors
          .map((error) {
            final path = error.path.join('.');
            return path.isEmpty ? error.message : '$path: ${error.message}';
          })
          .join('; ');
      return 'Donation $donationId was accepted, but database persistence '
          'failed: $errors';
    }
    return 'Donation $donationId was accepted, but database persistence '
        'failed: $cause';
  }
}

class ZeroHungerApi {
  ZeroHungerApi({this.connector});

  // Our functions run in us-central1 (setGlobalOptions in index.ts).
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );
  final ZerohungerConnector? connector;

  // api-postFood: a donor posts food. Guests get "permission-denied".
  Future<Submitted> postFood({
    required String title,
    String description = '',
    required List<FoodItem> items,
    required PickupAddress address,
    required DateTime pickupStart,
    required DateTime pickupEnd,
  }) async {
    final submitted = await _call('api-postFood', {
      'title': title,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'address': address.toJson(),
      'pickupStart': pickupStart.toUtc().toIso8601String(),
      'pickupEnd': pickupEnd.toUtc().toIso8601String(),
    });
    PushNotificationService.instance.markOwnDonation(submitted.donationId);
    try {
      await _saveDonationToDatabase(
        donationId: submitted.donationId,
        title: title,
        items: items,
        pickupStart: pickupStart,
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        DonationPersistenceException(submitted.donationId, error),
        stackTrace,
      );
    }
    return submitted;
  }

  Future<void> _saveDonationToDatabase({
    required String donationId,
    required String title,
    required List<FoodItem> items,
    required DateTime pickupStart,
  }) async {
    final activeConnector = connector ?? ZerohungerConnector.instance;
    final quantity = items.fold<int>(0, (total, item) => total + item.quantity);
    final statusId = await _resolveAvailableStatusId(activeConnector);
    final saved = await activeConnector
        .createDonation(
          donationTitle: title,
          pickupTime: _databaseTime(pickupStart),
          itemQuantities: BigInt.from(quantity),
          statusId: statusId,
        )
        .donationId(donationId)
        .execute();
    if (!uuidsMatch(saved.data.donation_insert.donationId, donationId)) {
      throw StateError(
        'Data Connect saved a different donation ID (${saved.data.donation_insert.donationId}).',
      );
    }
  }

  Future<BigInt> _resolveAvailableStatusId(ZerohungerConnector activeConnector) async {
    try {
      final statuses = await activeConnector.listDonationStatuses().execute();
      for (final status in statuses.data.donationStatuses) {
        if (status.name.trim().toLowerCase() == 'available') {
          return status.statusId;
        }
      }
      if (statuses.data.donationStatuses.isNotEmpty) {
        return statuses.data.donationStatuses.first.statusId;
      }
    } catch (_) {
      // Fall back to statusId 1 ("Available") if status lookup is unavailable.
    }
    return BigInt.one;
  }

  String _databaseTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

  // api-updateQuantity: a donor sets how much food is left.
  Future<Submitted> updateQuantity({
    required String donationId,
    required int newQuantity,
  }) {
    return _call('api-updateQuantity', {
      'donationId': donationId,
      'newQuantity': newQuantity,
    });
  }

  // api-cancelOrRescheduleDonation with CANCEL: a donor cancels a donation.
  Future<Submitted> cancelDonation({
    required String donationId,
    String? reason,
  }) {
    return _call('api-cancelOrRescheduleDonation', {
      'donationId': donationId,
      'action': 'CANCEL',
      'reason': ?reason, // left out if null
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
    String? donorId,
    String? donationTitle,
  }) async {
    final answer = await _answer('api-claimFood', {
      'donationId': donationId,
      'items': items.map((item) => item.toJson()).toList(),
      if (note != null) 'note': note,
      if (donorId != null && donorId.isNotEmpty) 'donorId': donorId,
      if (donationTitle != null && donationTitle.isNotEmpty)
        'donationTitle': donationTitle,
    });
    final result = ClaimResult.fromJson(answer);
    unawaited(PushNotificationService.instance.subscribeToDonation(result.donationId));
    return result;
  }

  // api-sendMessage: send a message in a chat
  // Guests can only write in their own pickup chat, whose ID is the claim's reservationId
  Future<MessageSubmitted> sendMessage({
    required String conversationId,
    required String text,
    String? donationId,
    String? receiverId,
  }) async {
    final answer = await _answer('api-sendMessage', {
      'conversationId': conversationId,
      'text': text,
      if (donationId != null && donationId.isNotEmpty) 'donationId': donationId,
      if (receiverId != null && receiverId.isNotEmpty) 'receiverId': receiverId,
    });
    return MessageSubmitted(
      answer['messageId'] as String,
      answer['correlationId'] as String,
    );
  }

  // api-postDistribution: an organization or donor posts a distribution or a donation event
  // Guests get "permission-denied", like postFood
  Future<DistributionSubmitted> postDistribution({
    required String kind, // from distributionKindOptions
    required String title,
    String comments = '',
    required PickupAddress address,
    required DateTime startTime,
    required DateTime endTime,
    String? organizationId, // the organization it's posted for, if any
  }) async {
    final answer = await _answer('api-postDistribution', {
      'kind': kind,
      'title': title,
      'comments': comments,
      'address': address.toJson(),
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      if (organizationId != null) 'organizationId': organizationId,
    });
    return DistributionSubmitted(
      answer['distributionId'] as String,
      answer['correlationId'] as String,
    );
  }

  // Calls one function by name and turns its answer into a Submitted.
  // If the function says no, throws an ApiException with words for the user.
  Future<Submitted> _call(String name, Map<String, dynamic> data) async {
    final answer = await _answer(name, data);
    return Submitted(
      answer['donationId'] as String,
      answer['correlationId'] as String,
    );
  }

  // Calls one function by name and returns its answer as a map (used by _call and claimFood).
  Future<Map<String, dynamic>> _answer(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      final code = e.code.toLowerCase().replaceAll(
        '_',
        '-',
      ); // e.g. "permission-denied"
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
        return message ??
            'Something in the form is not right.'; // e.g. "title is missing"
      case 'not-found':
        return 'This food is no longer listed.';
      case 'failed-precondition':
        return message ??
            'This food cannot be claimed right now.'; // e.g. "not enough left"
      case 'unavailable':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
