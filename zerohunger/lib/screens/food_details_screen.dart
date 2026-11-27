// food_details_screen.dart
// One donation in full: switch on the items you want, then claim them. Guests can claim too.
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
import 'claimed_screen.dart';

class FoodDetailsScreen extends StatefulWidget {
  const FoodDetailsScreen({super.key, required this.donation});

  final Donation donation;

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  final _auth = AuthService();
  final _api = ZeroHungerApi();

  final _wanted = <String>{}; // the itemIds switched on, e.g. {"sample-rice"}
  bool _claiming = false;     // true while waiting for api-claimFood

  // Sends the claim and waits for the reservation (request-reply).
  Future<void> _claim() async {
    setState(() {
      _claiming = true;
    });
    try {
      final result = await _api.claimFood(
        donationId: widget.donation.donationId,
        items: [
          // A switched-on item is claimed whole: all of it that's left.
          for (final item in widget.donation.items)
            if (_wanted.contains(item.itemId)) ClaimItem(itemId: item.itemId, quantity: item.quantityLeft),
        ],
      );
      if (!mounted) return; // the screen was closed while we waited
      debugPrint('Claimed: reservation ${result.reservationId}, pickup code ${result.pickupCode}');
      // Swap this screen for Claimed, so Back goes to the Find food list.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClaimedScreen(
            donation: widget.donation,
            items: [for (final item in widget.donation.items) if (_wanted.contains(item.itemId)) item],
            result: result,
          ),
        ),
      );
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
              Text(
                '${d.area}, ${d.address.city}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ZhColors.text),
              ),
              const SizedBox(height: 4),
              Text(
                'Pickup: ${pickupWindowText(d.pickupStart, d.pickupEnd)}',
                style: const TextStyle(fontSize: 15, color: ZhColors.text),
              ),
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
              wanted: _wanted.contains(item.itemId),
              onChanged: (on) => setState(() {
                if (on) {
                  _wanted.add(item.itemId);
                } else {
                  _wanted.remove(item.itemId);
                }
              }),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // The bar pinned to the bottom: how many items are chosen, and the Claim button.
  Widget _bottomBar() {
    final count = _wanted.length;

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
                  count == 0 ? 'Nothing yet' : (count == 1 ? '1 item' : '$count items'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ZhColors.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: zhPrimaryButton(),
              onPressed: count == 0 || _claiming ? null : _claim, // greyed out until something is chosen
              child: Text(_claiming ? 'Claiming…' : 'Claim'),
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

// One item: its name, how much there is, its tags, and a switch to say you want it.
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.wanted, required this.onChanged});

  final DonationItem item;
  final bool wanted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ZhColors.text)),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantityLeft} ${item.unit}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ZhColors.primary),
                  ),
                ],
              ),
            ),
            Switch(value: wanted, onChanged: onChanged), // green when on (the theme's primary colour)
          ],
        ),
        if (item.categories.isNotEmpty || item.allergens.isNotEmpty) ...[
          const SizedBox(height: 12),
          TagChips(categories: item.categories, allergens: item.allergens),
        ],
      ],
    );
  }
}