// find_food_screen.dart
// The food anyone can claim, guests included.
//
//QueryService.availableDonations() -> a card per donation -> tap one -> Food details (FoodDetailsScreen done) 
//TODO:Still needs database inplementation
//
// Until the database exists the list is the sample donations in query_service.dart.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/query_service.dart';
import '../services/zero_hunger_api.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/food_parts.dart';
import '../widgets/form_parts.dart';
import '../widgets/notification_button.dart';
import 'food_details_screen.dart';

class FindFoodScreen extends StatefulWidget {
  const FindFoodScreen({super.key});

  @override
  State<FindFoodScreen> createState() => _FindFoodScreenState();
}

class _FindFoodScreenState extends State<FindFoodScreen> {
  final _auth = AuthService();
  final _query = QueryService();

  late Future<List<Donation>> _donations = _query.availableDonations(); // the list being loaded
  final _filters = <String>{}; // the categories picked, e.g. {"HALAL"}

  // Loads the list again (pull down to refresh).
  Future<void> _reload() async {
    final next = _query.availableDonations();
    setState(() {
      _donations = next;
    });
    await next;
  }

  // The donations that have at least one item with every category picked.
  List<Donation> _matching(List<Donation> all) {
    if (_filters.isEmpty) return all;
    return all.where((d) => d.items.any((item) => item.categories.toSet().containsAll(_filters))).toList();
  }

    void _open(Donation donation) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodDetailsScreen(donation: donation)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZhColors.background,
        foregroundColor: ZhColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: const Text(
          'Find food',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          const NotificationButton(),
          StreamBuilder<User?>(
            stream: _auth.userChanges,
            initialData: _auth.currentUser,
            builder: (context, snapshot) => AccountButton(user: snapshot.data),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _filterRow(),
          Expanded(
            child: FutureBuilder<List<Donation>>(
              future: _donations,
              builder: (context, snapshot) {
                // A spinner on the first load. On a refresh the old list stays until the new one arrives.
                if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final shown = _matching(snapshot.data ?? const []);

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(), // pull to refresh works on a short list too
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (snapshot.hasError)
                        const _Notice(
                          icon: Icons.cloud_off_rounded,
                          title: 'Could not load food',
                          subtitle: 'Check your connection, then pull down to try again.',
                        )
                      else if (shown.isEmpty)
                        _Notice(
                          icon: Icons.search_off_rounded,
                          title: _filters.isEmpty ? 'No food near you right now' : 'No food matches these filters',
                          subtitle: _filters.isEmpty ? 'Pull down to check again.' : 'Try turning a filter off.',
                        )
                      else
                        for (final donation in shown) ...[
                          _DonationCard(donation: donation, onOpen: () => _open(donation)),
                          const SizedBox(height: 16),
                        ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // The category filters, in a row you can scroll sideways. Tap one to turn it on or off.
  Widget _filterRow() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          for (final tag in foodCategoryOptions) ...[
            TagChip(
              label: tagLabel(tag),
              selected: _filters.contains(tag),
              onTap: () => setState(() {
                if (!_filters.remove(tag)) _filters.add(tag); // remove it, or add it if it wasn't there
              }),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// One donation: title, items, pickup time, area, tags, and a "Claim food" button.
class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.donation, required this.onOpen});

  final Donation donation;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final d = donation;

    return Material(
      color: ZhColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ZhColors.divider),
      ),
      clipBehavior: Clip.antiAlias, // keeps the tap ripple inside the rounded corners
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ZhColors.text)),
              const SizedBox(height: 4),
              Text(itemsSummary(d.items), style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary)),
              const SizedBox(height: 12),
              IconLine(icon: Icons.schedule_rounded, text: pickupWindowText(d.pickupStart, d.pickupEnd)),
              const SizedBox(height: 8),
              IconLine(icon: Icons.place_outlined, text: '${d.area}, ${d.address.city}'),
              const SizedBox(height: 12),
              TagChips(categories: d.categories, allergens: d.allergens),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ZhColors.primary,
                    foregroundColor: ZhColors.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onOpen,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text('Claim food'), SizedBox(width: 4), Icon(Icons.chevron_right_rounded, size: 20)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A message in place of the list, e.g. "No food near you right now".
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: ZhColors.primaryContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: ZhColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ZhColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary),
          ),
        ],
      ),
    );
  }
}