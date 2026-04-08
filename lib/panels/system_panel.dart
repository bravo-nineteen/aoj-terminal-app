import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/ui_components.dart';

class SystemPanel extends StatelessWidget {
  final Color accent;
  final AppStateData appState;
  final EventRecord? activeEvent;
  final String systemStatus;
  final String exportStatus;
  final Future<void> Function(String) onCreateEvent;
  final Future<void> Function() onExportEvent;
  final Future<void> Function() onExportBookings;
  final Future<void> Function() onImportBookings;
  final Future<void> Function() onImportTickets;
  final Future<void> Function() onImportMembers;
  final Future<void> Function() onImportSchedule;
  final Future<void> Function() onImportGameModes;
  final Future<void> Function() onImportFieldMap;

  const SystemPanel({
    super.key,
    required this.accent,
    required this.appState,
    required this.activeEvent,
    required this.systemStatus,
    required this.exportStatus,
    required this.onCreateEvent,
    required this.onExportEvent,
    required this.onExportBookings,
    required this.onImportBookings,
    required this.onImportTickets,
    required this.onImportMembers,
    required this.onImportSchedule,
    required this.onImportGameModes,
    required this.onImportFieldMap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'AOJ CENTRAL COMMAND',
            subtitle: 'Offline event management and import control',
            accent: accent,
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Create New Event',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => onCreateEvent(controller.text),
                child: const Text('ADD EVENT'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onExportEvent,
                child: const Text('EXPORT JSON'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onExportBookings,
                child: const Text('EXPORT BOOKINGS CSV'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'System Status',
                    accent: accent,
                    children: [
                      InfoLine('State', systemStatus),
                      InfoLine('Events', appState.events.length.toString()),
                      InfoLine('Active', activeEvent?.name ?? 'None'),
                      InfoLine('Export', exportStatus),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InfoCard(
                    title: 'Import Control',
                    accent: accent,
                    children: [
                      ActionLine(label: 'Bookings CSV', onTap: onImportBookings),
                      ActionLine(label: 'Tickets CSV', onTap: onImportTickets),
                      ActionLine(label: 'Members CSV', onTap: onImportMembers),
                      ActionLine(label: 'Schedule CSV', onTap: onImportSchedule),
                      ActionLine(label: 'Game Modes CSV', onTap: onImportGameModes),
                      ActionLine(label: 'Field Map Image', onTap: onImportFieldMap),
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
