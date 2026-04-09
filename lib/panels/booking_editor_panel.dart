import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/persistent_edit_field.dart';
import '../widgets/summary_line.dart';
import '../widgets/ui_components.dart';

class BookingEditorPanel extends StatefulWidget {
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

  const BookingEditorPanel({
    super.key,
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
  State<BookingEditorPanel> createState() => _BookingEditorPanelState();
}

class _BookingEditorPanelState extends State<BookingEditorPanel> {
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

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final balance = BookingUtils.balance(group);
    final isOutstanding = balance > 0;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          HeroPanel(
            title: 'BOOKING EDITOR',
            subtitle: 'Two-column booking control and finance editing',
            accent: widget.accent,
            icon: Icons.assignment_ind_outlined,
          ),
          const SizedBox(height: 12),
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
              _StatusBadge(
                text: widget.membershipLevel.isEmpty
                    ? 'NO MEMBERSHIP'
                    : widget.membershipLevel.toUpperCase(),
                background: widget.accent.withOpacity(0.16),
                foreground: widget.accent,
              ),
              const SizedBox(width: 8),
              _StatusBadge(
                text: group.primary.checkInStatus.toUpperCase(),
                background: group.primary.checkInStatus == 'Checked In'
                    ? Colors.green.withOpacity(0.16)
                    : Colors.white.withOpacity(0.08),
                foreground: group.primary.checkInStatus == 'Checked In'
                    ? Colors.greenAccent
                    : Colors.white70,
              ),
              const SizedBox(width: 8),
              _StatusBadge(
                text: group.primary.paymentStatus.toUpperCase(),
                background: group.primary.paymentStatus == 'Paid'
                    ? Colors.green.withOpacity(0.16)
                    : group.primary.paymentStatus == 'Part Paid'
                        ? Colors.orange.withOpacity(0.16)
                        : Colors.red.withOpacity(0.16),
                foreground: group.primary.paymentStatus == 'Paid'
                    ? Colors.greenAccent
                    : group.primary.paymentStatus == 'Part Paid'
                        ? Colors.orangeAccent
                        : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              _StatusBadge(
                text: isOutstanding
                    ? 'BAL ¥ ${MoneyUtils.formatMoney(balance)}'
                    : 'CLEAR',
                background: isOutstanding
                    ? Colors.red.withOpacity(0.18)
                    : Colors.green.withOpacity(0.16),
                foreground:
                    isOutstanding ? Colors.redAccent : Colors.greenAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _sectionCard(
                        title: 'Member / Booking Details',
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => widget.onToggleCheckIn(group),
                              icon: Icon(
                                group.primary.checkInStatus == 'Checked In'
                                    ? Icons.how_to_reg
                                    : Icons.login,
                              ),
                              label: Text(
                                group.primary.checkInStatus == 'Checked In'
                                    ? 'UNDO'
                                    : 'CHECK IN',
                              ),
                            ),
                            IconButton(
                              onPressed: () => widget.onEditContact(group),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit contact',
                            ),
                            OutlinedButton.icon(
                              onPressed: () => widget.onDeleteGroup(group),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('DELETE'),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SummaryLine(label: 'Email', value: group.primary.email),
                            SummaryLine(label: 'Phone', value: group.primary.phone),
                            SummaryLine(label: 'Booking ID', value: group.bookingId),
                            SummaryLine(
                              label: 'Transaction ID',
                              value: group.primary.transactionId,
                            ),
                            SummaryLine(
                              label: 'Booking Date',
                              value: group.primary.bookingDate,
                            ),
                            SummaryLine(
                              label: 'Pickup',
                              value: group.needsPickup ? 'YES' : 'NO',
                            ),
                            SummaryLine(
                              label: 'Training',
                              value: group.needsTraining ? 'YES' : 'NO',
                            ),
                            SummaryLine(
                              label: 'Guest Names',
                              value: group.guestNames.isEmpty
                                  ? 'None'
                                  : group.guestNames,
                            ),
                            SummaryLine(
                              label: 'Language',
                              value: group.languagePreference,
                            ),
                            SummaryLine(
                              label: 'Rental Gun Sets',
                              value: BookingUtils.groupRentalCount(group).toString(),
                            ),
                          ],
                        ),
                      ),
                      _sectionCard(
                        title: 'Totals / Status',
                        child: Column(
                          children: [
                            SummaryLine(
                              label: 'Tickets Total',
                              value:
                                  '¥ ${MoneyUtils.formatMoney(BookingUtils.ticketsTotal(group))}',
                            ),
                            SummaryLine(
                              label: 'Sales Total',
                              value:
                                  '¥ ${MoneyUtils.formatMoney(BookingUtils.salesTotal(group))}',
                            ),
                            SummaryLine(
                              label: 'Grand Total',
                              value:
                                  '¥ ${MoneyUtils.formatMoney(BookingUtils.grandTotal(group))}',
                            ),
                            SummaryLine(
                              label: 'Paid',
                              value:
                                  '¥ ${MoneyUtils.formatMoney(BookingUtils.paymentsTotal(group))}',
                            ),
                            SummaryLine(
                              label: 'Balance',
                              value:
                                  '¥ ${MoneyUtils.formatMoney(BookingUtils.balance(group))}',
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: widget.paymentStatuses.contains(
                                      group.primary.paymentStatus)
                                  ? group.primary.paymentStatus
                                  : 'Unpaid',
                              decoration: const InputDecoration(
                                labelText: 'Payment Status',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: widget.paymentStatuses
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                group.primary.paymentStatus = v;
                                await _saveGroupAndRefresh();
                              },
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: widget.checkInStatuses.contains(
                                      group.primary.checkInStatus)
                                  ? group.primary.checkInStatus
                                  : 'Not Checked In',
                              decoration: const InputDecoration(
                                labelText: 'Check In',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: widget.checkInStatuses
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                group.primary.checkInStatus = v;
                                await _saveGroupAndRefresh();
                              },
                            ),
                          ],
                        ),
                      ),
                      _sectionCard(
                        title: 'Notes',
                        child: PersistentEditField(
                          label: 'Notes',
                          value: group.primary.notes,
                          maxLines: 5,
                          onChanged: (v) async {
                            group.primary.notes = v;
                            await _saveGroupAndRefresh();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ListView(
                    children: [
                      _sectionCard(
                        title: 'Tickets',
                        trailing: ElevatedButton(
                          onPressed: () => widget.onAddTicket(group),
                          child: const Text('ADD TICKET'),
                        ),
                        child: Column(
                          children: group.tickets.isEmpty
                              ? const [Text('NO TICKETS')]
                              : group.tickets.map((ticket) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withOpacity(0.03),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.07),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ticket.ticketName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Qty ${ticket.quantity} • ¥ ${ticket.price} • ${ticket.status}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _editTicketPrice(ticket),
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: 'Edit ticket price',
                                        ),
                                        DropdownButton<String>(
                                          value: ticket.status == 'Cancelled'
                                              ? 'Cancelled'
                                              : 'Active',
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Active',
                                              child: Text('Keep'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Cancelled',
                                              child: Text('Cancel'),
                                            ),
                                          ],
                                          onChanged: (value) async {
                                            if (value == null) return;
                                            ticket.status = value;
                                            BookingUtils.recalculateAllTotals(
                                              widget.event,
                                            );
                                            await _saveEventAndRefresh();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                      _sectionCard(
                        title: 'Payments',
                        trailing: ElevatedButton(
                          onPressed: () => widget.onAddPayment(group),
                          child: const Text('ADD PAYMENT'),
                        ),
                        child: Column(
                          children: group.primary.payments.isEmpty
                              ? const [Text('NO PAYMENTS')]
                              : group.primary.payments.map((payment) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withOpacity(0.03),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.07),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '¥ ${payment.amount} • ${payment.method}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (payment.note.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 4,
                                                  ),
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
                                          onPressed: () => widget.onDeletePayment(
                                            group,
                                            payment.id,
                                          ),
                                          icon:
                                              const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                      _sectionCard(
                        title: 'Sales',
                        trailing: ElevatedButton(
                          onPressed: () => widget.onAddSale(group),
                          child: const Text('ADD SALE'),
                        ),
                        child: Column(
                          children: group.primary.sales.isEmpty
                              ? const [Text('NO SALES')]
                              : group.primary.sales.map((sale) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withOpacity(0.03),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.07),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sale.product.isEmpty
                                                    ? 'Unnamed item'
                                                    : sale.product,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '¥ ${sale.price}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => widget.onDeleteSale(
                                            group,
                                            sale.id,
                                          ),
                                          icon:
                                              const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                    ],
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

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _StatusBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
