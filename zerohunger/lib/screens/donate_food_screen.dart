// donate_food_screen.dart
//Only signed-in users can donate:a guest who opens it gets the sign-in sheet first
//
//   form ──"Post food"──> ZeroHungerApi.postFood ──> api-postFood ──PostFood──> Listing processor
//
// After posting, a green "Submitted" card appears at the top. The listing goes live

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/zero_hunger_api.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/form_parts.dart';
import '../widgets/notification_button.dart';
import 'sign_in_sheet.dart';

// The choices in the dropdowns
//DO NOT CHANGE PLS
const _units = ['portions', 'items', 'kg', 'lb', 'litres'];
const _provinces = [
  'AB',
  'BC',
  'MB',
  'NB',
  'NL',
  'NS',
  'NT',
  'NU',
  'ON',
  'PE',
  'QC',
  'SK',
  'YT',
];

// A Canadian postal code once tidied up, e.g. "T2N 1N4" (the same rule the Listing processor checks).
final _postalCodePattern = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');

class DonateFoodScreen extends StatefulWidget {
  const DonateFoodScreen({super.key});

  @override
  State<DonateFoodScreen> createState() => _DonateFoodScreenState();
}

class _DonateFoodScreenState extends State<DonateFoodScreen> {
  final _auth = AuthService();
  final _api = ZeroHungerApi();
  final _formKey = GlobalKey<FormState>(); // lets us check every field at once
  final _scroll =
      ScrollController(); // lets us scroll back up to the success card

  // What the donor types in.
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController(text: 'Calgary');
  final _postalCode = TextEditingController();
  String _province = 'AB';
  final List<_ItemDraft> _items = [
    _ItemDraft(),
  ]; // a donation needs at least one item

  // The pickup window: a day, a start time and an end time.
  late DateTime _date;
  late TimeOfDay _from;
  late TimeOfDay _to;
  bool _windowWrong = false; // true shows the pickup window in red

  bool _posting = false; // true while waiting for api-postFood
  Submitted? _submitted; // the last post, shown in the green card

