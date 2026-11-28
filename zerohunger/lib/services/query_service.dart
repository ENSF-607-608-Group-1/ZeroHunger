// query_service.dart
// The app's read side: the food that can be claimed and the user's reservations.

// Database-backed queries are being added incrementally. Unsupported lists return
// no records until the schema can represent them safely.

import 'package:firebase_data_connect/firebase_data_connect.dart'
    show Timestamp;

import '../generated/zerohunger.dart';
import 'zero_hunger_api.dart';

// Where a reservation is in its life (ReservationStatus in functions/src/events/types.ts).
enum ReservationStatus { active, rescheduled, pickedUp, cancelled, expired }

// One food item in a donation, e.g. 6 portions of rice.
class DonationItem {
  final String itemId; // what api-claimFood needs
  final String name; // e.g. "Jasmine rice"
  final List<String> categories; // from foodCategoryOptions, e.g. ["HALAL"]
  final List<String> allergens; // from allergenOptions, or empty
  final int quantityLeft; // how many can still be claimed
  final String unit; // e.g. "portions"

  const DonationItem({
    required this.itemId,
    required this.name,
    this.categories = const [],
    this.allergens = const [],
    required this.quantityLeft,
    required this.unit,
  });
}

// A donation as recipients see it.
class Donation {
  final String donationId;
  final String title; // e.g. "Rice and stew"
  final String description;
  final List<DonationItem> items;
  final String?
  area; // the postal code's first part, e.g. "T2N" (gridCell in the events)
  final PickupAddress? address; // the full address, shown only after claiming
  final DateTime? pickupStart;
  final DateTime? pickupEnd;
  final String? pickupTime;
  final BigInt? totalQuantity;

  const Donation({
    required this.donationId,
    required this.title,
    this.description = '',
    this.items = const [],
    this.area,
    this.address,
    this.pickupStart,
    this.pickupEnd,
    this.pickupTime,
    this.totalQuantity,
  });

  // Every category of its items, e.g. {"HALAL", "VEGAN"}.
  Set<String> get categories => {for (final item in items) ...item.categories};

  // Every allergen of its items, e.g. {"SOY"}.
  Set<String> get allergens => {for (final item in items) ...item.allergens};
}

// One claimed donation and its pickup details, shown on My reservations.
class Reservation {
  final String reservationId; // also the pickup chat's conversationId
  final String donationId;
  final String donationTitle; // e.g. "Rice and stew"
  final String pickupCode; // 6 digits shown to the donor at pickup
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final PickupAddress address; // full pickup address, available after claiming
  final ReservationStatus status;
  final List<DonationItem> items;
  final String? cancelReason; // shown when status is cancelled

  const Reservation({
    required this.reservationId,
    required this.donationId,
    required this.donationTitle,
    required this.pickupCode,
    required this.pickupStart,
    required this.pickupEnd,
    required this.address,
    required this.status,
    this.items = const [],
    this.cancelReason,
  });

  // Active and rescheduled claims still need to be picked up.
  bool get isUpcoming =>
      status == ReservationStatus.active ||
      status == ReservationStatus.rescheduled;
}

// Where a donation is in its life (matches DonationState in functions/src/events/types.ts).
enum DonationStatus {
  available,
  claimed,
  completed,
  cancelled,
  expired;

  String get label => switch (this) {
    DonationStatus.available => 'Available',
    DonationStatus.claimed => 'Claimed',
    DonationStatus.completed => 'Completed',
    DonationStatus.cancelled => 'Cancelled',
    DonationStatus.expired => 'Expired',
  };
}

// One pickup chat linked to a donor's donation (placeholder until MessagingService is built).
class PickupChatSummary {
  final String chatId;
  final String recipientLabel;
  final String lastMessage;
  final DateTime updatedAt;

  const PickupChatSummary({
    required this.chatId,
    required this.recipientLabel,
    required this.lastMessage,
    required this.updatedAt,
  });
}

// A donation as its donor sees and manages it on the My donations screen.
class DonorDonation {
  final String donationId;
  final String title;
  final DonationStatus status;
  final int amountLeft;
  final String unit;
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final String? cancelReason;
  final List<PickupChatSummary> pickupChats;

  const DonorDonation({
    required this.donationId,
    required this.title,
    required this.status,
    required this.amountLeft,
    required this.unit,
    required this.pickupStart,
    required this.pickupEnd,
    this.cancelReason,
    this.pickupChats = const [],
  });

  DonorDonation copyWith({
    DonationStatus? status,
    int? amountLeft,
    DateTime? pickupStart,
    DateTime? pickupEnd,
    String? cancelReason,
    List<PickupChatSummary>? pickupChats,
  }) {
    return DonorDonation(
      donationId: donationId,
      title: title,
      status: status ?? this.status,
      amountLeft: amountLeft ?? this.amountLeft,
      unit: unit,
      pickupStart: pickupStart ?? this.pickupStart,
      pickupEnd: pickupEnd ?? this.pickupEnd,
      cancelReason: cancelReason ?? this.cancelReason,
      pickupChats: pickupChats ?? this.pickupChats,
    );
  }
}

// The two kinds of community events a donor or organization can announce.
enum EventKind {
  foodDistribution,
  donationEvent;

