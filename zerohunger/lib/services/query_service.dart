// query_service.dart
// The app's read side: the food that can be claimed and the user's reservations.



// TODO: Implement the actual cloud QueryService and database integration.
//NOTE:The cloud QueryService and the database don't exist yet, so this returns sample data.
// Screens only ask this class, so real data later changes this file only.



import 'zero_hunger_api.dart';

// Where a reservation is in its life (ReservationStatus in functions/src/events/types.ts).
enum ReservationStatus {
  active,
  rescheduled,
  pickedUp,
  cancelled,
  expired,
}

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

// One claimed donation and its pickup details, shown on My reservations.
class Reservation {
  final String reservationId;       // also the pickup chat's conversationId
  final String donationId;
  final String donationTitle;       // e.g. "Rice and stew"
  final String pickupCode;          // 6 digits shown to the donor at pickup
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final PickupAddress address;      // full pickup address, available after claiming
  final ReservationStatus status;
  final List<DonationItem> items;
  final String? cancelReason;       // shown when status is cancelled

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
  bool get isUpcoming => status == ReservationStatus.active || status == ReservationStatus.rescheduled;
}

class QueryService {
  // The donations that can be claimed now.
  // TODO: Review when database is complete. Ask the cloud QueryService for AVAILABLE donations
  //   near the user, without the full address (api-claimFood returns it after claiming).
  Future<List<Donation>> availableDonations() async {
    await Future<void>.delayed(const Duration(milliseconds: 400)); // like a real network call
    return _sampleDonations();
  }

  // The current user's food claims and their pickup codes.
  // TODO: Review when database is complete. Ask the cloud QueryService for the signed-in
  //   user's FoodReservations (with each donation's title and pickup address).
  Future<List<Reservation>> myReservations() async {
    await Future<void>.delayed(const Duration(milliseconds: 400)); // like a real network call
    return _sampleReservations();
  }
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

// Made-up reservations covering every status for building and testing My reservations.
List<Reservation> _sampleReservations() {
  final now = DateTime.now();
  DateTime at(int days, int hour, [int minute = 0]) => DateTime(now.year, now.month, now.day + days, hour, minute);

  return [
    Reservation(
      reservationId: 'sample-res-rice-and-stew',
      donationId: 'sample-rice-and-stew',
      donationTitle: 'Rice and stew',
      pickupCode: '615318',
      pickupStart: DateTime(now.year, now.month, now.day, now.hour + 1),
      pickupEnd: DateTime(now.year, now.month, now.day, now.hour + 3),
      address: const PickupAddress(line1: '12 Sample Crescent NW', city: 'Calgary', province: 'AB', postalCode: 'T2N 1A1'),
      status: ReservationStatus.active,
      items: const [
        DonationItem(itemId: 'sample-rice', name: 'Jasmine rice', categories: ['VEGAN', 'HALAL'], quantityLeft: 6, unit: 'portions'),
        DonationItem(itemId: 'sample-stew', name: 'Bean stew', categories: ['VEGAN', 'HALAL'], allergens: ['SOY'], quantityLeft: 4, unit: 'portions'),
      ],
    ),
    Reservation(
      reservationId: 'sample-res-biryani-and-raita',
      donationId: 'sample-biryani-and-raita',
      donationTitle: 'Vegetable biryani and raita',
      pickupCode: '482910',
      pickupStart: at(1, 12),
      pickupEnd: at(1, 14),
      address: const PickupAddress(line1: '56 Sample Road NW', city: 'Calgary', province: 'AB', postalCode: 'T3A 0A1'),
      status: ReservationStatus.rescheduled,
      items: const [
        DonationItem(itemId: 'sample-biryani', name: 'Vegetable biryani', categories: ['VEGETARIAN', 'HALAL'], quantityLeft: 5, unit: 'portions'),
      ],
    ),
    Reservation(
      reservationId: 'sample-res-bagels-and-bread',
      donationId: 'sample-bagels-and-bread',
      donationTitle: 'Fresh bagels and bread',
      pickupCode: '903421',
      pickupStart: at(-1, 17),
      pickupEnd: at(-1, 19),
      address: const PickupAddress(line1: '34 Sample Avenue SE', city: 'Calgary', province: 'AB', postalCode: 'T2G 0A1'),
      status: ReservationStatus.pickedUp,
      items: const [
        DonationItem(itemId: 'sample-bagels', name: 'Assorted bagels', categories: ['VEGETARIAN'], allergens: ['WHEAT', 'SESAME'], quantityLeft: 6, unit: 'items'),
      ],
    ),
    Reservation(
      reservationId: 'sample-res-pasta-sauce',
      donationId: 'sample-pasta-sauce',
      donationTitle: 'Pasta and tomato sauce',
      pickupCode: '274815',
      pickupStart: at(-1, 14),
      pickupEnd: at(-1, 16),
      address: const PickupAddress(line1: '78 Sample Street SW', city: 'Calgary', province: 'AB', postalCode: 'T2S 1B2'),
      status: ReservationStatus.cancelled,
      items: const [
        DonationItem(itemId: 'sample-pasta', name: 'Penne pasta', categories: ['VEGETARIAN'], allergens: ['WHEAT'], quantityLeft: 3, unit: 'portions'),
      ],
      cancelReason: 'Donor ran out of containers before pickup.',
    ),
    Reservation(
      reservationId: 'sample-res-sourdough-pastries',
      donationId: 'sample-sourdough-pastries',
      donationTitle: 'Sourdough and pastries',
      pickupCode: '519034',
      pickupStart: at(-2, 10),
      pickupEnd: at(-2, 12),
      address: const PickupAddress(line1: '90 Sample Way NE', city: 'Calgary', province: 'AB', postalCode: 'T1Y 2C3'),
      status: ReservationStatus.expired,
      items: const [
        DonationItem(itemId: 'sample-croissants', name: 'Butter croissants', categories: ['VEGETARIAN'], allergens: ['WHEAT', 'MILK'], quantityLeft: 4, unit: 'items'),
      ],
    ),
  ];
}