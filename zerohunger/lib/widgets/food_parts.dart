// food_parts.dart
// Small pieces shared by Find food, Food details and Claimed: the words for tags, items and pickup times, an icon line, and read-only tag chips.

import 'package:flutter/material.dart';

import '../services/query_service.dart';
import '../theme/app_theme.dart';

// A tag as people read it, e.g. "TREE_NUTS" -> "Tree nuts".
String tagLabel(String tag) {
  final words = tag.toLowerCase().replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}

// The items in one line, e.g. "Jasmine rice · 6 portions, Bean stew · 4 portions".
String itemsSummary(List<DonationItem> items) =>
    items.map((item) => '${item.name} · ${item.quantityLeft} ${item.unit}').join(', ');

// The pickup window in words, e.g. "Today, 5–7 pm" or "Tomorrow, 12–2 pm".
String pickupWindowText(DateTime start, DateTime end) {
  final now = DateTime.now();
  // Days from today. UTC dates, so a daylight-saving change can't make a day 23 hours.
  final days = DateTime.utc(start.year, start.month, start.day)
      .difference(DateTime.utc(now.year, now.month, now.day))
      .inDays;
  final day = switch (days) {
    0 => 'Today',
    1 => 'Tomorrow',
    _ => '${_weekdays[start.weekday - 1]} ${start.day} ${_months[start.month - 1]}',
  };
  return '$day, ${_timeRange(start, end)}';
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

// "5–7 pm", or "11 am–1 pm" when the window crosses noon.
String _timeRange(DateTime start, DateTime end) {
  final a = _amPm(start), b = _amPm(end);
  return a == b ? '${_clock(start)}–${_clock(end)} $b' : '${_clock(start)} $a–${_clock(end)} $b';
}

// "5" for 5:00, "8:30" for 8:30.
String _clock(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return t.minute == 0 ? '$hour' : '$hour:${t.minute.toString().padLeft(2, '0')}';
}

String _amPm(DateTime t) => t.hour < 12 ? 'am' : 'pm';

// An icon and a line of text, e.g. a clock and "Today, 5–7 pm".
class IconLine extends StatelessWidget {
  const IconLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ZhColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: ZhColors.text))),
      ],
    );
  }
}

// A small read-only chip, e.g. "Halal". With warning: true (allergens) it's amber with a warning sign.
class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.warning = false});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warning ? ZhColors.warningContainer : ZhColors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warning) ...[
            const Icon(Icons.warning_amber_rounded, size: 16, color: ZhColors.warningIcon),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: warning ? ZhColors.onWarning : ZhColors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// Tags as chips: categories in green, then allergens in amber.
class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.categories, required this.allergens});

  final Iterable<String> categories;
  final Iterable<String> allergens;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in categories) InfoChip(tagLabel(tag)),
        for (final tag in allergens) InfoChip(tagLabel(tag), warning: true),
      ],
    );
  }
}