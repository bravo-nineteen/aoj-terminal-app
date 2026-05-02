import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';

class BookingsPanel extends StatefulWidget {
  final Color accent;
  final AppStateData appState;
  final EventRecord? event;
  final List<BookingGroup> groups;
  final int? selectedBookingIndex;
  final List<String> checkInStatuses;
  final List<String> paymentStatuses;
  final String selectedPaymentFilter;
  final String selectedTicketTypeFilter;
  final Future<void> Function(String?) onSetActiveEvent;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPaymentFilterChanged;
  final ValueChanged<String> onTicketTypeFilterChanged;
  final ValueChanged<int> onSelectBooking;
  final Future<void> Function(BookingGroup, String) onQuickSetCheckInStatus;
  final Future<void> Function() onCheckInAll;
  final Future<void> Function(BookingGroup) onOpenBookingEditor;
  final Future<void> Function() onAddManualBooking;
  final Future<void> Function(BookingGroup)? onAddPayment;

  const BookingsPanel({
    super.key,
    required this.accent,
    required this.appState,
    required this.event,
    required this.groups,
    required this.selectedBookingIndex,
    required this.checkInStatuses,
    required this.paymentStatuses,
    required this.selectedPaymentFilter,
    required this.selectedTicketTypeFilter,
    required this.onSetActiveEvent,
    required this.onSearchChanged,
    required this.onPaymentFilterChanged,
    required this.onTicketTypeFilterChanged,
    required this.onSelectBooking,
    required this.onQuickSetCheckInStatus,
    required this.onCheckInAll,
    required this.onOpenBookingEditor,
    required this.onAddManualBooking,
    this.onAddPayment,
  });

  @override
  State<BookingsPanel> createState() => _BookingsPanelState();
}

class _BookingsPanelState extends State<BookingsPanel> {
  final TextEditingController _searchController = TextEditingController();
  bool _checkInMode = false;

  @override
  void didUpdateWidget(covariant BookingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event?.id != widget.event?.id) {
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _membershipLevelForGroup(EventRecord? event, BookingGroup group) {
    if (event == null) return '';

    for (final member in event.members) {
      final memberEmail = member.email.trim().toLowerCase();
      final memberPhone = member.telephone.trim().toLowerCase();
      final memberName = member.fullName.trim().toLowerCase();

      final groupEmail = group.email.trim().toLowerCase();
      final groupPhone = group.phone.trim().toLowerCase();
      final groupName = group.displayName.trim().toLowerCase();

      final emailMatch = memberEmail.isNotEmpty &&
          groupEmail.isNotEmpty &&
          memberEmail == groupEmail;

      final phoneMatch = memberPhone.isNotEmpty &&
          groupPhone.isNotEmpty &&
          memberPhone == groupPhone;

      final nameMatch = memberName.isNotEmpty &&
          groupName.isNotEmpty &&
          memberName == groupName;

      if (emailMatch || phoneMatch || nameMatch) {
        return member.membershipLevel;
      }
    }

    return '';
  }

  Color _paymentColor(String status) {
    switch (status.trim()) {
      case 'Paid':
        return Colors.greenAccent;
      case 'Overpaid':
        return Colors.lightBlueAccent;
      case 'Part Paid':
        return Colors.orangeAccent;
      case 'Refunded':
        return Colors.blueAccent;
      default:
        return Colors.redAccent;
    }
  }

  Color _checkInColor(String status) {
    switch (status.trim()) {
      case 'Checked In':
        return Colors.greenAccent;
      case 'Cancelled':
        return Colors.redAccent;
      case 'No Show':
        return Colors.orangeAccent;
      default:
        return Colors.white70;
    }
  }

  List<String> _lunchNamesForGroup(BookingGroup group) {
    final event = widget.event;
    if (event == null || group.primary.lunchOrderIds.isEmpty) return [];
    final optionsById = {for (final o in event.lunchOptions) o.id: o};
    return group.primary.lunchOrderIds
        .map((id) => optionsById[id])
        .whereType<LunchOptionRecord>()
        .map((o) => o.name.trim().isEmpty ? 'Lunch' : o.name.trim())
        .toList();
  }

  List<String> _ticketTypeFilterOptions() {
    final event = widget.event;
    if (event == null) {
      return const ['All Ticket Types'];
    }

    final seen = <String>{};
    final options = <String>['All Ticket Types'];
    for (final ticket in event.tickets) {
      final name = ticket.ticketName.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) {
        options.add(name);
      }
    }
    return options;
  }

