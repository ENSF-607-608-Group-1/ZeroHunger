// query_service.dart
// The app's read side: the food that can be claimed.



// TODO: Implement the actual cloud QueryService and database integration.
//NOTE:The cloud QueryService and the database don't exist yet, so this returns sample donations.
// Screens only ask this class, so real data later changes this file only.



import 'zero_hunger_api.dart';

// One food item in a donation, e.g. 6 portions of rice.
class DonationItem {
  final String itemId;            // what api-claimFood needs
  final String name;              // e.g. "Jasmine rice"
  final List<String> categories;  // from foodCategoryOptions, e.g. ["HALAL"]
  final List<String> allergens;   // from allergenOptions, or empty
  final int quantityLeft;         // how many can still be claimed
  final String unit;              // e.g. "portions"

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
  final String title;           // e.g. "Rice and stew"
  final String description;
  final List<DonationItem> items;
  final String area;            // the postal code's first part, e.g. "T2N" (gridCell in the events)
  final PickupAddress address;  // the full address, shown only after claiming
  final DateTime pickupStart;
  final DateTime pickupEnd;

  const Donation({
    required this.donationId,
    required this.title,
    required this.description,
    required this.items,
    required this.area,
    required this.address,
    required this.pickupStart,
    required this.pickupEnd,
  });

  // Every category of its items, e.g. {"HALAL", "VEGAN"}.
  Set<String> get categories => {for (final item in items) ...item.categories};

  // Every allergen of its items, e.g. {"SOY"}.
  Set<String> get allergens => {for (final item in items) ...item.allergens};
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
        EventKind.foodDistribution => 'Announce scheduled free food pickup for people nearby.',
        EventKind.donationEvent => 'Invite donors to bring and pool food at a scheduled time.',
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
      followingOrganization: followingOrganization ?? this.followingOrganization,
      rsvpCount: rsvpCount ?? this.rsvpCount,
    );
  }
}

class QueryService {
  // The donations that can be claimed now.
  // TODO: Review when database is complete. Ask the cloud QueryService for AVAILABLE donations
  //   near the user, without the full address (api-claimFood returns it after claiming).
  Future<List<Donation>> availableDonations() async {
    await Future<void>.delayed(const Duration(milliseconds: 400)); // like a real network call
    return _sampleDonations();
  }

  // The donations posted by the signed-in donor.
  // TODO: Review when database is complete. Ask the cloud QueryService for this donor's
  //   donations, their remaining quantities, status, and linked pickup chats.
  Future<List<DonorDonation>> myDonations() async {
    await Future<void>.delayed(const Duration(milliseconds: 400)); // like a real network call
    return _sampleMyDonations();
  }

  // Upcoming food distributions and donation events nearby.
  // TODO: Review when database is complete. Ask the cloud QueryService for upcoming
  //   DistributionEvent rows near the user, along with follow/RSVP status.
  Future<List<CommunityEvent>> upcomingEvents() async {
    await Future<void>.delayed(const Duration(milliseconds: 400)); // like a real network call
    return _sampleEvents();
  }
}

// Made-up upcoming events for building and testing the Events screen.
List<CommunityEvent> _sampleEvents() {
  final now = DateTime.now();
  DateTime at(int days, int hour, [int minute = 0]) => DateTime(now.year, now.month, now.day + days, hour, minute);

  return [
    CommunityEvent(
      eventId: 'evt-calgary-food-bank-1',
      title: 'Saturday Community Food Distribution',
      kind: EventKind.foodDistribution,
      startTime: at(0, 14),
      endTime: at(0, 17),
      address: const PickupAddress(
        line1: '5000 11 St SE',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2H 2Y5',
      ),
      organization: 'Calgary Food Bank',
      comments: 'Fresh produce, bread, and pantry staples available while supplies last. Please bring reusable bags and photo ID.',
      rsvpCount: 24,
    ),
    CommunityEvent(
      eventId: 'evt-community-fridge-drive',
      title: 'Beltline Community Donation Drive',
      kind: EventKind.donationEvent,
      startTime: at(1, 11),
      endTime: at(1, 14, 30),
      address: const PickupAddress(
        line1: '227 11 Ave SW',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2R 1B9',
      ),
      organization: 'Community Fridge YYC',
      comments: 'Collecting sealed dry goods, fresh fruit, and halal-certified meals to stock the community fridge for the week.',
      isHost: true,
      rsvpCount: 11,
    ),
    CommunityEvent(
      eventId: 'evt-ucalgary-pantry',
      title: 'Campus Weekly Pantry Pickup',
      kind: EventKind.foodDistribution,
      startTime: at(2, 12),
      endTime: at(2, 15),
      address: const PickupAddress(
        line1: '2500 University Dr NW',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2N 1N4',
      ),
      organization: 'UCalgary Food Pantry',
      comments: 'Open to students and local families. Enter through MacEwan Student Centre main doors.',
      followingOrganization: true,
      rsvpCount: 38,
    ),
    CommunityEvent(
      eventId: 'evt-neighbourhood-cookout',
      title: 'Bridgeland Neighbours Pantry Share',
      kind: EventKind.donationEvent,
      startTime: at(3, 16),
      endTime: at(3, 18, 30),
      address: const PickupAddress(
        line1: '917 Centre Ave NE',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2E 0C6',
      ),
      comments: 'Drop off extra unopened groceries or baked goods to share with neighbours in Bridgeland.',
      rsvpCount: 7,
    ),
  ];
}

