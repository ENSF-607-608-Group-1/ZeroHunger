// claimed_screen.dart
// Shown after a successful claim: the pickup code, where and when to pick up, and what was claimed.
//
//   FoodDetailsScreen -> api-claimFood answers -> ClaimedScreen
//
// Until the database exists, the pickup times are the Claim processor's placeholders
// (now to 2 hours from now) and the address comes from the sample donation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/query_service.dart';
import '../services/zero_hunger_api.dart';
import '../theme/app_theme.dart';
import '../widgets/food_parts.dart';

class ClaimedScreen extends StatelessWidget {
  const ClaimedScreen({super.key, required this.donation, required this.items, required this.result});

  final Donation donation;         // the donation the food came from
  final List<DonationItem> items;  // the items that were switched on
  final ClaimResult result;        // api-claimFood's answer: the reservation and pickup code

  @override
  Widget build(BuildContext context) {
    // The cloud sends times in UTC; show them in the phone's time zone.
    final start = result.pickupStart.toLocal();
    final end = result.pickupEnd.toLocal();

    // TODO: Review when database is complete. Take the address from api-claimFood's answer
    //   (ClaimResult) instead of the listing, so it stays hidden until someone claims.
    final address = donation.address;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZhColors.background,
        foregroundColor: ZhColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: const Text(
          'Claimed',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            "You're all set!",
            style: TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w600, color: ZhColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Your food from ${donation.title} is reserved.',
            style: const TextStyle(fontSize: 15, color: ZhColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _CodeCard(code: result.pickupCode),
          const SizedBox(height: 16),
          _Panel(
            children: [
              const _Label('Pickup address'),
              Text(address.line1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ZhColors.text)),
              Text(
                '${address.city}, ${address.province} ${address.postalCode}',
                style: const TextStyle(fontSize: 15, color: ZhColors.text),
              ),
              const SizedBox(height: 16),
              const _Label('Pickup time'),
              Text(
                pickupWindowText(start, end),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ZhColors.text),
              ),
              const SizedBox(height: 2),
              Text(
                _startsIn(start, end),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ZhColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Panel(
            children: [
              const _Label('What you claimed'),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      item.name,
                    style: const TextStyle(fontSize: 15, color: ZhColors.text),
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            style: zhPrimaryButton(),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), // back to Home
            child: const Text('Back to home'),
          ),
        ),
      ),
    );
  }
}

// When pickup starts, in words: "Starts in 1 h 45 min", "Pickup is open now" or "The pickup time has passed".
String _startsIn(DateTime start, DateTime end) {
  final now = DateTime.now();
  if (now.isAfter(end)) return 'The pickup time has passed';
  if (!now.isBefore(start)) return 'Pickup is open now';
  final wait = start.difference(now);
  final hours = wait.inHours, minutes = wait.inMinutes % 60;
  if (hours == 0) return 'Starts in $minutes min';
  return minutes == 0 ? 'Starts in $hours h' : 'Starts in $hours h $minutes min';
}

// The pickup code in large digits, with a button to copy it.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    // "615318" -> "615 318", easier to read out at pickup.
    final shown = code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ZhColors.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text(
            'PICKUP CODE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: ZhColors.onPrimaryContainer),
          ),
          const SizedBox(height: 8),
          Text(
            shown,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: 4, color: ZhColors.onPrimaryContainer),
          ),
          const SizedBox(height: 8),
          const Text(
            'Show this code to the donor when you pick up.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: ZhColors.onPrimaryContainer),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) showZhMessage(context, 'Pickup code copied');
            },
            child: const Text('Copy code'),
          ),
        ],
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

// A small grey heading inside a panel, e.g. "Pickup address".
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ZhColors.textSecondary),
      ),
    );
  }
}