  Widget _buildStatsBar() {
    final groups = widget.groups;
    final total = groups.length;
    final checkedIn = groups
        .where((g) => g.primary.checkInStatus.trim() == 'Checked In')
        .length;
    final unpaid = groups
        .where((g) {
          final s = g.primary.paymentStatus.trim();
          return s == 'Unpaid' || s.isEmpty;
        })
        .length;
    final partPaid = groups
        .where((g) => g.primary.paymentStatus.trim() == 'Part Paid')
        .length;
    double outstanding = 0;
    for (final g in groups) {
      final bal = BookingUtils.balance(g, widget.event);
      if (bal > 0) outstanding += bal;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _statChip('$total', 'BOOKINGS', Colors.white70),
          const SizedBox(width: 10),
          _statChip('$checkedIn', 'CHECKED IN', Colors.greenAccent),
          const SizedBox(width: 10),
          if (unpaid > 0) ...[
            _statChip('$unpaid', 'UNPAID', Colors.redAccent),
            const SizedBox(width: 10),
          ],
          if (partPaid > 0) ...[
            _statChip('$partPaid', 'PART PAID', Colors.orangeAccent),
            const SizedBox(width: 10),
          ],
          if (outstanding > 0)
            _statChip(
              '¥ ${MoneyUtils.formatMoney(outstanding)}',
              'OUTSTANDING',
              Colors.redAccent,
            ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color colour) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colour,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF98A197),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _flagBadge(String label, IconData icon, Color colour) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: colour),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: colour,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.appState.activeEventId,
                  decoration: const InputDecoration(
                    labelText: 'Event',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: widget.appState.events
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(e.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: widget.onSetActiveEvent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'Search booking',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged('');
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _checkInMode
                    ? 'Standard view'
                    : 'Check-in mode',
                onPressed: () => setState(() {
                  _checkInMode = !_checkInMode;
                }),
                icon: Icon(
                  _checkInMode
                      ? Icons.list_alt_outlined
                      : Icons.door_front_door_outlined,
                  size: 20,
                  color: _checkInMode
                      ? widget.accent
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.selectedPaymentFilter,
                  decoration: const InputDecoration(
                    labelText: 'Payment',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: <String>[
                    'All Payments',
                    ...widget.paymentStatuses,
                  ]
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: widget.event == null
                      ? null
                      : (value) {
                          if (value == null) return;
                          widget.onPaymentFilterChanged(value);
                        },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _ticketTypeFilterOptions().contains(
                    widget.selectedTicketTypeFilter,
                  )
                      ? widget.selectedTicketTypeFilter
                      : 'All Ticket Types',
                  decoration: const InputDecoration(
                    labelText: 'Ticket Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: _ticketTypeFilterOptions()
                      .map(
                        (ticketType) => DropdownMenuItem<String>(
                          value: ticketType,
                          child: Text(
                            ticketType,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: widget.event == null
                      ? null
                      : (value) {
                          if (value == null) return;
                          widget.onTicketTypeFilterChanged(value);
                        },
                ),
              ),
              OutlinedButton.icon(
                onPressed: widget.event == null
                    ? null
                    : () async {
                        await widget.onAddManualBooking();
                      },
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('ADD BOOKING'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
              OutlinedButton.icon(
                onPressed: widget.event == null
                    ? null
                    : () async {
                        await widget.onCheckInAll();
                        if (mounted) setState(() {});
                      },
                icon: const Icon(Icons.how_to_reg_outlined, size: 16),
                label: const Text('ALL IN'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (widget.event != null) _buildStatsBar(),
          const SizedBox(height: 6),
          if (widget.event == null)
            const Expanded(
              child: Center(
                child: Text('NO ACTIVE EVENT'),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xCC101511),
                  border:
                      Border.all(color: widget.accent.withValues(alpha: 0.30)),
                ),
                child: widget.groups.isEmpty
                    ? const Center(child: Text('NO BOOKINGS FOR THIS EVENT'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: widget.groups.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        itemBuilder: (context, index) {
                          final group = widget.groups[index];
                          final active = index == widget.selectedBookingIndex;
                          final membershipLevel =
                              _membershipLevelForGroup(widget.event, group);
                          final paymentStatus =
                              group.primary.paymentStatus.trim().isEmpty
                                  ? 'Unpaid'
                                  : group.primary.paymentStatus.trim();
                          final checkInStatus =
                              group.primary.checkInStatus.trim().isEmpty
                                  ? 'Not Checked In'
                                  : group.primary.checkInStatus.trim();
                          final total = BookingUtils.grandTotal(group, widget.event);
                          final balance = BookingUtils.balance(group, widget.event);
                          final hasOutstanding = balance > 0;
                          final lunchNames = _lunchNamesForGroup(group);

                          if (_checkInMode) {
                            // ── Check-in mode: large card ──
                            final isCheckedIn =
                                checkInStatus == 'Checked In';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: isCheckedIn
                                    ? Colors.green.withValues(alpha: 0.10)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isCheckedIn
                                      ? Colors.greenAccent
                                          .withValues(alpha: 0.40)
                                      : Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            membershipLevel.isNotEmpty
                                                ? '${group.displayName} ($membershipLevel)'
                                                : group.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (hasOutstanding)
                                                Text(
                                                  'BAL ¥ ${MoneyUtils.formatMoney(balance)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.redAccent,
                                                  ),
                                                )
                                              else
                                                Text(
                                                  paymentStatus,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: _paymentColor(
                                                        paymentStatus),
                                                  ),
                                                ),
                                              if (lunchNames.isNotEmpty) ...
                                                lunchNames.map(
                                                  (n) => Container(
                                                    margin: const EdgeInsets
                                                        .only(left: 6),
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber
                                                          .withValues(
                                                              alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                      border: Border.all(
                                                        color: Colors.amber
                                                            .withValues(
                                                                alpha: 0.4),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      n,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.amber,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isCheckedIn
                                            ? Colors.green.withValues(
                                                alpha: 0.30)
                                            : widget.accent
                                                .withValues(alpha: 0.85),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                      ),
                                      onPressed: () async {
                                        final next = isCheckedIn
                                            ? 'Not Checked In'
                                            : 'Checked In';
                                        await widget
                                            .onQuickSetCheckInStatus(
                                                group, next);
                                        if (mounted) setState(() {});
                                      },
                                      child: Text(
                                        isCheckedIn
                                            ? 'UNDO CHECK-IN'
                                            : 'CHECK IN',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // ── Standard mode ──
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: active
                                  ? widget.accent.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              border: Border.all(
                                color: active
                                    ? widget.accent.withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.03),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onSelectBooking(index),
                              onDoubleTap: () =>
                                  widget.onOpenBookingEditor(group),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            membershipLevel.isNotEmpty
                                                ? '${group.displayName} ($membershipLevel)'
                                                : group.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Text(
                                                'Check-in:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFAFB7AD),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: widget.checkInStatuses
                                                          .contains(
                                                              checkInStatus)
                                                      ? checkInStatus
                                                      : widget.checkInStatuses
                                                          .first,
                                                  isDense: true,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: _checkInColor(
                                                        checkInStatus),
                                                  ),
                                                  dropdownColor:
                                                      const Color(0xFF1A211C),
                                                  items: widget.checkInStatuses
                                                      .map(
                                                        (e) => DropdownMenuItem<
                                                            String>(
                                                          value: e,
                                                          child: Text(
                                                            e,
                                                            style: TextStyle(
                                                              color:
                                                                  _checkInColor(
                                                                      e),
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (value) async {
                                                    if (value == null) return;
                                                    await widget
                                                        .onQuickSetCheckInStatus(
                                                      group,
                                                      value,
                                                    );
                                                    if (mounted) {
                                                      setState(() {});
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                'Payment:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFAFB7AD),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                paymentStatus,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: _paymentColor(
                                                    paymentStatus,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (lunchNames.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 3),
                                              child: Wrap(
                                                spacing: 4,
                                                children: lunchNames
                                                    .map(
                                                      (n) => Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.amber
                                                              .withValues(
                                                                  alpha: 0.12),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      999),
                                                          border: Border.all(
                                                            color: Colors.amber
                                                                .withValues(
                                                                    alpha: 0.35),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          n,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.amber,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                          if (group.primary.needsPickup ||
                                              group.primary.needsTraining)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 3),
                                              child: Wrap(
                                                spacing: 4,
                                                children: [
                                                  if (group.primary.needsPickup)
                                                    _flagBadge(
                                                      'PICKUP',
                                                      Icons
                                                          .directions_car_outlined,
                                                      Colors.cyanAccent,
                                                    ),
                                                  if (group
                                                      .primary.needsTraining)
                                                    _flagBadge(
                                                      'TRAINING',
                                                      Icons.school_outlined,
                                                      Colors.purpleAccent,
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '¥ ${MoneyUtils.formatMoney(total)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (hasOutstanding)
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                horizontal: 6,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red
                                                    .withValues(alpha: 0.18),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: Colors.redAccent
                                                      .withValues(alpha: 0.35),
                                                ),
                                              ),
                                              child: Text(
                                                'BAL ¥ ${MoneyUtils.formatMoney(balance)}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (widget.onAddPayment != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        child: Tooltip(
                                          message: 'Add payment',
                                          child: Material(
                                            color: Colors.green
                                                .withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              onTap: () => widget
                                                  .onAddPayment!(group),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: Colors.greenAccent
                                                          .withValues(
                                                              alpha: 0.35)),
                                                ),
                                                child: const Icon(
                                                  Icons.payments_outlined,
                                                  size: 16,
                                                  color: Colors.greenAccent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    _IntegratedOpenButton(
                                      accent: widget.accent,
                                      onTap: () =>
                                          widget.onOpenBookingEditor(group),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IntegratedOpenButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _IntegratedOpenButton({
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Icon(
            Icons.open_in_new_rounded,
            size: 16,
            color: accent,
          ),
        ),
      ),
    );
  }
}