// Made-up donor donations for building and testing the My donations screen.
List<DonorDonation> _sampleMyDonations() {
  final now = DateTime.now();
  DateTime at(int days, int hour, [int minute = 0]) => DateTime(now.year, now.month, now.day + days, hour, minute);

  return [
    DonorDonation(
      donationId: 'sample-rice-and-stew',
      title: 'Rice and stew',
      status: DonationStatus.available,
      amountLeft: 10,
      unit: 'portions',
      pickupStart: at(0, 17),
      pickupEnd: at(0, 19),
      pickupChats: [
        PickupChatSummary(
          chatId: 'chat-101',
          recipientLabel: 'Recipient #1043',
          lastMessage: 'Pickup chat opened. Hi, I can arrive around 5:30 pm.',
          updatedAt: now.subtract(const Duration(minutes: 18)),
        ),
        PickupChatSummary(
          chatId: 'chat-102',
          recipientLabel: 'Recipient #1049',
          lastMessage: 'Pickup chat opened.',
          updatedAt: now.subtract(const Duration(minutes: 5)),
        ),
      ],
    ),
    DonorDonation(
      donationId: 'sample-bagels-and-bread',
      title: 'Fresh bagels and bread',
      status: DonationStatus.claimed,
      amountLeft: 0,
      unit: 'items',
      pickupStart: at(0, 18),
      pickupEnd: at(0, 20, 30),
      pickupChats: [
        PickupChatSummary(
          chatId: 'chat-201',
          recipientLabel: 'Recipient #1052',
          lastMessage: 'On my way to pick up the bagels!',
          updatedAt: now.subtract(const Duration(minutes: 42)),
        ),
      ],
    ),
    DonorDonation(
      donationId: 'sample-biryani-and-raita',
      title: 'Vegetable biryani and raita',
      status: DonationStatus.available,
      amountLeft: 10,
      unit: 'portions',
      pickupStart: at(1, 12),
      pickupEnd: at(1, 14),
    ),
    DonorDonation(
      donationId: 'sample-pasta-trays',
      title: 'Baked vegetable pasta',
      status: DonationStatus.completed,
      amountLeft: 0,
      unit: 'portions',
      pickupStart: at(-1, 16),
      pickupEnd: at(-1, 18),
      pickupChats: [
        PickupChatSummary(
          chatId: 'chat-301',
          recipientLabel: 'Recipient #1012',
          lastMessage: 'Picked up, thank you so much!',
          updatedAt: now.subtract(const Duration(hours: 22)),
        ),
      ],
    ),
  ];
}

// Made-up donations for building and testing the screens.
List<Donation> _sampleDonations() {
  final now = DateTime.now();
  DateTime at(int days, int hour, [int minute = 0]) => DateTime(now.year, now.month, now.day + days, hour, minute);

  return [
    Donation(
      donationId: 'sample-rice-and-stew',
      title: 'Rice and stew',
      description: 'Vegetable rice and bean stew made this afternoon, in microwave-safe containers. Reheat before eating.',
      items: const [
        DonationItem(itemId: 'sample-rice', name: 'Jasmine rice', categories: ['VEGAN', 'HALAL'], quantityLeft: 6, unit: 'portions'),
        DonationItem(itemId: 'sample-stew', name: 'Bean stew', categories: ['VEGAN', 'HALAL'], allergens: ['SOY'], quantityLeft: 4, unit: 'portions'),
      ],
      area: 'T2N',
      address: const PickupAddress(line1: '12 Sample Crescent NW', city: 'Calgary', province: 'AB', postalCode: 'T2N 1A1'),
      pickupStart: at(0, 17),
      pickupEnd: at(0, 19),
    ),
    Donation(
      donationId: 'sample-bagels-and-bread',
      title: 'Fresh bagels and bread',
      description: "Today's unsold bagels and sourdough from a local bakery.",
      items: const [
        DonationItem(itemId: 'sample-bagels', name: 'Assorted bagels', categories: ['VEGETARIAN'], allergens: ['WHEAT', 'SESAME'], quantityLeft: 12, unit: 'items'),
        DonationItem(itemId: 'sample-sourdough', name: 'Sourdough loaf', categories: ['VEGETARIAN'], allergens: ['WHEAT'], quantityLeft: 2, unit: 'items'),
      ],
      area: 'T2G',
      address: const PickupAddress(line1: '34 Sample Avenue SE', city: 'Calgary', province: 'AB', postalCode: 'T2G 0A1'),
      pickupStart: at(0, 18),
      pickupEnd: at(0, 20, 30),
    ),
    Donation(
      donationId: 'sample-biryani-and-raita',
      title: 'Vegetable biryani and raita',
      description: 'Leftover catering trays, kept in the fridge since lunch.',
      items: const [
        DonationItem(itemId: 'sample-biryani', name: 'Vegetable biryani', categories: ['VEGETARIAN', 'HALAL'], quantityLeft: 5, unit: 'portions'),
        DonationItem(itemId: 'sample-raita', name: 'Raita', categories: ['VEGETARIAN', 'HALAL'], allergens: ['MILK'], quantityLeft: 5, unit: 'portions'),
      ],
      area: 'T3A',
      address: const PickupAddress(line1: '56 Sample Road NW', city: 'Calgary', province: 'AB', postalCode: 'T3A 0A1'),
      pickupStart: at(1, 12),
      pickupEnd: at(1, 14),
    ),
  ];
}