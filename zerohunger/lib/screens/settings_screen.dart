// settings_screen.dart
// Lets the user set their area (postal code), food preferences, allergens to avoid,
// and whether notifications are on or off, so alerts fit their needs.
//
// Reached from the "Settings" section under the top-right Profile menu.
// Preferences are disabled until they can be stored persistently.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/account_settings_service.dart';
import '../services/auth_service.dart';
import '../services/zero_hunger_api.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/food_parts.dart';
import '../widgets/form_parts.dart';
import '../widgets/notification_button.dart';

// Canadian postal code once tidied up, e.g. "T2N 1N4" (matches donate_food_screen.dart).
final _postalCodePattern = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.accountSettingsService,
    this.accountAction,
  });

  final AccountSettingsService? accountSettingsService;
  final Widget? accountAction;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AccountSettingsService _service = widget.accountSettingsService ?? AccountSettingsService();
  late final AuthService? _auth = widget.accountAction == null ? AuthService() : null;

  final _formKey = GlobalKey<FormState>();
  final _postalCode = TextEditingController();

  final Set<String> _foodPreferences = {};
  final Set<String> _allergensToAvoid = {};
  bool _notificationsEnabled = true;

  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _postalCode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    if (!_service.isAvailable) {
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }
    try {
      final prefs = await _service.load();
      if (!mounted) return;
      _postalCode.text = prefs.postalCode;
      setState(() {
        _foodPreferences
          ..clear()
          ..addAll(prefs.foodPreferences);
        _allergensToAvoid
          ..clear()
          ..addAll(prefs.allergensToAvoid);
        _notificationsEnabled = prefs.notificationsEnabled;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  // Tidies a postal code the way people type it: "t2n1n4" -> "T2N 1N4".
  String _tidyPostalCode(String typed) {
    final letters = typed.toUpperCase().replaceAll(RegExp(r'\s'), '');
    if (letters.isEmpty) return '';
    return letters.length == 6 ? '${letters.substring(0, 3)} ${letters.substring(3)}' : letters;
  }

  String? _checkPostalCode(String? value) {
    final tidied = _tidyPostalCode(value ?? '');
    if (tidied.isEmpty) return null; // optional until the user wants nearby alerts
    return _postalCodePattern.hasMatch(tidied) ? null : 'Use the format A1A 1A1';
  }

  void _toggle(Set<String> tags, String tag) {
    setState(() {
      if (!tags.add(tag)) tags.remove(tag);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showZhMessage(context, 'Please fix the fields marked in red.');
      return;
    }

    final tidiedPostal = _tidyPostalCode(_postalCode.text);
    setState(() => _saving = true);
    try {
      await _service.saveSettings(
        postalCode: tidiedPostal,
        foodPreferences: _foodPreferences,
        allergensToAvoid: _allergensToAvoid,
        notificationsEnabled: _notificationsEnabled,
      );
      if (!mounted) return;
      _postalCode.text = tidiedPostal;
      setState(() => _saving = false);
      showZhMessage(context, 'Settings saved');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showZhMessage(context, 'Could not save settings. Please try again.', onRetry: _save);
    }
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
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          NotificationButton(accountAction: widget.accountAction),
          if (widget.accountAction != null)
            widget.accountAction!
          else
            StreamBuilder<User?>(
              stream: _auth!.userChanges,
              initialData: _auth.currentUser,
              builder: (context, snapshot) => AccountButton(user: snapshot.data, showSettings: false),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: (_loading || _loadFailed) ? null : _bottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: ZhColors.primaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.cloud_off_rounded, size: 36, color: ZhColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                _service.isAvailable ? 'Could not load settings' : 'Settings are not available yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ZhColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                _service.isAvailable
                    ? 'Check your connection and try again.'
                    : 'Preferences are not connected to a persistent store, so they cannot be loaded or saved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: ZhColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (_service.isAvailable)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ZhColors.primary,
                    foregroundColor: ZhColors.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Set your area and food needs so alerts match what you are looking for.',
            style: TextStyle(fontSize: 14, color: ZhColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Area: postal code
          const SectionHeading('Area'),
          _Panel(
            children: [
              TextFormField(
                controller: _postalCode,
                textCapitalization: TextCapitalization.characters,
                validator: _checkPostalCode,
                decoration: zhField(
                  label: 'Postal code',
                  hint: 'T2N 1N4',
                  helper: 'Used for alerts about food nearby',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Food preferences: Halal, Vegan, Vegetarian, Uncooked, Grain
          const SectionHeading('Food preferences'),
          _Panel(
            children: [
              const GroupLabel('Show alerts for these food types'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in foodCategoryOptions)
                    TagChip(
                      label: tagLabel(tag),
                      selected: _foodPreferences.contains(tag),
                      onTap: () => _toggle(_foodPreferences, tag),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Allergens to avoid: all 11 Health Canada priority allergens
          const SectionHeading('Allergens to avoid'),
          _Panel(
            children: [
              const GroupLabel('Health Canada priority allergens (11)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in allergenOptions)
                    TagChip(
                      label: tagLabel(tag),
                      selected: _allergensToAvoid.contains(tag),
                      warning: true,
                      onTap: () => _toggle(_allergensToAvoid, tag),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Notifications on or off
          const SectionHeading('Notifications'),
          _Panel(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alerts on',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ZhColors.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _notificationsEnabled
                              ? 'Receive alerts for nearby food, pickup chats, and events.'
                              : 'Notifications are paused.',
                          style: const TextStyle(fontSize: 13, color: ZhColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (on) => setState(() => _notificationsEnabled = on),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: ZhColors.surface,
        border: Border(top: BorderSide(color: ZhColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: FilledButton(
          style: zhPrimaryButton(),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save settings'),
        ),
      ),
    );
  }
}

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