  @override
  void initState() {
    super.initState();
    _resetWindow();
    // Guests can't donate: once the screen is showing, ask them to sign in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _auth.isGuest) showSignInSheet(context);
    });
  }

  @override
  void dispose() {
    for (final field in [_title, _description, _street, _city, _postalCode]) {
      field.dispose();
    }
    for (final item in _items) {
      item.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  // PICKUP window

  // Default window: today, starting at the next full hour, for two hours.
  void _resetWindow() {
    final now = DateTime.now();
    final startHour = now.hour < 23 ? now.hour + 1 : 23;
    _date = DateTime(now.year, now.month, now.day);
    _from = TimeOfDay(hour: startHour, minute: 0);
    _to = startHour + 2 <= 23
        ? TimeOfDay(hour: startHour + 2, minute: 0)
        : const TimeOfDay(hour: 23, minute: 59);
    _windowWrong = false;
  }

  DateTime get _start =>
      DateTime(_date.year, _date.month, _date.day, _from.hour, _from.minute);
  DateTime get _end =>
      DateTime(_date.year, _date.month, _date.day, _to.hour, _to.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool from}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: from ? _from : _to,
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
      _windowWrong = false;
    });
  }

  // "Today", "Tomorrow" or e.g. "Nov 20".
  String _dateText(DateTime day) {
    final now = DateTime.now();
    final daysAway = DateTime(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (daysAway == 0) return 'Today';
    if (daysAway == 1) return 'Tomorrow';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[day.month - 1]} ${day.day}';
  }

  // e.g. "14:00"
  String _timeText(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Checks
  // ---------------------------------------------------------------------------

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  // Tidies a postal code the way people type it: "t2n1n4" → "T2N 1N4".
  String _tidyPostalCode(String typed) {
    final letters = typed.toUpperCase().replaceAll(RegExp(r'\s'), '');
    return letters.length == 6
        ? '${letters.substring(0, 3)} ${letters.substring(3)}'
        : letters;
  }

  String? _checkPostalCode(String? value) =>
      _postalCodePattern.hasMatch(_tidyPostalCode(value ?? ''))
      ? null
      : 'Use the format A1A 1A1';

  // Items

  void _addItem() => setState(() => _items.add(_ItemDraft()));

  void _removeItem(_ItemDraft item) {
    setState(() => _items.remove(item));
    // Free its text box after the screen has redrawn without it.
    WidgetsBinding.instance.addPostFrameCallback((_) => item.dispose());
  }

  // Turns a tag on or off, e.g. adds or removes "VEGAN".
  void _toggle(Set<String> tags, String tag) {
    setState(() {
      if (!tags.add(tag)) tags.remove(tag);
    });
  }

  // "TREE_NUTS" → "Tree nuts", for the chip labels.
  String _tagText(String tag) {
    final words = tag.toLowerCase().replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }

  // Posting

  Future<void> _post() async {
    FocusScope.of(context).unfocus(); // closes the keyboard
    final formOk = _formKey.currentState!
        .validate(); // shows "Required" etc. in red
    final windowOk = _end.isAfter(_start);
    setState(() => _windowWrong = !windowOk);
    if (!formOk || !windowOk) {
      showZhMessage(context, 'Please fix the fields marked in red.');
      return;
    }

    setState(() => _posting = true);
    try {
      final submitted = await _api.postFood(
        title: _title.text.trim(),
        description: _description.text.trim(),
        items: _items.map((item) => item.toFoodItem()).toList(),
        address: PickupAddress(
          line1: _street.text.trim(),
          city: _city.text.trim(),
          province: _province,
          postalCode: _tidyPostalCode(_postalCode.text),
        ),
        pickupStart: _start,
        pickupEnd: _end,
      );
      debugPrint(
        'Posted. donationId: ${submitted.donationId}, correlationId: ${submitted.correlationId}',
      );
      if (!mounted) return;
      setState(() {
        _submitted = submitted;
        _clearFood();
      });
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        showSignInSheet(context); // e.g. they signed out somewhere else
      } else {
        showZhMessage(
          context,
          e.message,
          onRetry: e.code == 'unavailable' ? _post : null,
        );
      }
    } on DonationPersistenceException catch (e, stackTrace) {
      debugPrint('$e\n$stackTrace');
      if (mounted) {
        showZhMessage(context, e.toString());
      }
    } catch (e, stackTrace) {
      debugPrint('Donation submission failed: $e\n$stackTrace');
      if (mounted) {
        showZhMessage(
          context,
          'Could not submit or save the donation. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  // After posting: empty the food fields. The address and pickup window stay for the next post.
  void _clearFood() {
    _title.clear();
    _description.clear();
    final old = List.of(_items);
    _items
      ..clear()
      ..add(_ItemDraft());
    // Free the old items' text boxes after the screen has redrawn without them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final item in old) {
        item.dispose();
      }
    });
  }

  // The screen

  @override
  Widget build(BuildContext context) {
    // Redraws whenever the user changes, e.g. a guest signs in from the sheet.
    return StreamBuilder<User?>(
      stream: _auth.userChanges,
      initialData: _auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final signedIn = user != null && !user.isAnonymous;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: ZhColors.background,
            foregroundColor: ZhColors.text,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 64,
            title: const Text(
              'Donate food',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: ZhColors.text,
              ),
            ),
            actions: [
              const NotificationButton(),
              AccountButton(user: user),
              const SizedBox(width: 8),
            ],
          ),
          body: signedIn
              ? _form()
              : _GuestNotice(onSignIn: () => showSignInSheet(context)),
          bottomNavigationBar: signedIn ? _bottomBar() : null,
        );
      },
    );
  }

  // The form, top to bottom, as in the design.
  Widget _form() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_submitted != null) ...[
              _SuccessCard(
                submitted: _submitted!,
                onClose: () => setState(() => _submitted = null),
              ),
              const SizedBox(height: 24),
            ],

            // What are you donating?
            const SectionHeading('What are you donating?'),
            TextFormField(
              controller: _title,
              maxLength: 60,
              validator: _required,
              onChanged: (_) =>
                  setState(() {}), // keeps the 0/60 counter up to date
              decoration: zhField(
                label: 'Title',
                hint: 'e.g. Rice and bean stew',
                suffixText: '${_title.text.length}/60',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: zhField(
                label: 'Description (optional)',
                hint: 'Add details such as packaging, reheat instructions, or pickup notes',
              ),
            ),
            const SizedBox(height: 24),

            // Items
            const SectionHeading('Items'),
            for (final item in _items) ...[
              _itemCard(item),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add another item'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ZhColors.primary,
                side: const BorderSide(color: ZhColors.primary),
                minimumSize: const Size.fromHeight(44),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pickup address
            const SectionHeading('Pickup address'),
            TextFormField(
              controller: _street,
              validator: _required,
              decoration: zhField(
                label: 'Street address',
                hint: 'e.g. 615 Macleod Trail SE',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    validator: _required,
                    decoration: zhField(label: 'City'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    initialValue: _province,
                    items: [
                      for (final p in _provinces)
                        DropdownMenuItem(value: p, child: Text(p)),
                    ],
                    onChanged: (p) =>
                        setState(() => _province = p ?? _province),
                    decoration: zhField(
                      label: 'Province',
                      padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 180,
                child: TextFormField(
                  controller: _postalCode,
                  textCapitalization: TextCapitalization.characters,
                  validator: _checkPostalCode,
                  decoration: zhField(
                    label: 'Postal code',
                    hint: 'A1A 1A1',
                    helper: 'Format: A1A 1A1',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pickup window: the widths keep the design's 132 : 112 : 112 split on any phone.
            const SectionHeading('Pickup window'),
            Row(
              children: [
                Expanded(
                  flex: 132,
                  child: PickerField(
                    label: 'Date',
                    value: _dateText(_date),
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickDate,
                    hasError: _windowWrong,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 112,
                  child: PickerField(
                    label: 'From',
                    value: _timeText(_from),
                    icon: Icons.schedule_rounded,
                    onTap: () => _pickTime(from: true),
                    hasError: _windowWrong,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 112,
                  child: PickerField(
                    label: 'To',
                    value: _timeText(_to),
                    icon: Icons.schedule_rounded,
                    onTap: () => _pickTime(from: false),
                    hasError: _windowWrong,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Pickup must end after it starts.',
                style: TextStyle(
                  fontSize: 12,
                  color: _windowWrong ? ZhColors.error : ZhColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // One item's card: name, quantity, unit, categories and allergens.
  Widget _itemCard(_ItemDraft item) {
    return Container(
      key: ObjectKey(
        item,
      ), // keeps each card's fields with its own item when one is removed
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.name,
                  validator: _required,
                  decoration: zhField(label: 'Item name', hint: 'e.g. Rice'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove item',
                color: ZhColors.textSecondary,
                // A donation needs at least one item, so the last one can't be removed.
                onPressed: _items.length > 1 ? () => _removeItem(item) : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              QuantityStepper(
                value: item.quantity,
                onChanged: (q) => setState(() => item.quantity = q),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: item.unit,
                  items: [
                    for (final u in _units)
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (u) => setState(() => item.unit = u ?? item.unit),
                  decoration: zhField(
                    label: 'Unit',
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const GroupLabel('Categories'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in foodCategoryOptions)
                TagChip(
                  label: _tagText(category),
                  selected: item.categories.contains(category),
                  onTap: () => _toggle(item.categories, category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const GroupLabel('Allergens'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final allergen in allergenOptions)
                TagChip(
                  label: _tagText(allergen),
                  selected: item.allergens.contains(allergen),
                  warning: true,
                  onTap: () => _toggle(item.allergens, allergen),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // The bar pinned to the bottom with the "Post food" button (spinner while posting).
  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: ZhColors.surface,
        border: Border(top: BorderSide(color: ZhColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          style: zhPrimaryButton(),
          onPressed: _posting ? null : _post,
          icon: _posting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ZhColors.onPrimary,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 20),
          label: Text(_posting ? 'Posting…' : 'Post food'),
        ),
      ),
    );
  }
}

// One item card's values while the donor fills in the form.
class _ItemDraft {
  final name = TextEditingController();
  int quantity = 1;
  String unit = 'portions';
  final categories = <String>{}; // e.g. {"HALAL", "VEGAN"}
  final allergens = <String>{}; // e.g. {"SOY"}

  FoodItem toFoodItem() => FoodItem(
    name: name.text.trim(),
    categories: categories.toList(),
    allergens: allergens.toList(),
    quantity: quantity,
    unit: unit,
  );

  void dispose() => name.dispose();
}

// What a guest sees on this screen (behind the sheet, or after tapping "Not now").
class _GuestNotice extends StatelessWidget {
  const _GuestNotice({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: ZhColors.warningContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: ZhColors.warningIcon,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in to donate food',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: ZhColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Only signed-in users can donate. It's free.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ZhColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: zhPrimaryButton(),
              onPressed: onSignIn,
              child: const Text('Sign in or create account'),
            ),
          ],
        ),
      ),
    );
  }
}

// The green card shown after posting: the post was accepted and goes live in a moment.
class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.submitted, required this.onClose});

  final Submitted submitted;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
      decoration: BoxDecoration(
        color: ZhColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 32,
            color: ZhColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submitted',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ZhColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Your food is being listed. People nearby will be told once it's live.",
                  style: TextStyle(
                    fontSize: 14,
                    color: ZhColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Donation ID: ${submitted.donationId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ZhColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: ZhColors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
