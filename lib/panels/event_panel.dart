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

  double _ticketRevenue(EventRecord event) {
    return BookingUtils.eventTicketValue(event);
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
    return _ticketRevenue(event) - _ticketCostTotal(event) + _salesRevenue(event);
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
          border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                  color: Colors.white.withOpacity(0.62),
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
    required List<String> names,
    Widget? topExtra,
    String emptyText = 'NONE',
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xCC101511),
        border: Border.all(color: widget.accent.withOpacity(0.30)),
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
            child: names.isEmpty
                ? Center(
                    child: Text(
                      emptyText,
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    itemCount: names.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withOpacity(0.03),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Text(
                          names[index],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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

    final pickupNames = event == null
        ? <String>[]
        : BookingUtils.pickupGroups(event)
            .map((g) => g.displayName.trim())
            .where((name) => name.isNotEmpty)
            .toList();

    final trainingNames = event == null
        ? <String>[]
        : BookingUtils.trainingGroups(event)
            .map((g) => g.displayName.trim())
            .where((name) => name.isNotEmpty)
            .toList();

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
                          Row(
                            children: [
                              Expanded(
                                child: PersistentEditField(
                                  label: 'Date',
                                  value: event.date,
                                  onChanged: (v) async {
                                    event.date = v;
                                    await _saveAndRefresh();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: PersistentEditField(
                                  label: 'Time',
                                  value: event.time,
                                  onChanged: (v) async {
                                    event.time = v;
                                    await _saveAndRefresh();
                                  },
                                ),
                              ),
                            ],
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
                              '¥ ${MoneyUtils.formatMoney(_ticketRevenue(event))}',
                            ),
                            InfoLine(
                              'Ticket Cost Total',
                              '¥ ${MoneyUtils.formatMoney(_ticketCostTotal(event))}',
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
                              BookingUtils.pickupGroups(event).length.toString(),
                            ),
                            InfoLine(
                              'Training Requests',
                              BookingUtils.trainingGroups(event).length.toString(),
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
                            names: pickupNames,
                            emptyText: 'NO PICKUPS',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildRosterCard(
                            title: 'Training Roster',
                            names: trainingNames,
                            emptyText: 'NO TRAINING REQUESTS',
                            topExtra: _isEditing
                                ? PersistentEditField(
                                    label: 'Trainer',
                                    value: event.trainingTrainer,
                                    onChanged: (v) async {
                                      event.trainingTrainer = v;
                                      await _saveAndRefresh();
                                    },
                                  )
                                : Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white.withOpacity(0.03),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                    child: Text(
                                      event.trainingTrainer.trim().isEmpty
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
