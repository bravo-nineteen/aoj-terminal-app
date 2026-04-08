import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/persistent_edit_field.dart';
import '../widgets/summary_line.dart';
import '../widgets/ui_components.dart';

class BookingsPanel extends StatefulWidget {
  final Color accent;
  final AppStateData appState;
  final EventRecord? event;
  final List<BookingGroup> groups;
  final int? selectedBookingIndex;
  final List<String> paymentMethods;
  final List<String> paymentStatuses;
  final List<String> checkInStatuses;
  final Future<void> Function(String?) onSetActiveEvent;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onSelectBooking;
  final Future<void> Function(BookingGroup) onToggleCheckIn;
  final Future<void> Function(BookingGroup) onEditContact;
  final Future<void> Function(BookingGroup) onDeleteGroup;
  final Future<void> Function(BookingGroup) onAddTicket;
  final Future<void> Function(BookingGroup) onAddPayment;
  final Future<void> Function(BookingGroup, String) onDeletePayment;
  final Future<void> Function(BookingGroup) onAddSale;
  final Future<void> Function(BookingGroup, String) onDeleteSale;
  final Future<void> Function(BookingGroup) onSaveGroup;
  final Future<void> Function() onSave;
  final VoidCallback onRefresh;

  const BookingsPanel({
    super.key,
    required this.accent,
    required this.appState,
    required this.event,
    required this.groups,
    required this.selectedBookingIndex,
    required this.paymentMethods,
    required this.paymentStatuses,
    required this.checkInStatuses,
    required this.onSetActiveEvent,
    required this.onSearchChanged,
    required this.onSelectBooking,
    required this.onToggleCheckIn,
    required this.onEditContact,
    required this.onDeleteGroup,
    required this.onAddTicket,
    required this.onAddPayment,
    required this.onDeletePayment,
    required this.onAddSale,
    required this.onDeleteSale,
    required this.onSaveGroup,
    required this.onSave,
    required this.onRefresh,
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
    BookingGroup? selectedGroup;
    if (widget.selectedBookingIndex != null &&
        widget.selectedBookingIndex! >= 0 &&
        widget.selectedBookingIndex! < widget.groups.length) {
      selectedGroup = widget.groups[widget.selectedBookingIndex!];
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'LOGISTICS / BOOKING DETAILS',
            subtitle: 'One person per booking with logistics, tickets, payments and sales',
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
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(color: widget.accent.withOpacity(0.35)),
                      ),
                      child: widget.groups.isEmpty
                          ? const Center(child: Text('NO BOOKINGS FOR THIS EVENT'))
                          : ListView.separated(
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

                                return ListTile(
                                  selected: active,
                                  selectedTileColor: widget.accent.withOpacity(0.16),
                                  title: Text(
                                    group.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    membershipLevel.isNotEmpty
                                        ? membershipLevel
                                        : 'No membership level',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '¥ ${MoneyUtils.formatMoney(BookingUtils.grandTotal(group))}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Balance ¥ ${MoneyUtils.formatMoney(BookingUtils.balance(group))}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  onTap: () => widget.onSelectBooking(index),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(color: widget.accent.withOpacity(0.35)),
                      ),
                      child: selectedGroup == null
                          ? const Center(child: Text('SELECT A PERSON'))
                          : _BookingDetails(
                              accent: widget.accent,
                              event: widget.event!,
                              group: selectedGroup,
                              membershipLevel:
                                  _membershipLevelForGroup(widget.event, selectedGroup),
                              paymentStatuses: widget.paymentStatuses,
                              checkInStatuses: widget.checkInStatuses,
                              onToggleCheckIn: widget.onToggleCheckIn,
                              onEditContact: widget.onEditContact,
                              onDeleteGroup: widget.onDeleteGroup,
                              onAddTicket: widget.onAddTicket,
                              onAddPayment: widget.onAddPayment,
                              onDeletePayment: widget.onDeletePayment,
                              onAddSale: widget.onAddSale,
                              onDeleteSale: widget.onDeleteSale,
                              onSaveGroup: widget.onSaveGroup,
                              onSave: widget.onSave,
                              onRefresh: widget.onRefresh,
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BookingDetails extends StatefulWidget {
  final Color accent;
  final EventRecord event;
  final BookingGroup group;
  final String membershipLevel;
  final List<String> paymentStatuses;
  final List<String> checkInStatuses;
  final Future<void> Function(BookingGroup) onToggleCheckIn;
  final Future<void> Function(BookingGroup) onEditContact;
  final Future<void> Function(BookingGroup) onDeleteGroup;
  final Future<void> Function(BookingGroup) onAddTicket;
  final Future<void> Function(BookingGroup) onAddPayment;
  final Future<void> Function(BookingGroup, String) onDeletePayment;
  final Future<void> Function(BookingGroup) onAddSale;
  final Future<void> Function(BookingGroup, String) onDeleteSale;
  final Future<void> Function(BookingGroup) onSaveGroup;
  final Future<void> Function() onSave;
  final VoidCallback onRefresh;

  const _BookingDetails({
    required this.accent,
    required this.event,
    required this.group,
    required this.membershipLevel,
    required this.paymentStatuses,
    required this.checkInStatuses,
    required this.onToggleCheckIn,
    required this.onEditContact,
    required this.onDeleteGroup,
    required this.onAddTicket,
    required this.onAddPayment,
    required this.onDeletePayment,
    required this.onAddSale,
    required this.onDeleteSale,
    required this.onSaveGroup,
    required this.onSave,
    required this.onRefresh,
  });

  @override
  State<_BookingDetails> createState() => _BookingDetailsState();
}

class _BookingDetailsState extends State<_BookingDetails> {
  Future<void> _saveGroupAndRefresh() async {
    await widget.onSaveGroup(widget.group);
    widget.onRefresh();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveEventAndRefresh() async {
    await widget.onSave();
    widget.onRefresh();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editTicketPrice(TicketRecord ticket) async {
    final controller = TextEditingController(text: ticket.price);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Ticket Price'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Price',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    ticket.price = controller.text.trim();
    BookingUtils.recalculateAllTotals(widget.event);
    await _saveEventAndRefresh();
  }

  Widget _buildSectionCard({
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.membershipLevel.isNotEmpty
                        ? widget.membershipLevel
                        : 'No membership level',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.accent,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => widget.onToggleCheckIn(group),
              icon: Icon(
                group.primary.checkInStatus == 'Checked In'
                    ? Icons.how_to_reg
                    : Icons.login,
              ),
              label: Text(
                group.primary.checkInStatus == 'Checked In'
                    ? 'UNDO CHECK-IN'
                    : 'CHECK IN',
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => widget.onEditContact(group),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit contact',
            ),
            const SizedBox(width: 4),
            OutlinedButton.icon(
              onPressed: () => widget.onDeleteGroup(group),
              icon: const Icon(Icons.delete_outline),
              label: const Text('DELETE'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          group.primary.email,
          style: const TextStyle(fontSize: 12, color: Color(0xFFAFB7AD)),
        ),
        const SizedBox(height: 2),
        Text(
          group.primary.phone,
          style: const TextStyle(fontSize: 12, color: Color(0xFFAFB7AD)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.accent.withOpacity(0.10),
            border: Border.all(color: widget.accent.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOGISTICS / BOOKING DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: widget.accent,
                ),
              ),
              const SizedBox(height: 8),
              SummaryLine(label: 'Pickup', value: group.needsPickup ? 'YES' : 'NO'),
              SummaryLine(
                label: 'Beginners Training',
                value: group.needsTraining ? 'YES' : 'NO',
              ),
              SummaryLine(
                label: 'Guest Names',
                value: group.guestNames.isEmpty ? 'None' : group.guestNames,
              ),
              SummaryLine(
                label: 'Language',
                value: group.languagePreference.isEmpty ? '-' : group.languagePreference,
              ),
              SummaryLine(
                label: 'Rental Gun Sets',
                value: BookingUtils.groupRentalCount(group).toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SummaryLine(label: 'Booking ID', value: group.bookingId),
        SummaryLine(label: 'Transaction ID', value: group.primary.transactionId),
        SummaryLine(
          label: 'Tickets Total',
          value: '¥ ${MoneyUtils.formatMoney(BookingUtils.ticketsTotal(group))}',
        ),
        SummaryLine(
          label: 'Sales Total',
          value: '¥ ${MoneyUtils.formatMoney(BookingUtils.salesTotal(group))}',
        ),
        SummaryLine(
          label: 'Grand Total',
          value: '¥ ${MoneyUtils.formatMoney(BookingUtils.grandTotal(group))}',
        ),
        SummaryLine(
          label: 'Paid',
          value: '¥ ${MoneyUtils.formatMoney(BookingUtils.paymentsTotal(group))}',
        ),
        SummaryLine(
          label: 'Balance',
          value: '¥ ${MoneyUtils.formatMoney(BookingUtils.balance(group))}',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  value: widget.paymentStatuses.contains(group.primary.paymentStatus)
                      ? group.primary.paymentStatus
                      : 'Unpaid',
                  decoration: const InputDecoration(
                    labelText: 'Payment Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: widget.paymentStatuses
                      .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    group.primary.paymentStatus = v;
                    await _saveGroupAndRefresh();
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  value: widget.checkInStatuses.contains(group.primary.checkInStatus)
                      ? group.primary.checkInStatus
                      : 'Not Checked In',
                  decoration: const InputDecoration(
                    labelText: 'Check In',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: widget.checkInStatuses
                      .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    group.primary.checkInStatus = v;
                    await _saveGroupAndRefresh();
                  },
                ),
              ),
            ),
          ],
        ),
        PersistentEditField(
          label: 'Notes',
          value: group.primary.notes,
          maxLines: 3,
          onChanged: (v) async {
            group.primary.notes = v;
            await _saveGroupAndRefresh();
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tickets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              onPressed: () => widget.onAddTicket(group),
              child: const Text('ADD TICKET'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...group.tickets.map((ticket) {
          return _buildSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.ticketName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quantity: ${ticket.quantity}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: ¥ ${ticket.price}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editTicketPrice(ticket),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit ticket price',
                ),
                DropdownButton<String>(
                  value: ticket.status == 'Cancelled' ? 'Cancelled' : 'Active',
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Keep')),
                    DropdownMenuItem(value: 'Cancelled', child: Text('Cancel')),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    ticket.status = value;
                    BookingUtils.recalculateAllTotals(widget.event);
                    await _saveEventAndRefresh();
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Payments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              onPressed: () => widget.onAddPayment(group),
              child: const Text('ADD PAYMENT'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...group.primary.payments.map((payment) {
          return _buildSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¥ ${payment.amount}  -  ${payment.method}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (payment.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            payment.note,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFAFB7AD),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onDeletePayment(group, payment.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Sales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              onPressed: () => widget.onAddSale(group),
              child: const Text('ADD SALE'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...group.primary.sales.map((sale) {
          return _buildSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: PersistentEditField(
                    label: 'Product',
                    value: sale.product,
                    onChanged: (v) async {
                      sale.product = v;
                      await _saveGroupAndRefresh();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: PersistentEditField(
                    label: 'Price',
                    value: sale.price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) async {
                      sale.price = v;
                      BookingUtils.recalculateAllTotals(widget.event);
                      await widget.onSaveGroup(group);
                      await _saveEventAndRefresh();
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onDeleteSale(group, sale.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
