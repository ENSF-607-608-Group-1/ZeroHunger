// post_event_screen.dart
// Lets a signed-in donor or organization announce a food distribution or donation event.
// Guests see a sign-in notice (and get the sign-in sheet first), matching DonateFoodScreen.
//
//   form ──"Post event"──> DistributionService (TODO) ──DistributionScheduled──> Notification & Activity
//
// Until DistributionService / api-postEvent is built on the backend, submitting uses a local
// stub so the screen can be tested end-to-end; swap the TODO in _post() once the API is ready.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/query_service.dart';
import '../services/zero_hunger_api.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/form_parts.dart';
import 'sign_in_sheet.dart';

export '../services/query_service.dart' show EventKind;

// The 13 Canadian provinces and territories (same list as DonateFoodScreen).
const _provinces = ['AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT'];

// Canadian postal code once tidied up, e.g. "T2N 1N4".
final _postalCodePattern = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');

// Sample organizations a donor can post on behalf of until Organization queries exist.
const _defaultOrganizations = [
  'Calgary Food Bank',
  'Community Fridge YYC',
  'UCalgary Food Pantry',
];

// Form data sent when posting an event.
class PostEventData {
  final EventKind kind;
  final String title;
  final String comments;
  final String? organization;
  final PickupAddress address;
  final DateTime startTime;
  final DateTime endTime;

  const PostEventData({
    required this.kind,
    required this.title,
    this.comments = '',
    this.organization,
    required this.address,
    required this.startTime,
    required this.endTime,
  });
}

// Confirmation returned after an event is accepted.
class SubmittedEvent {
  final String eventId;
  final String title;
  final EventKind kind;

  const SubmittedEvent({
    required this.eventId,
    required this.title,
    required this.kind,
  });
}

typedef PostEventFn = Future<SubmittedEvent> Function(PostEventData data);

class PostEventScreen extends StatefulWidget {
  const PostEventScreen({
    super.key,
    this.onPostEvent,
    this.organizations = _defaultOrganizations,
    this.userStream,
    this.initialUser,
    this.signedInOverride,
  });

  final PostEventFn? onPostEvent;
  final List<String> organizations;
  final Stream<User?>? userStream;
  final User? initialUser;
  final bool? signedInOverride;

  @override
  State<PostEventScreen> createState() => _PostEventScreenState();
}

class _PostEventScreenState extends State<PostEventScreen> {
  AuthService? _authInstance;
  AuthService get _auth => _authInstance ??= AuthService();

  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  // Event details
  EventKind _kind = EventKind.foodDistribution;
  final _title = TextEditingController();
  final _comments = TextEditingController();
  String? _organization; // null = posting as yourself

  // Address
  final _street = TextEditingController();
  final _city = TextEditingController(text: 'Calgary');
  String _province = 'AB';
  final _postalCode = TextEditingController();

  // Date & time window
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _windowWrong = false;

  bool _posting = false;
  SubmittedEvent? _submitted;

