import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../widgets/ui_components.dart';

class SystemPanel extends StatefulWidget {
  final Color accent;
  final AppStateData appState;
  final EventRecord? activeEvent;
  final String systemStatus;
  final String exportStatus;
  final String syncStatus;
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
  final Future<void> Function() onSyncPush;
  final Future<void> Function() onSyncPull;

  const SystemPanel({
    super.key,
    required this.accent,
    required this.appState,
    required this.activeEvent,
    required this.systemStatus,
    required this.exportStatus,
    required this.syncStatus,
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
    required this.onSyncPush,
    required this.onSyncPull,
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

  Future<void> _runIfActive(Future<void> Function() action) async {
    if (widget.activeEvent == null) return;
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveEvent = widget.activeEvent != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                      InfoLine('Sync', widget.syncStatus),
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
                        onTap: () => _runIfActive(widget.onImportWorkbook),
                      ),
                      ActionLine(
                        label: 'Bookings CSV',
                        onTap: () => _runIfActive(widget.onImportBookings),
                      ),
                      ActionLine(
                        label: 'Tickets CSV',
                        onTap: () => _runIfActive(widget.onImportTickets),
                      ),
                      ActionLine(
                        label: 'Members CSV',
                        onTap: () => _runIfActive(widget.onImportMembers),
                      ),
                      ActionLine(
                        label: 'Schedule CSV',
                        onTap: () => _runIfActive(widget.onImportSchedule),
                      ),
                      ActionLine(
                        label: 'Game Modes CSV',
                        onTap: () => _runIfActive(widget.onImportGameModes),
                      ),
                      ActionLine(
                        label: 'Field Map Image',
                        onTap: () => _runIfActive(widget.onImportFieldMap),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InfoCard(
                    title: 'Supabase Sync',
                    accent: widget.accent,
                    children: [
                      ActionLine(
                        label: 'Push to Supabase',
                        onTap: widget.onSyncPush,
                      ),
                      ActionLine(
                        label: 'Pull from Supabase',
                        onTap: widget.onSyncPull,
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
