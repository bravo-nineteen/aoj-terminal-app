import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/persistent_edit_field.dart';
import '../widgets/ui_components.dart';

class EventPanel extends StatefulWidget {
  final Color accent;
  final AppStateData appState;
  final EventRecord? event;
  final Future<void> Function(String?) onSetActiveEvent;
  final Future<void> Function() onDeleteEvent;
  final Future<void> Function() onSave;
  final VoidCallback onRefresh;

  const EventPanel({
    super.key,
    required this.accent,
    required this.appState,
    required this.event,
    required this.onSetActiveEvent,
    required this.onDeleteEvent,
    required this.onSave,
    required this.onRefresh,
  });

  @override
  State<EventPanel> createState() => _EventPanelState();
}

class _EventPanelState extends State<EventPanel> {
  bool _isEditing = false;

  @override
  void didUpdateWidget(covariant EventPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event?.id != widget.event?.id) {
      _isEditing = false;
    }
  }

  Future<void> _saveAndRefresh() async {
    await widget.onSave();
    widget.onRefresh();
    if (mounted) {
      setState(() {});
    }
  }

  double _parseMoney(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _eventTicketCostPerPerson(EventRecord event) {
    return event.ticketCostPerPerson.trim().isEmpty
        ? '0'
        : event.ticketCostPerPerson.trim();
  }

  Future<void> _setEventTicketCostPerPerson(
    EventRecord event,
    String value,
  ) async {
    event.ticketCostPerPerson = value.trim().isEmpty ? '0' : value.trim();
    await _saveAndRefresh();
  }

  Future<void> _addLunchOption(EventRecord event) async {
    event.lunchOptions.add(
      LunchOptionRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: '',
        fee: '0',
      ),
    );
    await _saveAndRefresh();
  }

  Future<void> _removeLunchOption(EventRecord event, String optionId) async {
    event.lunchOptions.removeWhere((o) => o.id == optionId);
    for (final booking in event.bookings) {
      booking.lunchOrderIds.removeWhere((id) => id == optionId);
    }
    await _saveAndRefresh();
  }

  String _lunchOptionsSummary(EventRecord event) {
    if (event.lunchOptions.isEmpty) return '—';
    return event.lunchOptions
        .map((o) => '${o.name.isEmpty ? 'Unnamed' : o.name} (¥ ${MoneyUtils.formatMoney(_parseMoney(o.fee))})')
        .join(', ');
  }

  double _ticketRevenue(EventRecord event) {
    return BookingUtils.eventTicketValue(event);
  }

  double _donationTicketRevenue(EventRecord event) {
    return BookingUtils.eventDonationValue(event);
  }

  double _salesRevenue(EventRecord event) {
    return BookingUtils.eventSalesValue(event);
  }

  int _bookedPersons(EventRecord event) {
    return BookingUtils.eventBookedPersons(event);
  }

  double _ticketCostPerPersonNumber(EventRecord event) {
    return _parseMoney(_eventTicketCostPerPerson(event));
  }

  double _ticketCostTotal(EventRecord event) {
    return _bookedPersons(event) * _ticketCostPerPersonNumber(event);
  }

  double _estimatedProfit(EventRecord event) {
    final manualExpensesTotal = event.expenses.fold<double>(
      0.0,
      (sum, e) => sum + _parseMoney(e.amount),
    );
    final ticketAndDonations =
        _ticketRevenue(event) + _donationTicketRevenue(event);
    return ticketAndDonations -
        _ticketCostTotal(event) +
        _salesRevenue(event) -
        manualExpensesTotal;
  }

  int _lunchOrderCount(EventRecord event) {
    return BookingUtils.lunchBreakdown(event)
        .fold<int>(0, (sum, item) => sum + item.count);
  }

  double _lunchPassThroughTotal(EventRecord event) {
    return BookingUtils.groupedBookingsForEvent(event).fold<double>(
      0,
      (sum, group) => sum + BookingUtils.lunchTotal(group, event),
    );
  }

  List<_LunchOrderPerson> _lunchOrdersByPerson(EventRecord event) {
    final optionsById = <String, LunchOptionRecord>{
      for (final option in event.lunchOptions) option.id: option,
    };

    final rows = <_LunchOrderPerson>[];
    for (final group in BookingUtils.groupedBookingsForEvent(event)) {
      if (group.primary.lunchOrderIds.isEmpty) continue;

      final selectedOptions = group.primary.lunchOrderIds
          .map((id) => optionsById[id])
          .whereType<LunchOptionRecord>()
          .toList();

      if (selectedOptions.isEmpty) continue;

      final totalFee = selectedOptions.fold<double>(
        0.0,
        (sum, option) => sum + _parseMoney(option.fee),
      );

      rows.add(
        _LunchOrderPerson(
          personName: group.displayName,
          orderNames: selectedOptions
              .map((o) => o.name.trim().isEmpty ? 'Unnamed' : o.name.trim())
              .toList(),
          totalFee: totalFee,
        ),
      );
    }

    rows.sort(
      (a, b) => a.personName.toLowerCase().compareTo(b.personName.toLowerCase()),
    );
    return rows;
  }

  Future<void> _showLunchBreakdownDetails(EventRecord event) async {
    final rows = _lunchOrdersByPerson(event);
    if (rows.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lunch Orders'),
          content: SizedBox(
            width: 560,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final row = rows[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0x66121813),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.personName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row.orderNames.join(', '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total fee: ¥ ${MoneyUtils.formatMoney(row.totalFee)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameRosterName(BookingGroup group) async {
    final controller = TextEditingController(text: group.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    final updatedName = (result ?? '').trim();
    if (updatedName.isEmpty) return;

    final parts = updatedName.split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    for (final row in group.rows) {
      row.firstName = firstName;
      row.lastName = lastName;
    }
    await _saveAndRefresh();
  }

  Future<void> _removeFromRoster(
    BookingGroup group, {
    required bool pickup,
  }) async {
    final rosterLabel = pickup ? 'pickup' : 'training';
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove From List'),
          content: Text(
            'Remove ${group.displayName} from the $rosterLabel list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) return;

    for (final row in group.rows) {
      if (pickup) {
        row.needsPickup = false;
      } else {
        row.needsTraining = false;
      }
    }
    await _saveAndRefresh();
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          color: const Color(0x66121813),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 125,
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.trim().isEmpty ? '—' : value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterCard({
    required String title,
    required List<BookingGroup> groups,
    Widget? topExtra,
    String emptyText = 'NONE',
    bool editable = false,
    Future<void> Function(BookingGroup)? onRename,
    Future<void> Function(BookingGroup)? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xCC101511),
        border: Border.all(color: widget.accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: widget.accent,
            ),
          ),
          if (topExtra != null) ...[
            const SizedBox(height: 8),
            topExtra,
          ],
          const SizedBox(height: 8),
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Text(
                      emptyText,
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final name = group.displayName.trim().isEmpty
                          ? 'Unnamed Booking'
                          : group.displayName.trim();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (editable) ...[
                              IconButton(
                                tooltip: 'Edit name',
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: widget.accent,
                                ),
                                onPressed: onRename == null
                                    ? null
                                    : () async {
                                        await onRename(group);
                                      },
                              ),
                              IconButton(
                                tooltip: 'Remove from list',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                                onPressed: onRemove == null
                                    ? null
                                    : () async {
                                        await onRemove(group);
                                      },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    final pickupGroups =
      event == null ? <BookingGroup>[] : BookingUtils.pickupGroups(event);

    final trainingGroups =
      event == null ? <BookingGroup>[] : BookingUtils.trainingGroups(event);

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
                    labelText: 'Active Event',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: widget.appState.events
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(
                            e.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: widget.onSetActiveEvent,
                ),
              ),
              const SizedBox(width: 8),
              if (event != null)
                IconButton(
                  tooltip: _isEditing ? 'Finish editing' : 'Edit event',
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  icon: Icon(
                    _isEditing
                        ? Icons.check_circle_outline
                        : Icons.edit_outlined,
                    color: widget.accent,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                onPressed: event == null ? null : widget.onDeleteEvent,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('DELETE'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (event == null)
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
                    flex: 5,
                    child: ListView(
                      children: [
                        if (_isEditing) ...[
                          PersistentEditField(
                            label: 'Event Name',
                            value: event.name,
                            onChanged: (v) async {
                              event.name = v;
                              await _saveAndRefresh();
                            },
                          ),
                          PersistentEditField(
                            label: 'Venue',
                            value: event.venue,
                            onChanged: (v) async {
                              event.venue = v;
                              await _saveAndRefresh();
                            },
                          ),
                          PersistentEditField(
                            label: 'Ticket Cost Per Person',
                            value: _eventTicketCostPerPerson(event),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (v) async {
                              await _setEventTicketCostPerPerson(event, v);
                            },
                          ),
                          PersistentEditField(
                            label: 'Date',
                            value: event.date,
                            onChanged: (v) async {
                              event.date = v;
                              await _saveAndRefresh();
                            },
                          ),
                          PersistentEditField(
                            label: 'Time',
                            value: event.time,
                            onChanged: (v) async {
                              event.time = v;
                              await _saveAndRefresh();
                            },
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0x66121813),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'LUNCH OPTIONS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _addLunchOption(event),
                                      icon: const Icon(Icons.add, size: 18),
                                      tooltip: 'Add lunch option',
                                    ),
                                  ],
                                ),
                                if (event.lunchOptions.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text('No lunch options yet.'),
                                  )
                                else
                                  ...event.lunchOptions.map((option) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: PersistentEditField(
                                              label: 'Option Name',
                                              value: option.name,
                                              onChanged: (v) async {
                                                option.name = v;
                                                await _saveAndRefresh();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: PersistentEditField(
                                              label: 'Fee (JPY)',
                                              value: option.fee,
                                              keyboardType: const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                              onChanged: (v) async {
                                                option.fee =
                                                    v.trim().isEmpty ? '0' : v;
                                                await _saveAndRefresh();
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _removeLunchOption(
                                              event,
                                              option.id,
                                            ),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                            ),
                                            tooltip: 'Delete option',
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          PersistentEditField(
                            label: 'Notes',
                            value: event.notes,
                            maxLines: 4,
                            onChanged: (v) async {
                              event.notes = v;
                              await _saveAndRefresh();
                            },
                          ),
                        ] else ...[
                          _buildReadOnlyRow(
                            label: 'Event Name',
                            value: event.name,
                          ),
                          _buildReadOnlyRow(
                            label: 'Venue',
                            value: event.venue,
                          ),
                          _buildReadOnlyRow(
                            label: 'Date',
                            value: event.date,
                          ),
                          _buildReadOnlyRow(
                            label: 'Time',
                            value: event.time,
                          ),
                          _buildReadOnlyRow(
                            label: 'Ticket Cost Per Person',
                            value:
                                '¥ ${MoneyUtils.formatMoney(_ticketCostPerPersonNumber(event))}',
                          ),
                          _buildReadOnlyRow(
                            label: 'Lunch Options',
                            value: _lunchOptionsSummary(event),
                          ),
                          _buildReadOnlyRow(
                            label: 'Notes',
                            value: event.notes,
                          ),
                        ],
                        const SizedBox(height: 4),
                        InfoCard(
                          title: 'Event Totals',
                          accent: widget.accent,
                          children: [
                            InfoLine(
                              'Booked Persons',
                              _bookedPersons(event).toString(),
                            ),
                            InfoLine(
                              'Ticket Value',
                              '¥ ${MoneyUtils.formatMoney(_ticketCostTotal(event))}',
                            ),
                            InfoLine(
                              'Ticket Cost Total',
                              '¥ ${MoneyUtils.formatMoney(_ticketRevenue(event))}',
                            ),
                            InfoLine(
                              'Donation Tickets',
                              '¥ ${MoneyUtils.formatMoney(_donationTicketRevenue(event))}',
                            ),
                            InfoLine(
                              'Sales Value',
                              '¥ ${MoneyUtils.formatMoney(_salesRevenue(event))}',
                            ),
                            InfoLine(
                              'Estimated Profit',
                              '¥ ${MoneyUtils.formatMoney(_estimatedProfit(event))}',
                            ),
                            InfoLine(
                              'Rental Gun Sets',
                              BookingUtils.eventRentalCount(event).toString(),
                            ),
                            InfoLine(
                              'Pickup Bookings',
                              BookingUtils.pickupGroups(event)
                                  .length
                                  .toString(),
                            ),
                            InfoLine(
                              'Lunch Orders',
                              _lunchOrderCount(event).toString(),
                            ),
                            InfoLine(
                              'Lunch Fees (Pass-through)',
                              '¥ ${MoneyUtils.formatMoney(_lunchPassThroughTotal(event))}',
                            ),
                            InfoLine(
                              'Training Requests',
                              BookingUtils.trainingGroups(event)
                                  .length
                                  .toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRosterCard(
                            title: 'Pickup Roster',
                            groups: pickupGroups,
                            emptyText: 'NO PICKUPS',
                            editable: _isEditing,
                            onRename:
                                _isEditing ? _renameRosterName : null,
                            onRemove: _isEditing
                                ? (group) =>
                                    _removeFromRoster(group, pickup: true)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildRosterCard(
                                  title: 'Training Roster',
                                  groups: trainingGroups,
                                  emptyText: 'NO TRAINING REQUESTS',
                                  editable: _isEditing,
                                  onRename:
                                    _isEditing ? _renameRosterName : null,
                                  onRemove: _isEditing
                                    ? (group) =>
                                      _removeFromRoster(group, pickup: false)
                                    : null,
                                  topExtra: _isEditing
                                      ? (event.members.isEmpty
                                          ? PersistentEditField(
                                              label: 'Trainer',
                                              value: event.trainingTrainer,
                                              onChanged: (v) async {
                                                event.trainingTrainer = v;
                                                await _saveAndRefresh();
                                              },
                                            )
                                          : Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              child:
                                                  DropdownButtonFormField<
                                                      String>(
                                                initialValue: event.members.any(
                                                  (m) =>
                                                      m.fullName.trim() ==
                                                      event.trainingTrainer
                                                          .trim(),
                                                )
                                                    ? event.trainingTrainer
                                                        .trim()
                                                    : null,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Trainer',
                                                  border:
                                                      OutlineInputBorder(),
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10,
                                                  ),
                                                ),
                                                items: [
                                                  const DropdownMenuItem<
                                                      String>(
                                                    value: null,
                                                    child: Text('— None —'),
                                                  ),
                                                  ...event.members.map(
                                                    (m) {
                                                      final name =
                                                          m.fullName
                                                              .trim();
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: name.isEmpty
                                                            ? m.id
                                                            : name,
                                                        child: Text(
                                                          name.isEmpty
                                                              ? 'Unnamed'
                                                              : name,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                                onChanged: (v) async {
                                                  event.trainingTrainer =
                                                      v ?? '';
                                                  await _saveAndRefresh();
                                                },
                                              ),
                                            ))
                                      : Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 9,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors.white
                                                .withValues(alpha: 0.03),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.06),
                                            ),
                                          ),
                                          child: Text(
                                            event.trainingTrainer
                                                    .trim()
                                                    .isEmpty
                                                ? 'Trainer: —'
                                                : 'Trainer: ${event.trainingTrainer}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 170,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _showLunchBreakdownDetails(event),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: const Color(0xCC101511),
                                      border: Border.all(
                                        color: widget.accent
                                            .withValues(alpha: 0.30),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Lunch Breakdown',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: widget.accent,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'Tap for details',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white
                                                    .withValues(alpha: 0.65),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final breakdown =
                                                  BookingUtils.lunchBreakdown(
                                                event,
                                              );
                                              if (breakdown.isEmpty) {
                                                return const Center(
                                                  child: Text('NO LUNCH ORDERS'),
                                                );
                                              }
                                              return ListView.separated(
                                                itemCount: breakdown.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 4),
                                                itemBuilder: (context, index) {
                                                  final item =
                                                      breakdown[index];
                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          '${item.option.name.isEmpty ? 'Unnamed' : item.option.name} x ${item.count}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
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
    );
  }
}

class _LunchOrderPerson {
  final String personName;
  final List<String> orderNames;
  final double totalFee;

  const _LunchOrderPerson({
    required this.personName,
    required this.orderNames,
    required this.totalFee,
  });
}