  @override
  void initState() {
    super.initState();
    _resetWindow();
    if (widget.signedInOverride == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _auth.isGuest) showSignInSheet(context);
      });
    }
  }

  @override
  void dispose() {
    for (final field in [_title, _comments, _street, _city, _postalCode]) {
      field.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  // Default window: today, starting at the next full hour, for two hours.
  void _resetWindow() {
    final now = DateTime.now();
    final startHour = now.hour < 23 ? now.hour + 1 : 23;
    _date = DateTime(now.year, now.month, now.day);
    _startTime = TimeOfDay(hour: startHour, minute: 0);
    _endTime = startHour + 2 <= 23
        ? TimeOfDay(hour: startHour + 2, minute: 0)
        : const TimeOfDay(hour: 23, minute: 59);
    _windowWrong = false;
  }

  DateTime get _start => DateTime(_date.year, _date.month, _date.day, _startTime.hour, _startTime.minute);
  DateTime get _end => DateTime(_date.year, _date.month, _date.day, _endTime.hour, _endTime.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _windowWrong = false;
      });
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(context: context, initialTime: start ? _startTime : _endTime);
    if (picked == null) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
      _windowWrong = false;
    });
  }

  String _dateText(DateTime day) {
    final now = DateTime.now();
    final daysAway = DateTime.utc(day.year, day.month, day.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;
    if (daysAway == 0) return 'Today';
    if (daysAway == 1) return 'Tomorrow';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[day.month - 1]} ${day.day}';
  }

  String _timeText(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  // Validation
  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;

  String _tidyPostalCode(String typed) {
    final letters = typed.toUpperCase().replaceAll(RegExp(r'\s'), '');
    return letters.length == 6 ? '${letters.substring(0, 3)} ${letters.substring(3)}' : letters;
  }

  String? _checkPostalCode(String? value) =>
      _postalCodePattern.hasMatch(_tidyPostalCode(value ?? '')) ? null : 'Use the format A1A 1A1';

  // Default placeholder submission until DistributionService is built.
  Future<SubmittedEvent> _defaultPostEvent(PostEventData data) async {
    // TODO: Replace with DistributionService.postEvent(data) once api-postEvent is built.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final id = 'evt-${DateTime.now().millisecondsSinceEpoch}';
    return SubmittedEvent(eventId: id, title: data.title, kind: data.kind);
  }

  Future<void> _post() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState!.validate();
    final windowOk = _end.isAfter(_start);
    setState(() => _windowWrong = !windowOk);
    if (!formOk || !windowOk) {
      showZhMessage(context, 'Please fix the fields marked in red.');
      return;
    }

    final payload = PostEventData(
      kind: _kind,
      title: _title.text.trim(),
      comments: _comments.text.trim(),
      organization: _organization,
      address: PickupAddress(
        line1: _street.text.trim(),
        city: _city.text.trim(),
        province: _province,
        postalCode: _tidyPostalCode(_postalCode.text),
      ),
      startTime: _start,
      endTime: _end,
    );

    setState(() => _posting = true);
    try {
      final submitFn = widget.onPostEvent ?? _defaultPostEvent;
      final submitted = await submitFn(payload);
      if (!mounted) return;
      setState(() {
        _submitted = submitted;
        _title.clear();
        _comments.clear();
      });
      if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        showSignInSheet(context);
      } else {
        showZhMessage(context, e.message, onRetry: e.code == 'unavailable' ? _post : null);
      }
    } catch (_) {
      if (mounted) showZhMessage(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.signedInOverride != null) {
      return _scaffold(user: widget.initialUser, signedIn: widget.signedInOverride!);
    }

    return StreamBuilder<User?>(
      stream: widget.userStream ?? _auth.userChanges,
      initialData: widget.initialUser ?? _auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final signedIn = user != null && !user.isAnonymous;
        return _scaffold(user: user, signedIn: signedIn);
      },
    );
  }

  Widget _scaffold({required User? user, required bool signedIn}) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZhColors.background,
        foregroundColor: ZhColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: const Text(
          'Post an event',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          if (widget.signedInOverride == null) AccountButton(user: user),
          const SizedBox(width: 8),
        ],
      ),
      body: signedIn
          ? _form()
          : _GuestNotice(onSignIn: () => showSignInSheet(context)),
      bottomNavigationBar: signedIn ? _bottomBar() : null,
    );
  }

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
              _SuccessCard(submitted: _submitted!, onClose: () => setState(() => _submitted = null)),
              const SizedBox(height: 24),
            ],

            // Kind
            const SectionHeading('Event kind'),
            SegmentedButton<EventKind>(
              segments: const [
                ButtonSegment(value: EventKind.foodDistribution, label: Text('Food distribution')),
                ButtonSegment(value: EventKind.donationEvent, label: Text('Donation event')),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (picked) => setState(() => _kind = picked.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: ZhColors.primaryContainer,
                selectedForegroundColor: ZhColors.onPrimaryContainer,
                foregroundColor: ZhColors.textSecondary,
                side: const BorderSide(color: ZhColors.outline),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _kind.description,
                style: const TextStyle(fontSize: 12, color: ZhColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // Details
            const SectionHeading('Event details'),
            TextFormField(
              controller: _title,
              maxLength: 80,
              validator: _required,
              onChanged: (_) => setState(() {}),
              decoration: zhField(
                label: 'Title',
                hint: _kind == EventKind.foodDistribution
                    ? 'e.g. Saturday Community Food Distribution'
                    : 'e.g. Campus Canned Food Drive',
                suffixText: '${_title.text.length}/80',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _comments,
              minLines: 3,
              maxLines: 5,
              decoration: zhField(
                label: 'Comments (optional)',
                hint: 'Add details such as what to bring, parking, or pickup instructions',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _organization,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None (posting as yourself)'),
                ),
                for (final org in widget.organizations)
                  DropdownMenuItem<String?>(value: org, child: Text(org)),
              ],
              onChanged: (org) => setState(() => _organization = org),
              decoration: zhField(
                label: 'Organization (optional)',
                helper: 'Choose an organization if you are posting on its behalf',
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              ),
            ),
            const SizedBox(height: 24),

            // Address
            const SectionHeading('Address'),
            TextFormField(
              controller: _street,
              validator: _required,
              decoration: zhField(label: 'Street address', hint: 'e.g. 2500 University Dr NW'),
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
                    items: [for (final p in _provinces) DropdownMenuItem(value: p, child: Text(p))],
                    onChanged: (p) => setState(() => _province = p ?? _province),
                    decoration: zhField(label: 'Province', padding: const EdgeInsets.fromLTRB(12, 16, 8, 16)),
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
                  decoration: zhField(label: 'Postal code', hint: 'A1A 1A1', helper: 'Format: A1A 1A1'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date and time
            const SectionHeading('Date and time'),
            PickerField(
              label: 'Date',
              value: _dateText(_date),
              icon: Icons.calendar_today_rounded,
              onTap: _pickDate,
              hasError: _windowWrong,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PickerField(
                    label: 'Start time',
                    value: _timeText(_startTime),
                    icon: Icons.schedule_rounded,
                    onTap: () => _pickTime(start: true),
                    hasError: _windowWrong,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PickerField(
                    label: 'End time',
                    value: _timeText(_endTime),
                    icon: Icons.schedule_rounded,
                    onTap: () => _pickTime(start: false),
                    hasError: _windowWrong,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Event must end after it starts.',
                style: TextStyle(fontSize: 12, color: _windowWrong ? ZhColors.error : ZhColors.textSecondary),
              ),
            ),
          ],
        ),
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
        child: FilledButton.icon(
          style: zhPrimaryButton(),
          onPressed: _posting ? null : _post,
          icon: _posting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ZhColors.onPrimary),
                )
              : const Icon(Icons.event_available_rounded, size: 20),
          label: Text(_posting ? 'Posting…' : 'Post event'),
        ),
      ),
    );
  }
}

// Shown to guests instead of the form.
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
              decoration: const BoxDecoration(color: ZhColors.warningContainer, shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline_rounded, size: 40, color: ZhColors.warningIcon),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in to post an event',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
            ),
            const SizedBox(height: 8),
            const Text(
              "Only signed-in donors and organizations can post events. It's free.",
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

// Green confirmation card shown after submitting an event.
class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.submitted, required this.onClose});

  final SubmittedEvent submitted;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
      decoration: BoxDecoration(color: ZhColors.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 32, color: ZhColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submitted',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ZhColors.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${submitted.title}" (${submitted.kind.label.toLowerCase()}) has been submitted. Nearby users and followers will be notified once it is live.',
                  style: const TextStyle(fontSize: 14, color: ZhColors.onPrimaryContainer),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Event ID: ${submitted.eventId}',
                  style: const TextStyle(fontSize: 12, color: ZhColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20, color: ZhColors.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
