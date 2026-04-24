import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../services/device_identity_service.dart';
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
  late final TextEditingController _usernameController;
  String _savedUsername = '';

  @override
  void initState() {
    super.initState();
    _eventController = TextEditingController();
    _usernameController = TextEditingController();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final u = await DeviceIdentityService.getUsername();
    if (mounted) {
      setState(() {
        _savedUsername = u;
        _usernameController.text = u;
      });
    }
  }

  Future<void> _saveUsername() async {
    final u = _usernameController.text.trim();
    await DeviceIdentityService.setUsername(u);
    if (mounted) {
      setState(() => _savedUsername = u);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            u.isEmpty ? 'Username cleared.' : 'Username set to "$u".',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _eventController.dispose();
    _usernameController.dispose();
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
    final isNarrow = MediaQuery.of(context).size.width < 1200;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 320,
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
          // ── Device Identity ────────────────────────────────────────────────
          Row(
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Device Username',
                    hintText: 'e.g. Admin-1',
                    border: const OutlineInputBorder(),
                    suffixIcon: _savedUsername.isNotEmpty
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 18)
                        : null,
                  ),
                  onSubmitted: (_) => _saveUsername(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saveUsername,
                child: const Text('SAVE USERNAME'),
              ),
              const SizedBox(width: 8),
              if (_savedUsername.isNotEmpty)
                Text(
                  'Active: $_savedUsername',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: SingleChildScrollView(
              child: isNarrow
                  ? Column(
                      children: [
                        InfoCard(
                          title: 'System Status',
                          accent: widget.accent,
                          children: [
                            InfoLine('State', widget.systemStatus),
                            InfoLine('Events',
                                widget.appState.events.length.toString()),
                            InfoLine(
                                'Active', widget.activeEvent?.name ?? 'None'),
                            InfoLine('Export', widget.exportStatus),
                            InfoLine('Sync', widget.syncStatus),
                          ],
                        ),
                        const SizedBox(height: 14),
                        InfoCard(
                          title: 'Import Control',
                          accent: widget.accent,
                          children: [
                            ActionLine(
                              label: 'Workbook (.xlsx)',
                              onTap: () =>
                                  _runIfActive(widget.onImportWorkbook),
                            ),
                            ActionLine(
                              label: 'Bookings (CSV/Excel)',
                              onTap: () =>
                                  _runIfActive(widget.onImportBookings),
                            ),
                            ActionLine(
                              label: 'Tickets (CSV/Excel)',
                              onTap: () => _runIfActive(widget.onImportTickets),
                            ),
                            ActionLine(
                              label: 'Members (CSV/Excel)',
                              onTap: () => _runIfActive(widget.onImportMembers),
                            ),
                            ActionLine(
                              label: 'Schedule (CSV/Excel)',
                              onTap: () =>
                                  _runIfActive(widget.onImportSchedule),
                            ),
                            ActionLine(
                              label: 'Game Modes (CSV/Excel)',
                              onTap: () =>
                                  _runIfActive(widget.onImportGameModes),
                            ),
                            ActionLine(
                              label: 'Field Map Image',
                              onTap: () =>
                                  _runIfActive(widget.onImportFieldMap),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        InfoCard(
                          title: 'Supabase Sync',
                          accent: widget.accent,
                          children: [
                            ActionLine(
                              label: 'Sync Merge to Supabase',
                              onTap: widget.onSyncPush,
                            ),
                            ActionLine(
                              label: 'Sync Merge from Supabase',
                              onTap: widget.onSyncPull,
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'System Status',
                            accent: widget.accent,
                            children: [
                              InfoLine('State', widget.systemStatus),
                              InfoLine('Events',
                                  widget.appState.events.length.toString()),
                              InfoLine(
                                  'Active', widget.activeEvent?.name ?? 'None'),
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
                                onTap: () =>
                                    _runIfActive(widget.onImportWorkbook),
                              ),
                              ActionLine(
                                label: 'Bookings (CSV/Excel)',
                                onTap: () =>
                                    _runIfActive(widget.onImportBookings),
                              ),
                              ActionLine(
                                label: 'Tickets (CSV/Excel)',
                                onTap: () =>
                                    _runIfActive(widget.onImportTickets),
                              ),
                              ActionLine(
                                label: 'Members (CSV/Excel)',
                                onTap: () =>
                                    _runIfActive(widget.onImportMembers),
                              ),
                              ActionLine(
                                label: 'Schedule (CSV/Excel)',
                                onTap: () =>
                                    _runIfActive(widget.onImportSchedule),
                              ),
                              ActionLine(
                                label: 'Game Modes (CSV/Excel)',
                                onTap: () =>
                                    _runIfActive(widget.onImportGameModes),
                              ),
                              ActionLine(
                                label: 'Field Map Image',
                                onTap: () =>
                                    _runIfActive(widget.onImportFieldMap),
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
                                label: 'Sync Merge to Supabase',
                                onTap: widget.onSyncPush,
                              ),
                              ActionLine(
                                label: 'Sync Merge from Supabase',
                                onTap: widget.onSyncPull,
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
    );
  }
}
