
import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/persistent_edit_field.dart';

class EventPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'MISSION BRIEF',
            subtitle: 'Active event selection, field information and logistics overview',
            accent: accent,
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: appState.activeEventId,
                  decoration: const InputDecoration(
                    labelText: 'Active Event',
                    border: OutlineInputBorder(),
                  ),
                  items: appState.events
                      .map((e) => DropdownMenuItem<String>(value: e.id, child: Text(e.name)))
                      .toList(),
                  onChanged: onSetActiveEvent,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: event == null ? null : onDeleteEvent,
                icon: const Icon(Icons.delete_outline),
                label: const Text('DELETE EVENT'),
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
                    flex: 5,
                    child: ListView(
                      children: [
                        PersistentEditField(
                          label: 'Event Name',
                          value: event!.name,
                          onChanged: (v) async {
                            event!.name = v;
                            await onSave();
                            onRefresh();
                          },
                        ),
                        PersistentEditField(
                          label: 'Venue',
                          value: event!.venue,
                          onChanged: (v) async {
                            event!.venue = v;
                            await onSave();
                          },
                        ),
                        PersistentEditField(
                          label: 'Date',
                          value: event!.date,
                          onChanged: (v) async {
                            event!.date = v;
                            await onSave();
                          },
                        ),
                        PersistentEditField(
                          label: 'Notes',
                          value: event!.notes,
                          maxLines: 5,
                          onChanged: (v) async {
                            event!.notes = v;
                            await onSave();
                          },
                        ),
                        const SizedBox(height: 6),
                        InfoCard(
                          title: 'Event Totals',
                          accent: accent,
                          children: [
                            InfoLine('Booked Persons', BookingUtils.eventBookedPersons(event!).toString()),
                            InfoLine('Ticket Value', '¥ ${MoneyUtils.formatMoney(BookingUtils.eventTicketValue(event!))}'),
                            InfoLine('Sales Value', '¥ ${MoneyUtils.formatMoney(BookingUtils.eventSalesValue(event!))}'),
                            InfoLine('Rental Gun Sets', BookingUtils.eventRentalCount(event!).toString()),
                            InfoLine('Pickup Bookings', BookingUtils.pickupGroups(event!).length.toString()),
                            InfoLine('Training Requests', BookingUtils.trainingGroups(event!).length.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pickup Roster', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: BookingUtils.pickupGroups(event!).isEmpty
                                      ? const Center(child: Text('NO PICKUPS'))
                                      : ListView.builder(
                                          itemCount: BookingUtils.pickupGroups(event!).length,
                                          itemBuilder: (context, index) {
                                            final group = BookingUtils.pickupGroups(event!)[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Text(
                                                '${group.displayName}  ·  ${group.phone.isNotEmpty ? group.phone : group.email}',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Training Requests', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: BookingUtils.trainingGroups(event!).isEmpty
                                      ? const Center(child: Text('NO TRAINING BOOKINGS'))
                                      : ListView.builder(
                                          itemCount: BookingUtils.trainingGroups(event!).length,
                                          itemBuilder: (context, index) {
                                            final group = BookingUtils.trainingGroups(event!)[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Text(
                                                '${group.displayName}${group.languagePreference.isNotEmpty ? '  ·  ${group.languagePreference}' : ''}',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
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
    );
  }
}
