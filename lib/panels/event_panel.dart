import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/desktop_widgets.dart';
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

  String _eventTicketCostPerPerson(EventRecord event) {
    try {
      final dynamic dynamicEvent = event;
      final value = dynamicEvent.ticketCostPerPerson;
      if (value == null) return '0';
      return value.toString();
    } catch (_) {
      return '0';
    }
  }

  Future<void> _setEventTicketCostPerPerson(EventRecord event, String value) async {
    try {
      final dynamic dynamicEvent = event;
      dynamicEvent.ticketCostPerPerson = value.trim().isEmpty ? '0' : value.trim();
      await _saveAndRefresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add "ticketCostPerPerson" to EventRecord to save event ticket costs.'),
        ),
      );
    }
  }

  double _parseMoney(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          color: const Color(0x66121813),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.trim().isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xCC101511),
        border: Border.all(color: widget.accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: widget.accent,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: names.isEmpty
                ? Center(
                    child: Text(
                      title == 'Pickup Roster' ? 'NO PICKUPS' : 'NO TRAINING REQUESTS',
                    ),
                  )
                : ListView.builder(
                    itemCount: names.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.appState.activeEventId,
                  decoration: const InputDecoration(
                    labelText: 'Active Event',
                    border: OutlineInputBorder(),
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
              if (event != null)
                IconButton(
                  tooltip: _isEditing ? 'Finish editing' : 'Edit event',
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  icon: Icon(
                    _isEditing ? Icons.check_circle_outline : Icons.edit_outlined,
                    color: widget.accent,
                  ),
                ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: event == null ? null : widget.onDeleteEvent,
                icon: const Icon(Icons.delete_outline),
                label: const Text('DELETE EVENT'),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                          PersistentEditField(
                            label: 'Ticket Cost Per Person',
                            value: _eventTicketCostPerPerson(event),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) async {
                              await _setEventTicketCostPerPerson(event, v);
                            },
                          ),
                          PersistentEditField(
                            label: 'Notes',
                            value: event.notes,
                            maxLines: 5,
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
                            value: '¥ ${MoneyUtils.formatMoney(_ticketCostPerPersonNumber(event))}',
                          ),
                          _buildReadOnlyRow(
                            label: 'Notes',
                            value: event.notes,
                          ),
                        ],
                        const SizedBox(height: 6),
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
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildRosterCard(
                            title: 'Pickup Roster',
                            names: pickupNames,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: _buildRosterCard(
                            title: 'Training Requests',
                            names: trainingNames,
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
