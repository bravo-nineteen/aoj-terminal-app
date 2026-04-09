import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/ui_components.dart';

class SystemPanel extends StatefulWidget {
  final Color accent;
  final AppStateData appState;
  final EventRecord? activeEvent;
  final String systemStatus;
  final String exportStatus;
  final Future<void> Function(String) onCreateEvent;
  final Future<void> Function() onExportEvent;
  final Future<void> Function() onExportBookings;
  final Future<void> Function() onImportWorkbook;
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
    required this.onImportWorkbook,
    required this.onImportBookings,
    required this.onImportTickets,
    required this.onImportMembers,
    required this.onImportSchedule,
    required this.onImportGameModes,
    required this.onImportFieldMap,
  });

  @override
  State<SystemPanel> createState() => _SystemPanelState();
}

class _SystemPanelState extends State<SystemPanel> {
  late final TextEditingController _eventController;

  @override
  void initState() {
    super.initState();
    _eventController = TextEditingController();
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateEvent() async {
    final name = _eventController.text.trim();
    if (name.isEmpty) return;

    await widget.onCreateEvent(name);

    if (mounted) {
      _eventController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveEvent = widget.activeEvent != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'AOJ CENTRAL COMMAND',
            subtitle: 'Offline event management and import control',
            accent: widget.accent,
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _eventController,
                  decoration: const InputDecoration(
                    labelText: 'Create New Event',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _handleCreateEvent(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _handleCreateEvent,
                child: const Text('ADD EVENT'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: hasActiveEvent ? widget.onExportEvent : null,
                child: const Text('EXPORT JSON'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: hasActiveEvent ? widget.onExportBookings : null,
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
                    accent: widget.accent,
                    children: [
                      InfoLine('State', widget.systemStatus),
                      InfoLine('Events', widget.appState.events.length.toString()),
                      InfoLine('Active', widget.activeEvent?.name ?? 'None'),
                      InfoLine('Export', widget.exportStatus),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InfoCard(
                    title: 'Import Control',
                    accent: widget.accent,
                    children: [
                      ActionLine(
                        label: 'Workbook (.xlsx)',
                        onTap: hasActiveEvent ? widget.onImportWorkbook : null,
                      ),
                      ActionLine(
                        label: 'Bookings CSV',
                        onTap: hasActiveEvent ? widget.onImportBookings : null,
                      ),
                      ActionLine(
                        label: 'Tickets CSV',
                        onTap: hasActiveEvent ? widget.onImportTickets : null,
                      ),
                      ActionLine(
                        label: 'Members CSV',
                        onTap: hasActiveEvent ? widget.onImportMembers : null,
                      ),
                      ActionLine(
                        label: 'Schedule CSV',
                        onTap: hasActiveEvent ? widget.onImportSchedule : null,
                      ),
                      ActionLine(
                        label: 'Game Modes CSV',
                        onTap: hasActiveEvent ? widget.onImportGameModes : null,
                      ),
                      ActionLine(
                        label: 'Field Map Image',
                        onTap: hasActiveEvent ? widget.onImportFieldMap : null,
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
