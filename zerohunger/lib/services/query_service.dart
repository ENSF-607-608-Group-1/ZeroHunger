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