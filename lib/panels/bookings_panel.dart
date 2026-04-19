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
  final Future<void> Function(String?) onSetActiveEvent;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onSelectBooking;
  final Future<void> Function(BookingGroup, String) onQuickSetCheckInStatus;
  final Future<void> Function(BookingGroup) onOpenBookingEditor;

  const BookingsPanel({
    super.key,
    required this.accent,
    required this.appState,
    required this.event,
    required this.groups,
    required this.selectedBookingIndex,
    required this.checkInStatuses,
    required this.onSetActiveEvent,
    required this.onSearchChanged,
    required this.onSelectBooking,
    required this.onQuickSetCheckInStatus,
    required this.onOpenBookingEditor,
  });

  @override
  State<BookingsPanel> createState() => _BookingsPanelState();
}

class _BookingsPanelState extends State<BookingsPanel> {
  final TextEditingController _searchController = TextEditingController();

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
                  decoration: const InputDecoration(
                    labelText: 'Search booking',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 18),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                          final total = BookingUtils.grandTotal(group);
                          final balance = BookingUtils.balance(group);
                          final hasOutstanding = balance > 0;

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
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text(
                                                'Check-in:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFAFB7AD),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
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
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                paymentStatus,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: _paymentColor(
                                                      paymentStatus),
                                                ),
                                              ),
                                              if (hasOutstanding) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withValues(
                                                            alpha: 0.18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                    border: Border.all(
                                                      color: Colors.redAccent
                                                          .withValues(
                                                              alpha: 0.35),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'BAL ¥ ${MoneyUtils.formatMoney(balance)}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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
