// food_details_screen.dart
// One donation in full: pick how much of each item you want, then claim it. Guests can claim too.
//
//   "Claim" -> ZeroHungerApi.claimFood -> api-claimFood -> Claim processor -> the reservation
//
// The exact address shows only after claiming.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/query_service.dart';
import '../services/zero_hunger_api.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/food_parts.dart';
import '../widgets/form_parts.dart';

class FoodDetailsScreen extends StatefulWidget {
  const FoodDetailsScreen({super.key, required this.donation});

  final Donation donation;

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  final _auth = AuthService();
  final _api = ZeroHungerApi();

  final _chosen = <String, int>{}; // how many of each item, by itemId, e.g. {"sample-rice": 2}
  bool _claiming = false;          // true while waiting for api-claimFood

  // Everything chosen, added up, e.g. 2 + 1 = 3.
  int get _total => _chosen.values.fold(0, (sum, n) => sum + n);

  // Sends the claim and waits for the reservation (request-reply).
  Future<void> _claim() async {
    setState(() {
      _claiming = true;
    });
    try {
      final result = await _api.claimFood(
        donationId: widget.donation.donationId,
        items: [
          for (final entry in _chosen.entries)
            if (entry.value > 0) ClaimItem(itemId: entry.key, quantity: entry.value),
        ],
      );
      if (!mounted) return; // the screen was closed while we waited
      debugPrint('Claimed: reservation ${result.reservationId}, pickup code ${result.pickupCode}');
      // Next step: open the Claimed screen here.
      showZhMessage(context, 'chill guys...its not done yet :)');
    } on ApiException catch (e) {
      if (!mounted) return;
      showZhMessage(context, e.message, onRetry: _claim); // e.g. "This food is no longer listed."
    } catch (_) {
      if (!mounted) return;
      showZhMessage(context, 'Something went wrong. Please try again.', onRetry: _claim);
    } finally {
      if (mounted) {
        setState(() {
          _claiming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.donation;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZhColors.background,
        foregroundColor: ZhColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: const Text(
          'Food details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          StreamBuilder<User?>(
            stream: _auth.userChanges,
            initialData: _auth.currentUser,
            builder: (context, snapshot) => AccountButton(user: snapshot.data),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            d.title,
            style: const TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w600, color: ZhColors.text),
          ),
          const SizedBox(height: 16),
          _Panel(
            children: [
              IconLine(icon: Icons.place_outlined, text: '${d.area}, ${d.address.city}'),
              const SizedBox(height: 8),
              IconLine(icon: Icons.schedule_rounded, text: 'Pickup: ${pickupWindowText(d.pickupStart, d.pickupEnd)}'),
              const SizedBox(height: 8),
              const Text(
                'The exact address shows once you claim.',
                style: TextStyle(fontSize: 13, color: ZhColors.textSecondary),
              ),
            ],
          ),
          if (d.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Panel(
              children: [
                const SectionHeading('Description'),
                Text(d.description, style: const TextStyle(fontSize: 15, height: 1.5, color: ZhColors.text)),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const SectionHeading('Items'),
          for (final item in d.items) ...[
            _ItemCard(
              item: item,
              chosen: _chosen[item.itemId] ?? 0,
              onChanged: (n) => setState(() {
                _chosen[item.itemId] = n;
              }),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          const _FairShareNote(),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // The bar pinned to the bottom: how much is chosen, and the Claim button.
  Widget _bottomBar() {
    final total = _total;

    return Container(
      decoration: const BoxDecoration(
        color: ZhColors.surface,
        border: Border(top: BorderSide(color: ZhColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Chosen', style: TextStyle(fontSize: 14, color: ZhColors.textSecondary)),
                const Spacer(),
                Text(
                  total == 0 ? 'Nothing yet' : '$total in total',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ZhColors.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: zhPrimaryButton(),
              onPressed: total == 0 || _claiming ? null : _claim, // greyed out until something is chosen
              icon: _claiming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ZhColors.onPrimary),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(_claiming ? 'Claiming…' : 'Claim'),
            ),
          ],
        ),
      ),
    );
  }
}

// A white card with a thin border, holding a column of parts.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

// One item: its name, how much is left, its tags, and a stepper to choose how many.
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.chosen, required this.onChanged});

  final DonationItem item;
  final int chosen;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ZhColors.text)),
        const SizedBox(height: 4),
        Text(
          '${item.quantityLeft} ${item.unit} left',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ZhColors.primary),
        ),
        if (item.categories.isNotEmpty || item.allergens.isNotEmpty) ...[
          const SizedBox(height: 12),
          TagChips(categories: item.categories, allergens: item.allergens),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text('How many?', style: TextStyle(fontSize: 14, color: ZhColors.textSecondary)),
            ),
            QuantityStepper(value: chosen, min: 0, max: item.quantityLeft, onChanged: onChanged),
          ],
        ),
      ],
    );
  }
}

// The reminder under the items, from the design's "Fair Share Promise".
class _FairShareNote extends StatelessWidget {
  const _FairShareNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ZhColors.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.volunteer_activism_outlined, size: 22, color: ZhColors.onPrimaryContainer),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please only claim what you can eat today and pick it up during the pickup time so no food is wasted.',
              style: TextStyle(fontSize: 14, height: 1.4, color: ZhColors.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}