  String get label => switch (this) {
    EventKind.foodDistribution => 'Food distribution',
    EventKind.donationEvent => 'Donation event',
  };

  String get apiValue => switch (this) {
    EventKind.foodDistribution => 'FOOD_DISTRIBUTION',
    EventKind.donationEvent => 'DONATION_EVENT',
  };

  String get description => switch (this) {
    EventKind.foodDistribution =>
      'Announce scheduled free food pickup for people nearby.',
    EventKind.donationEvent =>
      'Invite donors to bring and pool food at a scheduled time.',
  };
}

// An upcoming food distribution or donation event shown on the Events screen.
class CommunityEvent {
  final String eventId;
  final String title;
  final EventKind kind;
  final DateTime startTime;
  final DateTime endTime;
  final PickupAddress address;
  final String? organization;
  final String comments;
  final bool isHost;
  final bool endedEarly;
  final bool rsvped;
  final bool followingOrganization;
  final int rsvpCount;

  const CommunityEvent({
    required this.eventId,
    required this.title,
    required this.kind,
    required this.startTime,
    required this.endTime,
    required this.address,
    this.organization,
    this.comments = '',
    this.isHost = false,
    this.endedEarly = false,
    this.rsvped = false,
    this.followingOrganization = false,
    this.rsvpCount = 0,
  });

  CommunityEvent copyWith({
    bool? endedEarly,
    bool? rsvped,
    bool? followingOrganization,
    int? rsvpCount,
  }) {
    return CommunityEvent(
      eventId: eventId,
      title: title,
      kind: kind,
      startTime: startTime,
      endTime: endTime,
      address: address,
      organization: organization,
      comments: comments,
      isHost: isHost,
      endedEarly: endedEarly ?? this.endedEarly,
      rsvped: rsvped ?? this.rsvped,
      followingOrganization:
          followingOrganization ?? this.followingOrganization,
      rsvpCount: rsvpCount ?? this.rsvpCount,
    );
  }
}

// A local food bank or community group that users can follow for alerts.
class OrganizationSummary {
  final String organizationId;
  final String name;
  final String city;
  final bool following;

  const OrganizationSummary({
    required this.organizationId,
    required this.name,
    required this.city,
    this.following = false,
  });

  OrganizationSummary copyWith({bool? following}) {
    return OrganizationSummary(
      organizationId: organizationId,
      name: name,
      city: city,
      following: following ?? this.following,
    );
  }
}

class QueryService {
  QueryService({this.connector});

  final ZerohungerConnector? connector;

  // The donations that can be claimed now.
  Future<List<Donation>> availableDonations() async {
    final result = await (connector ?? ZerohungerConnector.instance)
        .listAvailableDonations()
        .execute();
    return result.data.donations
        .map(
          (donation) => Donation(
            donationId: donation.donationId,
            title: donation.donationTitle,
            pickupTime: donation.pickupTime,
            totalQuantity: donation.itemQuantities,
            items: donation.itemQuantities > BigInt.zero
                ? [
                    DonationItem(
                      itemId: donation.donationId,
                      name: donation.donationTitle,
                      quantityLeft: donation.itemQuantities.toInt(),
                      unit: donation.itemQuantities == BigInt.one
                          ? 'portion'
                          : 'portions',
                    ),
                  ]
                : const [],
          ),
        )
        .toList();
  }

  // The current user's food claims and their pickup codes.
  // The current schema has no reservation table or pickup-code fields.
  Future<List<Reservation>> myReservations() async {
    return const [];
  }

  // The schema does not associate donations with their posting user.
  Future<List<DonorDonation>> myDonations() async {
    return const [];
  }

  // Upcoming food distributions and donation events nearby.
  Future<List<CommunityEvent>> upcomingEvents() async {
    final now = DateTime.now();
    final result = await (connector ?? ZerohungerConnector.instance)
        .listDistributionEvents(
          asOf: Timestamp.fromJson(now.toUtc().toIso8601String()),
        )
        .execute();
    return result.data.distributionEvents
        .where((event) => event.timeEnd.toDateTime().isAfter(now))
        .map((event) {
          final kind = event.eventType.toUpperCase().contains('DONATION')
              ? EventKind.donationEvent
              : EventKind.foodDistribution;
          final postalCode = event.location.postalCode;
          return CommunityEvent(
            eventId: event.eventId.toString(),
            title: kind.label,
            kind: kind,
            startTime: event.timeStart.toDateTime(),
            endTime: event.timeEnd.toDateTime(),
            address: PickupAddress(
              line1: event.location.street,
              city: postalCode.city ?? '',
              province: postalCode.province ?? '',
              postalCode: postalCode.code,
            ),
            organization: event.location.organization?.orgName,
          );
        })
        .toList();
  }

  // Local food banks and community groups users can follow for alerts.
  Future<List<OrganizationSummary>> organizations() async {
    final result = await (connector ?? ZerohungerConnector.instance)
        .listOrganizations()
        .execute();
    return result.data.organizations
        .map(
          (organization) => OrganizationSummary(
            organizationId: organization.orgId.toString(),
            name: organization.orgName,
            city: organization.postalCode?.city ?? '',
          ),
        )
        .toList();
  }
}
