import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/persistent_edit_field.dart';
import '../widgets/summary_line.dart';

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
  final Future<void> Function(BookingGroup) onOpenTicketEditor;

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
    required this.onOpenTicketEditor,
  });

  @override
  State<BookingEditorPanel> createState() => _BookingEditorPanelState();
}

class _BookingEditorPanelState extends State<BookingEditorPanel> {
  bool _dirty = false;

  Future<void> _markDirtyAndSaveGroup() async {
    _dirty = true;
    await widget.onSaveGroup(widget.group);
    widget.onRefresh();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveAll() async {
    await widget.onSaveGroup(widget.group);
    await widget.onSave();
    _dirty = false;
    widget.onRefresh();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121813),
          title: const Text('Delete Booking'),
          content: const Text(
            'Are you sure you want to delete this booking?\nThis cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await widget.onDeleteGroup(widget.group);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final grandTotal = BookingUtils.grandTotal(group);
    final paid = BookingUtils.paymentsTotal(group);
    final balance = BookingUtils.balance(group);
    final outstanding = balance > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.membershipLevel.isNotEmpty
                        ? '${group.displayName} (${widget.membershipLevel})'
                        : group.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_dirty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'UNSAVED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _saveAll,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('SAVE'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        _sectionCard(
                          title: 'Member / Booking',
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              IconButton(
                                onPressed: () => widget.onEditContact(group),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit contact',
                              ),
                              IconButton(
                                onPressed: _confirmAndDelete,
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                tooltip: 'Delete booking',
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SummaryLine(
                                  label: 'Email', value: group.primary.email),
                              SummaryLine(
                                  label: 'Phone', value: group.primary.phone),
                              SummaryLine(
                                  label: 'Booking ID', value: group.bookingId),
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
                            ],
                          ),
                        ),
                        _sectionCard(
                          title: 'Financial / Status',
                          child: Column(
                            children: [
                              SummaryLine(
                                label: 'Tickets',
                                value:
                                    '¥ ${MoneyUtils.formatMoney(BookingUtils.ticketsTotal(group))}',
                              ),
                              SummaryLine(
                                label: 'Sales',
                                value:
                                    '¥ ${MoneyUtils.formatMoney(BookingUtils.salesTotal(group))}',
                              ),
                              SummaryLine(
                                label: 'Total',
                                value:
                                    '¥ ${MoneyUtils.formatMoney(grandTotal)}',
                              ),
                              SummaryLine(
                                label: 'Paid',
                                value: '¥ ${MoneyUtils.formatMoney(paid)}',
                              ),
                              SummaryLine(
                                label: 'Balance',
                                value: '¥ ${MoneyUtils.formatMoney(balance)}',
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue:
                                          widget.paymentStatuses.contains(
                                        group.primary.paymentStatus,
                                      )
                                              ? group.primary.paymentStatus
                                              : 'Unpaid',
                                      decoration: const InputDecoration(
                                        labelText: 'Payment',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
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
                                        await _markDirtyAndSaveGroup();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue:
                                          widget.checkInStatuses.contains(
                                        group.primary.checkInStatus,
                                      )
                                              ? group.primary.checkInStatus
                                              : 'Not Checked In',
                                      decoration: const InputDecoration(
                                        labelText: 'Check-in',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
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
                                        await _markDirtyAndSaveGroup();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (outstanding) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    'Outstanding balance: ¥ ${MoneyUtils.formatMoney(balance)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _sectionCard(
                          title: 'Notes',
                          child: PersistentEditField(
                            label: 'Notes',
                            value: group.primary.notes,
                            maxLines: 4,
                            onChanged: (v) async {
                              group.primary.notes = v;
                              await _markDirtyAndSaveGroup();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        _sectionCard(
                          title: 'Tickets',
                          trailing: ElevatedButton.icon(
                            onPressed: () => widget.onOpenTicketEditor(group),
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text('EDIT'),
                          ),
                          child: Column(
                            children: group.tickets.isEmpty
                                ? <Widget>[const Text('NO TICKETS')]
                                : group.tickets.map<Widget>((ticket) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white
                                            .withValues(alpha: 0.03),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.05),
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
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Qty ${ticket.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFAFB7AD),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '¥ ${ticket.price}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                          ),
                        ),
                        _sectionCard(
                          title: 'Payments / Sales',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Payments',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              widget.onAddPayment(group),
                                          icon: const Icon(Icons.add, size: 18),
                                          tooltip: 'Add payment',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ...group.primary.payments.map(
                                      (payment) => Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.white
                                              .withValues(alpha: 0.03),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.05),
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
                                                    '¥ ${payment.amount}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  Text(
                                                    payment.method,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  if (payment.note.isNotEmpty)
                                                    Text(
                                                      payment.note,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            Color(0xFFAFB7AD),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  widget.onDeletePayment(
                                                group,
                                                payment.id,
                                              ),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Sales',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              widget.onAddSale(group),
                                          icon: const Icon(Icons.add, size: 18),
                                          tooltip: 'Add sale',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ...group.primary.sales.map(
                                      (sale) => Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.white
                                              .withValues(alpha: 0.03),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.05),
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
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
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
                                              onPressed: () =>
                                                  widget.onDeleteSale(
                                                group,
                                                sale.id,
                                              ),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
