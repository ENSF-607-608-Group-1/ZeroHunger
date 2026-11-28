// my_donations_screen.dart
// Lets a signed-in donor see and manage the food they've posted:
//   - View each donation's title, status, amount left and pickup time
//   - Update amount left  -> ZeroHungerApi.updateQuantity
//   - Reschedule pickup   -> ZeroHungerApi.rescheduleDonation
//   - Cancel donation     -> ZeroHungerApi.cancelDonation
//   - Open pickup chats   -> pickup chats for that donation
//
// The current schema does not associate donations with their posting user.
// Successful updates apply immediately in the UI after the backend accepts the event.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/query_service.dart';
import '../services/zero_hunger_api.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/food_parts.dart';
import '../widgets/form_parts.dart';
import 'donate_food_screen.dart';
import 'sign_in_sheet.dart';

typedef UpdateQuantityFn = Future<Submitted> Function({
  required String donationId,
  required int newQuantity,
});

typedef RescheduleDonationFn = Future<Submitted> Function({
  required String donationId,
  required DateTime newPickupStart,
  required DateTime newPickupEnd,
});

typedef CancelDonationFn = Future<Submitted> Function({
  required String donationId,
  String? reason,
});

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({
    super.key,
    this.queryService,
    this.updateQuantity,
    this.rescheduleDonation,
    this.cancelDonation,
    this.onOpenPickupChats,
    this.userStream,
    this.initialUser,
    this.signedInOverride,
  });

  final QueryService? queryService;
  final UpdateQuantityFn? updateQuantity;
  final RescheduleDonationFn? rescheduleDonation;
  final CancelDonationFn? cancelDonation;
  final ValueChanged<DonorDonation>? onOpenPickupChats;
  final Stream<User?>? userStream;
  final User? initialUser;
  final bool? signedInOverride;

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  AuthService? _authInstance;
  ZeroHungerApi? _apiInstance;
  late final QueryService _query = widget.queryService ?? QueryService();

  AuthService get _auth => _authInstance ??= AuthService();
  ZeroHungerApi get _api => _apiInstance ??= ZeroHungerApi();

  List<DonorDonation>? _donations;
  bool _loading = true;
  bool _loadFailed = false;
  DonationStatus? _statusFilter; // null shows all statuses

  @override
  void initState() {
    super.initState();
    _loadDonations();
    if (widget.signedInOverride == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _auth.isGuest) showSignInSheet(context);
      });
    }
  }

  Future<void> _loadDonations() async {
    setState(() {
      _loading = _donations == null;
      _loadFailed = false;
    });
    try {
      final list = await _query.myDonations();
      if (!mounted) return;
      setState(() {
        _donations = List<DonorDonation>.from(list);
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

  UpdateQuantityFn get _updateQuantityCall =>
      widget.updateQuantity ??
      ({required String donationId, required int newQuantity}) =>
          _api.updateQuantity(donationId: donationId, newQuantity: newQuantity);

  RescheduleDonationFn get _rescheduleCall =>
      widget.rescheduleDonation ??
      ({
        required String donationId,
        required DateTime newPickupStart,
        required DateTime newPickupEnd,
      }) =>
          _api.rescheduleDonation(
            donationId: donationId,
            newPickupStart: newPickupStart,
            newPickupEnd: newPickupEnd,
          );

  CancelDonationFn get _cancelCall =>
      widget.cancelDonation ??
      ({required String donationId, String? reason}) =>
          _api.cancelDonation(donationId: donationId, reason: reason);

  void _replaceDonation(DonorDonation updated) {
    setState(() {
      final list = _donations;
      if (list == null) return;
      final index = list.indexWhere((d) => d.donationId == updated.donationId);
      if (index != -1) list[index] = updated;
    });
  }

  Future<void> _openUpdateAmount(DonorDonation donation) async {
    final updatedAmount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ZhColors.surface,
      barrierColor: const Color(0x66000000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _UpdateAmountSheet(
        donation: donation,
        onSave: (newQuantity) => _updateQuantityCall(donationId: donation.donationId, newQuantity: newQuantity),
        onAuthRequired: () => showSignInSheet(context),
      ),
    );
    if (updatedAmount == null || !mounted) return;

    _replaceDonation(donation.copyWith(amountLeft: updatedAmount));
    showZhMessage(context, 'Amount left updated to $updatedAmount ${donation.unit}.');
  }

  Future<void> _openReschedule(DonorDonation donation) async {
    final result = await showModalBottomSheet<_RescheduleResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ZhColors.surface,
      barrierColor: const Color(0x66000000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _RescheduleSheet(
        donation: donation,
        onSave: (start, end) => _rescheduleCall(
          donationId: donation.donationId,
          newPickupStart: start,
          newPickupEnd: end,
        ),
        onAuthRequired: () => showSignInSheet(context),
      ),
    );
    if (result == null || !mounted) return;

    _replaceDonation(donation.copyWith(pickupStart: result.start, pickupEnd: result.end));
    showZhMessage(context, 'Pickup rescheduled to ${pickupWindowText(result.start, result.end)}.');
  }

  Future<void> _openCancel(DonorDonation donation) async {
    final result = await showModalBottomSheet<_CancelResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ZhColors.surface,
      barrierColor: const Color(0x66000000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _CancelDonationSheet(
        donation: donation,
        onConfirm: (reason) => _cancelCall(donationId: donation.donationId, reason: reason),
        onAuthRequired: () => showSignInSheet(context),
      ),
    );
    if (result == null || !mounted) return;

    _replaceDonation(
      donation.copyWith(
        status: DonationStatus.cancelled,
        cancelReason: result.reason,
      ),
    );
    showZhMessage(context, 'Donation cancelled.');
  }

  void _openPickupChats(DonorDonation donation) {
    if (widget.onOpenPickupChats != null) {
      widget.onOpenPickupChats!(donation);
      return;
    }
    // TODO: Navigate directly to PickupChatScreen once it is built.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ZhColors.surface,
      barrierColor: const Color(0x66000000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _PickupChatsSheet(donation: donation),
    );
  }

  List<DonorDonation> get _visibleDonations {
    final all = _donations ?? const [];
    if (_statusFilter == null) return all;
    return all.where((d) => d.status == _statusFilter).toList();
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
          'My donations',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          if (widget.signedInOverride == null) AccountButton(user: user),
          const SizedBox(width: 8),
        ],
      ),
      body: signedIn
          ? _donationsBody()
          : _GuestNotice(onSignIn: () => showSignInSheet(context)),
    );
  }

  Widget _donationsBody() {
    return Column(
      children: [
        _statusFilterRow(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadDonations,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (_loadFailed)
                        const _Notice(
                          icon: Icons.cloud_off_rounded,
                          title: 'Could not load your donations',
                          subtitle: 'Check your connection, then pull down to try again.',
                        )
                      else if (_visibleDonations.isEmpty)
                        _Notice(
                          icon: Icons.volunteer_activism_outlined,
                          title: _statusFilter == null
                              ? 'Your donations are not available yet'
                              : 'No ${_statusFilter!.label.toLowerCase()} donations',
                          subtitle: _statusFilter == null
                              ? 'The current database does not link donations to their owner.'
                              : 'Try choosing another status filter.',
                          actionLabel: _statusFilter == null ? 'Donate food' : null,
                          onAction: _statusFilter == null
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DonateFoodScreen()),
                                  )
                              : null,
                        )
                      else
                        for (final donation in _visibleDonations) ...[
                          _DonorDonationCard(
                            donation: donation,
                            onUpdateAmount: () => _openUpdateAmount(donation),
                            onReschedule: () => _openReschedule(donation),
                            onCancel: () => _openCancel(donation),
                            onOpenChats: () => _openPickupChats(donation),
                          ),
                          const SizedBox(height: 16),
                        ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _statusFilterRow() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          TagChip(
            label: 'All',
            selected: _statusFilter == null,
            onTap: () => setState(() => _statusFilter = null),
          ),
          const SizedBox(width: 8),
          for (final status in DonationStatus.values) ...[
            TagChip(
              label: status.label,
              selected: _statusFilter == status,
              onTap: () => setState(() {
                _statusFilter = _statusFilter == status ? null : status;
              }),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// One row/card for a donor's posted donation: title, status, amount left, pickup time,
// and quick buttons to update amount left, reschedule, cancel, or open pickup chats.
class _DonorDonationCard extends StatelessWidget {
  const _DonorDonationCard({
    required this.donation,
    required this.onUpdateAmount,
    required this.onReschedule,
    required this.onCancel,
    required this.onOpenChats,
  });

  final DonorDonation donation;
  final VoidCallback onUpdateAmount;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback onOpenChats;

  @override
  Widget build(BuildContext context) {
    final d = donation;
    final canUpdateAmount = d.status == DonationStatus.available;
    final canRescheduleOrCancel = d.status == DonationStatus.available || d.status == DonationStatus.claimed;
    final chatCount = d.pickupChats.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and status badge. Wrap prevents overflow at large text sizes.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ZhColors.text),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: d.status),
            ],
          ),
          const SizedBox(height: 12),
          IconLine(
            icon: Icons.inventory_2_outlined,
            text: '${d.amountLeft} ${d.unit} left',
          ),
          const SizedBox(height: 8),
          IconLine(
            icon: Icons.schedule_rounded,
            text: pickupWindowText(d.pickupStart, d.pickupEnd),
          ),
          if (d.status == DonationStatus.cancelled &&
              d.cancelReason != null &&
              d.cancelReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${d.cancelReason}',
              style: const TextStyle(fontSize: 13, color: ZhColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: ZhColors.divider),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canUpdateAmount)
                _ActionChipButton(
                  icon: Icons.edit_outlined,
                  label: 'Update amount',
                  onPressed: onUpdateAmount,
                ),
              if (canRescheduleOrCancel)
                _ActionChipButton(
                  icon: Icons.event_repeat_rounded,
                  label: 'Reschedule',
                  onPressed: onReschedule,
                ),
              if (canRescheduleOrCancel)
                _ActionChipButton(
                  icon: Icons.cancel_outlined,
                  label: 'Cancel',
                  destructive: true,
                  onPressed: onCancel,
                ),
              _ActionChipButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: chatCount > 0 ? 'Pickup chats ($chatCount)' : 'Pickup chats',
                highlighted: true,
                onPressed: onOpenChats,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// High-contrast status badge for each DonationStatus.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DonationStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      DonationStatus.available => (ZhColors.primaryContainer, ZhColors.onPrimaryContainer),
      DonationStatus.claimed => (ZhColors.warningContainer, ZhColors.onWarning),
      DonationStatus.completed => (ZhColors.divider, ZhColors.text),
      DonationStatus.cancelled => (const Color(0xFFFCE8E6), ZhColors.error),
      DonationStatus.expired => (ZhColors.divider, ZhColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// Compact pill button used inside each donation card's action bar.
class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool destructive;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    if (highlighted) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: ZhColors.primaryContainer,
          foregroundColor: ZhColors.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    final color = destructive ? ZhColors.error : ZhColors.text;
    final borderColor = destructive ? ZhColors.error : ZhColors.outline;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet 1: Update amount left
// ---------------------------------------------------------------------------

class _UpdateAmountSheet extends StatefulWidget {
  const _UpdateAmountSheet({
    required this.donation,
    required this.onSave,
    required this.onAuthRequired,
  });

  final DonorDonation donation;
  final Future<Submitted> Function(int newQuantity) onSave;
  final VoidCallback onAuthRequired;

  @override
  State<_UpdateAmountSheet> createState() => _UpdateAmountSheetState();
}

class _UpdateAmountSheetState extends State<_UpdateAmountSheet> {
  late final TextEditingController _amount = TextEditingController(text: '${widget.donation.amountLeft}');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? get _parsedAmount => int.tryParse(_amount.text.trim());

  void _step(int delta) {
    final current = _parsedAmount ?? widget.donation.amountLeft;
    final next = (current + delta).clamp(0, 9999);
    setState(() {
      _amount.text = '$next';
      _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
      _error = null;
    });
  }

  Future<void> _submit() async {
    final value = _parsedAmount;
    if (value == null || value < 0) {
      setState(() => _error = 'Enter a whole number, 0 or more.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(value);
      if (!mounted) return;
      Navigator.pop(context, value);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        Navigator.pop(context);
        widget.onAuthRequired();
      } else {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _parsedAmount ?? 0;

    return _SheetShell(
      title: 'Update amount left',
      subtitle: widget.donation.title,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIconButton(
              icon: Icons.remove_rounded,
              tooltip: 'Decrease amount',
              onTap: _saving || current <= 0 ? null : () => _step(-1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _amount,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _error = null),
                decoration: zhField(
                  label: 'Amount left',
                  suffixText: widget.donation.unit,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _StepIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Increase amount',
              onTap: _saving ? null : () => _step(1),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontSize: 12, color: ZhColors.error)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          style: zhPrimaryButton(),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ZhColors.onPrimary),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _StepIconButton extends StatelessWidget {
  const _StepIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: ZhColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: onTap == null ? ZhColors.divider : ZhColors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 52,
            height: 56,
            child: Icon(icon, size: 22, color: onTap == null ? ZhColors.outline : ZhColors.text),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet 2: Reschedule pickup window
// ---------------------------------------------------------------------------

class _RescheduleResult {
  const _RescheduleResult(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({
    required this.donation,
    required this.onSave,
    required this.onAuthRequired,
  });

  final DonorDonation donation;
  final Future<Submitted> Function(DateTime start, DateTime end) onSave;
  final VoidCallback onAuthRequired;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime _date = DateTime(
    widget.donation.pickupStart.year,
    widget.donation.pickupStart.month,
    widget.donation.pickupStart.day,
  );
  late TimeOfDay _from = TimeOfDay.fromDateTime(widget.donation.pickupStart);
  late TimeOfDay _to = TimeOfDay.fromDateTime(widget.donation.pickupEnd);

  bool _windowWrong = false;
  bool _saving = false;
  String? _error;

  DateTime get _start => DateTime(_date.year, _date.month, _date.day, _from.hour, _from.minute);
  DateTime get _end => DateTime(_date.year, _date.month, _date.day, _to.hour, _to.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _windowWrong = false;
        _error = null;
      });
    }
  }

  Future<void> _pickTime({required bool from}) async {
    final picked = await showTimePicker(context: context, initialTime: from ? _from : _to);
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
      _windowWrong = false;
      _error = null;
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

  Future<void> _submit() async {
    if (!_end.isAfter(_start)) {
      setState(() {
        _windowWrong = true;
        _error = 'Pickup must end after it starts.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _windowWrong = false;
      _error = null;
    });

    try {
      await widget.onSave(_start, _end);
      if (!mounted) return;
      Navigator.pop(context, _RescheduleResult(_start, _end));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        Navigator.pop(context);
        widget.onAuthRequired();
      } else {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Reschedule pickup',
      subtitle: widget.donation.title,
      children: [
        PickerField(
          label: 'New date',
          value: _dateText(_date),
          icon: Icons.calendar_today_rounded,
          onTap: _saving ? () {} : _pickDate,
          hasError: _windowWrong,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PickerField(
                label: 'From',
                value: _timeText(_from),
                icon: Icons.schedule_rounded,
                onTap: _saving ? () {} : () => _pickTime(from: true),
                hasError: _windowWrong,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PickerField(
                label: 'To',
                value: _timeText(_to),
                icon: Icons.schedule_rounded,
                onTap: _saving ? () {} : () => _pickTime(from: false),
                hasError: _windowWrong,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            _error ?? 'Pickup must end after it starts.',
            style: TextStyle(fontSize: 12, color: (_windowWrong || _error != null) ? ZhColors.error : ZhColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: zhPrimaryButton(),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ZhColors.onPrimary),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet 3: Cancel donation
// ---------------------------------------------------------------------------

class _CancelResult {
  const _CancelResult(this.reason);
  final String? reason;
}

class _CancelDonationSheet extends StatefulWidget {
  const _CancelDonationSheet({
    required this.donation,
    required this.onConfirm,
    required this.onAuthRequired,
  });

  final DonorDonation donation;
  final Future<Submitted> Function(String? reason) onConfirm;
  final VoidCallback onAuthRequired;

  @override
  State<_CancelDonationSheet> createState() => _CancelDonationSheetState();
}

class _CancelDonationSheetState extends State<_CancelDonationSheet> {
  final _reason = TextEditingController();
  bool _cancelling = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final trimmed = _reason.text.trim();
    final reason = trimmed.isEmpty ? null : trimmed;

    setState(() {
      _cancelling = true;
      _error = null;
    });

    try {
      await widget.onConfirm(reason);
      if (!mounted) return;
      Navigator.pop(context, _CancelResult(reason));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        Navigator.pop(context);
        widget.onAuthRequired();
      } else {
        setState(() {
          _cancelling = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Cancel donation',
      subtitle: '${widget.donation.title} — Anyone who claimed this food will be notified.',
      children: [
        TextField(
          controller: _reason,
          enabled: !_cancelling,
          minLines: 2,
          maxLines: 4,
          maxLength: 200,
          decoration: zhField(
            label: 'Reason (optional)',
            hint: 'e.g. Food is no longer available',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontSize: 12, color: ZhColors.error)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ZhColors.error,
            foregroundColor: ZhColors.onPrimary,
            disabledBackgroundColor: const Color(0x99B3261E),
            disabledForegroundColor: ZhColors.onPrimary,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: _cancelling ? null : _submit,
          child: _cancelling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ZhColors.onPrimary),
                )
              : const Text('Cancel donation'),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _cancelling ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: ZhColors.textSecondary,
              minimumSize: const Size(0, 48),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            child: const Text('Keep donation'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet 4: Pickup chats for a donation
// ---------------------------------------------------------------------------

class _PickupChatsSheet extends StatelessWidget {
  const _PickupChatsSheet({required this.donation});

  final DonorDonation donation;

  String _timeAgo(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final chats = donation.pickupChats;

    return _SheetShell(
      title: 'Pickup chats',
      subtitle: donation.title,
      children: [
        if (chats.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No pickup chats yet. A chat opens automatically when someone claims this donation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ZhColors.textSecondary),
            ),
          )
        else
          for (final chat in chats) ...[
            Material(
              color: ZhColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: ZhColors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Push PickupChatScreen(chatId: chat.chatId, donationTitle: donation.title) once built.
                  showZhMessage(context, 'Opening chat with ${chat.recipientLabel} — Pickup chat screen coming next.');
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: ZhColors.primaryContainer,
                        child: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: ZhColors.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.recipientLabel,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ZhColors.text),
                                  ),
                                ),
                                Text(
                                  _timeAgo(chat.updatedAt),
                                  style: const TextStyle(fontSize: 12, color: ZhColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chat.lastMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: ZhColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 20, color: ZhColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

// Shared layout for modal bottom sheets on this screen (matches SignInSheet).
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(color: ZhColors.outline, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// Shown to guests instead of the donor list.
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
              'Sign in to manage your donations',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to see the food you have posted, update quantities, reschedule, or cancel.',
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

// Empty / error placeholder message.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              style: zhPrimaryButton(),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
