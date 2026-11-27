// form_parts.dart
// Small building blocks from the Stitch designs, shared by the screens:
// headings, tag chips, the quantity stepper and the tap-to-pick date/time field.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// A section heading, e.g. "Items": 16 sp, weight 600, 8 dp above its content.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ZhColors.text)),
    );
  }
}

// A small grey label above a group of chips, e.g. "Categories".
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ZhColors.textSecondary)),
    );
  }
}

// A chip you tap on and off, e.g. "Vegan": 32 dp tall, 12 dp side padding, 8 dp corners.
// Selected chips are green with a tick; with warning: true (allergens) they are amber with a warning sign.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.warning = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final fill = !selected ? ZhColors.surface : (warning ? ZhColors.warningContainer : ZhColors.primaryContainer);
    final edge = !selected ? ZhColors.outline : (warning ? ZhColors.warningIcon : ZhColors.primary);
    final ink = !selected ? ZhColors.text : (warning ? ZhColors.onWarning : ZhColors.onPrimaryContainer);

    return Material(
      color: fill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: edge)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  warning ? Icons.warning_rounded : Icons.check_rounded,
                  size: 18,
                  color: warning ? ZhColors.warningIcon : ZhColors.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ink)),
            ],
          ),
        ),
      ),
    );
  }
}

// The "−  6  +" box for an item's quantity: 140 × 48 dp, 1 dp outline, 12 dp corners.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.min = 1, this.max = 999});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 48,
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      // A see-through Material so the tap ripple shows on top of the white box.
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _button(Icons.remove_rounded, 'Less', value > min ? () => onChanged(value - 1) : null),
            Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ZhColors.text)),
            _button(Icons.add_rounded, 'More', value < max ? () => onChanged(value + 1) : null),
          ],
        ),
      ),
    );
  }

  // One of the − / + buttons. onTap is null (greyed out) at the lowest or highest value.
  Widget _button(IconData icon, String tooltip, VoidCallback? onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 20, color: onTap == null ? ZhColors.outline : ZhColors.text),
        ),
      ),
    );
  }
}

// A field you tap to pick a date or time, styled like the text fields,
// e.g. "Date  Today" with a calendar icon. hasError draws it with a red border.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.hasError = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: zhField(
          label: label,
          padding: const EdgeInsets.fromLTRB(12, 16, 4, 16),
          suffixIcon: Icon(icon, size: 20, color: ZhColors.textSecondary),
        ).copyWith(
          suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          // An empty error turns the border red without adding a line of text underneath.
          errorText: hasError ? '' : null,
          errorStyle: const TextStyle(fontSize: 0, height: 0),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, color: ZhColors.text),
        ),
      ),
    );
  }
}