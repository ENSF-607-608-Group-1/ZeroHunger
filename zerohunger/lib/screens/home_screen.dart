// home_screen.dart
// The first screen. Anyone can use it, guests included.
//
//   Find food   -> the Find food screen (Done)
//   Donate food -> DonateFoodScreen, which asks guests to sign in first

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import 'donate_food_screen.dart';
import 'events_screen.dart';
import 'find_food_screen.dart';
import 'my_donations_screen.dart';
import 'post_event_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    // Redraws when the user changes, e.g. a guest signs in.
    return StreamBuilder<User?>(
      stream: auth.userChanges,
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isGuest = user == null || user.isAnonymous;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: ZhColors.background,
            foregroundColor: ZhColors.text,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 64,
            titleSpacing: 16,
            title: const Column(
              mainAxisSize: MainAxisSize.min, // only as tall as the two lines, so the bar centres them
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zero Hunger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ZhColors.text)),
                Text('Home', style: TextStyle(fontSize: 12, color: ZhColors.textSecondary)),
              ],
            ),
            actions: [AccountButton(user: user), const SizedBox(width: 8)],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Free food from people near you',
                style: TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w600, color: ZhColors.text),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help reduce food waste and share meals with your neighbours in Calgary.',
                style: TextStyle(fontSize: 14, height: 20 / 14, color: ZhColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _ActionCard(
                title: 'Find food',
                subtitle: 'Browse food you can claim',
                // Next step: open the Find food screen here.
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FindFoodScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'Donate food',
                subtitle: 'Post food you have',
                tag: isGuest ? 'Account needed' : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DonateFoodScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'My donations',
                subtitle: 'Manage food you’ve posted',
                tag: isGuest ? 'Account needed' : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyDonationsScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'Events',
                subtitle: 'Browse food distributions and donation events',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'Post an event',
                subtitle: 'Announce a food distribution or donation event',
                tag: isGuest ? 'Account needed' : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PostEventScreen()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// One of the two big cards: a title, a line under it, an arrow,
// and an optional grey tag beside the title, e.g. "Account needed".
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tag,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag; // a local copy, so Dart knows it can't change after the null check

    return Material(
      color: ZhColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ZhColors.divider),
      ),
      clipBehavior: Clip.antiAlias, // keeps the tap ripple inside the rounded corners
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The title, with the tag beside it (Wrap moves the tag down a line if there's no room).
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ZhColors.text)),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: ZhColors.divider, borderRadius: BorderRadius.circular(16)),
                            child: Text(
                              tag,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ZhColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: ZhColors.divider, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, size: 20, color: ZhColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

