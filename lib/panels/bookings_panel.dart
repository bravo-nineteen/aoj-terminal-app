
import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/persistent_edit_field.dart';
import '../widgets/summary_line.dart';

class BookingsPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    BookingGroup? selectedGroup;
    if (selectedBookingIndex != null &&
        selectedBookingIndex! >= 0 &&
        selectedBookingIndex! < groups.length) {
      selectedGroup = groups[selectedBookingIndex!];
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'LOGISTICS / BOOKING DETAILS',
            subtitle: 'One person per booking with logistics, tickets, payments and sales',
            accent: accent,
            icon: Icons.assignment_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: appState.activeEventId,
                  decoration: const InputDecoration(
                    labelText: 'Event',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: appState.events
                      .map((e) => DropdownMenuItem<String>(value: e.id, child: Text(e.name)))
                      .toList(),
                  onChanged: onSetActiveEvent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    labelText: 'Search name / email / phone / booking ID / guest',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (event == null)
            const Expanded(child: Center(child: Text('NO ACTIVE EVENT')))
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
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: groups.isEmpty
                          ? const Center(child: Text('NO BOOKINGS FOR THIS EVENT'))
                          : ListView.separated(
                              itemCount: groups.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.06),
                              ),
                              itemBuilder: (context, index) {
                                final group = groups[index];
                                final active = index == selectedBookingIndex;

                                return ListTile(
                                  selected: active,
                                  selectedTileColor: accent.withOpacity(0.16),
                                  title: Text(
                                    group.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    group.email.isNotEmpty ? group.email : group.phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '¥ ${MoneyUtils.formatMoney(BookingUtils.grandTotal(group))}',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        'Balance ¥ ${MoneyUtils.formatMoney(BookingUtils.balance(group))}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  onTap: () => onSelectBooking(index),
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
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: selectedGroup == null
                          ? const Center(child: Text('SELECT A PERSON'))
                          : _BookingDetails(
                              accent: accent,
                              event: event!,
                              group: selectedGroup,
                              paymentStatuses: paymentStatuses,
                              checkInStatuses: checkInStatuses,
                              onToggleCheckIn: onToggleCheckIn,
                              onEditContact: onEditContact,
                              onDeleteGroup: onDeleteGroup,
                              onAddTicket: onAddTicket,
                              onAddPayment: onAddPayment,
                              onDeletePayment: onDeletePayment,
                              onAddSale: onAddSale,
                              onDeleteSale: onDeleteSale,
                              onSaveGroup: onSaveGroup,
                              onSave: onSave,
                              onRefresh: onRefresh,
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

class _BookingDetails extends StatelessWidget {
  final Color accent;
  final EventRecord event;
  final BookingGroup group;
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
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                group.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => onToggleCheckIn(group),
              icon: Icon(group.primary.checkInStatus == 'Checked In'
                  ? Icons.how_to_reg
                  : Icons.login),
              label: Text(group.primary.checkInStatus == 'Checked In'
                  ? 'UNDO CHECK-IN'
                  : 'CHECK IN'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => onEditContact(group),
              icon: const Icon(Icons.edit_outlined),
            ),
            const SizedBox(width: 4),
            OutlinedButton.icon(
              onPressed: () => onDeleteGroup(group),
              icon: const Icon(Icons.delete_outline),
              label: const Text('DELETE'),
            ),
          ],
        ),
        const SizedBox(height: 2),
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
            color: accent.withOpacity(0.10),
            border: Border.all(color: accent.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LOGISTICS / BOOKING DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
              const SizedBox(height: 8),
              SummaryLine(label: 'Pickup', value: group.needsPickup ? 'YES' : 'NO'),
              SummaryLine(label: 'Training', value: group.needsTraining ? 'YES' : 'NO'),
              SummaryLine(label: 'Guest Names', value: group.guestNames.isEmpty ? 'None' : group.guestNames),
              SummaryLine(label: 'Language', value: group.languagePreference.isEmpty ? '-' : group.languagePreference),
              SummaryLine(label: 'Rental Gun Sets', value: BookingUtils.groupRentalCount(group).toString()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SummaryLine(label: 'Booking ID', value: group.bookingId),
        SummaryLine(label: 'Transaction ID', value: group.primary.transactionId),
        SummaryLine(label: 'Tickets Total', value: '¥ ${MoneyUtils.formatMoney(BookingUtils.ticketsTotal(group))}'),
        SummaryLine(label: 'Sales Total', value: '¥ ${MoneyUtils.formatMoney(BookingUtils.salesTotal(group))}'),
        SummaryLine(label: 'Grand Total', value: '¥ ${MoneyUtils.formatMoney(BookingUtils.grandTotal(group))}'),
        SummaryLine(label: 'Paid', value: '¥ ${MoneyUtils.formatMoney(BookingUtils.paymentsTotal(group))}'),
        SummaryLine(label: 'Balance', value: '¥ ${MoneyUtils.formatMoney(BookingUtils.balance(group))}'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  value: paymentStatuses.contains(group.primary.paymentStatus)
                      ? group.primary.paymentStatus
                      : 'Unpaid',
                  decoration: const InputDecoration(
                    labelText: 'Payment Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: paymentStatuses
                      .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    group.primary.paymentStatus = v;
                    await onSaveGroup(group);
                    onRefresh();
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  value: checkInStatuses.contains(group.primary.checkInStatus)
                      ? group.primary.checkInStatus
                      : 'Not Checked In',
                  decoration: const InputDecoration(
                    labelText: 'Check In',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: checkInStatuses
                      .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    group.primary.checkInStatus = v;
                    await onSaveGroup(group);
                    onRefresh();
                  },
                ),
              ),
            ),
          ],
        ),
        PersistentEditField(
          label: 'Notes',
          value: group.primary.notes,
          onChanged: (v) async {
            group.primary.notes = v;
            await onSaveGroup(group);
            onRefresh();
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
              onPressed: () => onAddTicket(group),
              child: const Text('ADD TICKET'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...group.tickets.map((ticket) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.03),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.ticketName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('${ticket.quantity} × ', style: const TextStyle(fontSize: 12)),
                          SizedBox(
                            width: 120,
                            child: PersistentEditField(
                              label: 'Price',
                              value: ticket.price,
                              onChanged: (v) async {
                                ticket.price = v;
                                BookingUtils.recalculateAllTotals(event);
                                await onSave();
                                onRefresh();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                    BookingUtils.recalculateAllTotals(event);
                    await onSave();
                    onRefresh();
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
              onPressed: () => onAddPayment(group),
              child: const Text('ADD PAYMENT'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...group.primary.payments.map((payment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.03),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¥ ${payment.amount}  -  ${payment.method}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                  onPressed: () => onDeletePayment(group, payment.id),
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
              onPressed: () => onAddSale(group),
              child: const Text('ADD SALE'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...group.primary.sales.map((sale) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.03),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: PersistentEditField(
                    label: 'Product',
                    value: sale.product,
                    onChanged: (v) async {
                      sale.product = v;
                      await onSaveGroup(group);
                      onRefresh();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: PersistentEditField(
                    label: 'Price',
                    value: sale.price,
                    onChanged: (v) async {
                      sale.price = v;
                      BookingUtils.recalculateAllTotals(event);
                      await onSaveGroup(group);
                      await onSave();
                      onRefresh();
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => onDeleteSale(group, sale.id),
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
