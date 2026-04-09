import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/ui_components.dart';

class BookingsPanel extends StatefulWidget {
  final Color accent;
  final AppStateData appState;
  final EventRecord? event;
  final List<BookingGroup> groups;
  final int? selectedBookingIndex;
  final Future<void> Function(String?) onSetActiveEvent;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onSelectBooking;
  final Future<void> Function(BookingGroup) onOpenBookingEditor;

  const BookingsPanel({
    super.key,
    required this.accent,
    required this.appState,
    required this.event,
    required this.groups,
    required this.selectedBookingIndex,
    required this.onSetActiveEvent,
    required this.onSearchChanged,
    required this.onSelectBooking,
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

    MemberRecord? matched;

    for (final member in event.members) {
      final memberEmail = member.email.trim().toLowerCase();
      final memberPhone = member.telephone.trim().toLowerCase();
      final memberName = member.fullName.trim().toLowerCase();

      final groupEmail = group.email.trim().toLowerCase();
      final groupPhone = group.phone.trim().toLowerCase();
      final groupName = group.displayName.trim().toLowerCase();

      final emailMatch =
          memberEmail.isNotEmpty && groupEmail.isNotEmpty && memberEmail == groupEmail;
      final phoneMatch =
          memberPhone.isNotEmpty && groupPhone.isNotEmpty && memberPhone == groupPhone;
      final nameMatch =
          memberName.isNotEmpty && groupName.isNotEmpty && memberName == groupName;

      if (emailMatch || phoneMatch || nameMatch) {
        matched = member;
        break;
      }
    }

    return matched?.membershipLevel ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'BOOKING ROSTER',
            subtitle: 'Select and open a booking in a dedicated editor window',
            accent: widget.accent,
            icon: Icons.assignment_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.appState.activeEventId,
                  decoration: const InputDecoration(
                    labelText: 'Event',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: widget.appState.events
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  onChanged: widget.onSetActiveEvent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: const InputDecoration(
                    labelText: 'Search name / email / phone / booking ID / guest',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xCC101511),
                  border: Border.all(color: widget.accent.withOpacity(0.35)),
                ),
                child: widget.groups.isEmpty
                    ? const Center(child: Text('NO BOOKINGS FOR THIS EVENT'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: widget.groups.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.06),
                        ),
                        itemBuilder: (context, index) {
                          final group = widget.groups[index];
                          final active = index == widget.selectedBookingIndex;
                          final membershipLevel =
                              _membershipLevelForGroup(widget.event, group);

                          final paymentStatus = group.primary.paymentStatus.trim();
                          final checkInStatus = group.primary.checkInStatus.trim();
                          final balance = BookingUtils.balance(group);
                          final grandTotal = BookingUtils.grandTotal(group);
                          final hasOutstanding = balance > 0;

                          return InkWell(
                            onTap: () => widget.onSelectBooking(index),
                            onDoubleTap: () => widget.onOpenBookingEditor(group),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: active
                                    ? widget.accent.withOpacity(0.14)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: active
                                      ? widget.accent.withOpacity(0.45)
                                      : Colors.white.withOpacity(0.04),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _RosterBadge(
                                              text: membershipLevel.isEmpty
                                                  ? 'NO MEMBERSHIP'
                                                  : membershipLevel.toUpperCase(),
                                              background: widget.accent
                                                  .withOpacity(0.14),
                                              foreground: widget.accent,
                                            ),
                                            _RosterBadge(
                                              text: checkInStatus.isEmpty
                                                  ? 'NO STATUS'
                                                  : checkInStatus.toUpperCase(),
                                              background: checkInStatus ==
                                                      'Checked In'
                                                  ? Colors.green
                                                      .withOpacity(0.16)
                                                  : Colors.white
                                                      .withOpacity(0.08),
                                              foreground: checkInStatus ==
                                                      'Checked In'
                                                  ? Colors.greenAccent
                                                  : Colors.white70,
                                            ),
                                            _RosterBadge(
                                              text: paymentStatus.isEmpty
                                                  ? 'NO PAYMENT'
                                                  : paymentStatus.toUpperCase(),
                                              background: paymentStatus == 'Paid'
                                                  ? Colors.green
                                                      .withOpacity(0.16)
                                                  : paymentStatus == 'Part Paid'
                                                      ? Colors.orange
                                                          .withOpacity(0.16)
                                                      : Colors.red
                                                          .withOpacity(0.16),
                                              foreground: paymentStatus == 'Paid'
                                                  ? Colors.greenAccent
                                                  : paymentStatus == 'Part Paid'
                                                      ? Colors.orangeAccent
                                                      : Colors.redAccent,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          [
                                            if (group.primary.email.isNotEmpty)
                                              group.primary.email,
                                            if (group.primary.phone.isNotEmpty)
                                              group.primary.phone,
                                          ].join('  •  '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFAFB7AD),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '¥ ${MoneyUtils.formatMoney(grandTotal)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            color: hasOutstanding
                                                ? Colors.red.withOpacity(0.18)
                                                : Colors.green
                                                    .withOpacity(0.16),
                                            border: Border.all(
                                              color: hasOutstanding
                                                  ? Colors.redAccent
                                                      .withOpacity(0.45)
                                                  : Colors.greenAccent
                                                      .withOpacity(0.35),
                                            ),
                                          ),
                                          child: Text(
                                            hasOutstanding
                                                ? 'BAL ¥ ${MoneyUtils.formatMoney(balance)}'
                                                : 'CLEAR',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: hasOutstanding
                                                  ? Colors.redAccent
                                                  : Colors.greenAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              widget.onOpenBookingEditor(group),
                                          icon: const Icon(
                                            Icons.open_in_new,
                                            size: 16,
                                          ),
                                          label: const Text('OPEN'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

class _RosterBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _RosterBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
