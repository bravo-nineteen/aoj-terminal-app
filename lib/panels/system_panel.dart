import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final SyncDiagnosticsRecord syncDiagnostics;
  final SchemaHealthRecord schemaHealth;
  final List<MergeConflictRecord> recentConflicts;
  final Future<void> Function() onRefreshSchemaHealth;

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
    required this.syncDiagnostics,
    required this.schemaHealth,
    required this.recentConflicts,
    required this.onRefreshSchemaHealth,
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

  String _compactTimestamp(String iso) {
    if (iso.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _compactError(String value) {
    final normalized = value.replaceAll('\n', ' ').trim();
    if (normalized.length <= 96) return normalized;
    return '${normalized.substring(0, 96)}...';
  }

  Future<void> _copyLastSyncError() async {
    final error = widget.syncDiagnostics.lastError.trim();
    if (error.isEmpty) return;
    final detail = [
      'operation=${widget.syncDiagnostics.operation}',
      'started=${widget.syncDiagnostics.startedAt}',
      'completed=${widget.syncDiagnostics.completedAt}',
      'error_code=${widget.syncDiagnostics.lastErrorCode}',
      'error=${widget.syncDiagnostics.lastError}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: detail));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Last sync error details copied.')),
    );
  }

  Future<void> _showConflictDetailsDialog() async {
    if (widget.recentConflicts.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Merge Conflict Details'),
          content: SizedBox(
            width: 720,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.recentConflicts.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final c = widget.recentConflicts[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.entityType}:${c.entityId} • ${c.field}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('Local: ${c.localValue}'),
                    const SizedBox(height: 4),
                    Text('Cloud: ${c.cloudValue}'),
                    const SizedBox(height: 4),
                    Text('Resolved: ${c.resolvedValue}'),
                  ],
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
                            InfoLine(
                              'Schema',
                              widget.schemaHealth.healthy ? 'Healthy' : 'Needs Fix',
                            ),
                            InfoLine(
                              'Last Sync Error',
                              widget.syncDiagnostics.lastErrorCode.isEmpty
                                  ? '-'
                                  : widget.syncDiagnostics.lastErrorCode,
                            ),
                            InfoLine(
                              'Conflicts',
                              widget.syncDiagnostics.conflicts.toString(),
                            ),
                            if (!widget.schemaHealth.healthy)
                              ...widget.schemaHealth.issues
                                  .take(3)
                                  .map((i) => InfoLine('Schema Issue', i)),
                            ActionLine(
                              label: 'Refresh Schema Health',
                              onTap: widget.onRefreshSchemaHealth,
                            ),
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
                            InfoLine('Started', _compactTimestamp(widget.syncDiagnostics.startedAt)),
                            InfoLine('Completed', _compactTimestamp(widget.syncDiagnostics.completedAt)),
                            InfoLine('Local Events',
                                widget.syncDiagnostics.localEvents.toString()),
                            InfoLine('Cloud Events',
                                widget.syncDiagnostics.cloudEvents.toString()),
                            InfoLine('Merged Events',
                                widget.syncDiagnostics.mergedEvents.toString()),
                            if (widget.syncDiagnostics.lastError.isNotEmpty)
                              InfoLine('Last Error', _compactError(widget.syncDiagnostics.lastError)),
                            if (widget.syncDiagnostics.lastError.isNotEmpty)
                              ActionLine(
                                label: 'Copy Last Sync Error Details',
                                onTap: _copyLastSyncError,
                              ),
                            if (widget.recentConflicts.isNotEmpty)
                              ActionLine(
                                label: 'View Conflict Details',
                                onTap: _showConflictDetailsDialog,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (widget.recentConflicts.isNotEmpty)
                          InfoCard(
                            title: 'Recent Merge Conflicts',
                            accent: widget.accent,
                            children: widget.recentConflicts
                                .take(6)
                                .map(
                                  (c) => InfoLine(
                                    '${c.entityType}:${c.entityId} ${c.field}',
                                    'resolved="${c.resolvedValue}"',
                                  ),
                                )
                                .toList(),
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
                              InfoLine(
                                'Schema',
                                widget.schemaHealth.healthy ? 'Healthy' : 'Needs Fix',
                              ),
                              InfoLine(
                                'Last Sync Error',
                                widget.syncDiagnostics.lastErrorCode.isEmpty
                                    ? '-'
                                    : widget.syncDiagnostics.lastErrorCode,
                              ),
                              InfoLine(
                                'Conflicts',
                                widget.syncDiagnostics.conflicts.toString(),
                              ),
                              if (!widget.schemaHealth.healthy)
                                ...widget.schemaHealth.issues
                                    .take(3)
                                    .map((i) => InfoLine('Schema Issue', i)),
                              ActionLine(
                                label: 'Refresh Schema Health',
                                onTap: widget.onRefreshSchemaHealth,
                              ),
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
                                InfoLine('Started', _compactTimestamp(widget.syncDiagnostics.startedAt)),
                                InfoLine('Completed', _compactTimestamp(widget.syncDiagnostics.completedAt)),
                              InfoLine('Local Events',
                                  widget.syncDiagnostics.localEvents.toString()),
                              InfoLine('Cloud Events',
                                  widget.syncDiagnostics.cloudEvents.toString()),
                              InfoLine('Merged Events',
                                  widget.syncDiagnostics.mergedEvents.toString()),
                              if (widget.syncDiagnostics.lastError.isNotEmpty)
                                InfoLine('Last Error', _compactError(widget.syncDiagnostics.lastError)),
                              if (widget.syncDiagnostics.lastError.isNotEmpty)
                                ActionLine(
                                  label: 'Copy Last Sync Error Details',
                                  onTap: _copyLastSyncError,
                                ),
                              if (widget.recentConflicts.isNotEmpty)
                                ActionLine(
                                  label: 'View Conflict Details',
                                  onTap: _showConflictDetailsDialog,
                                ),
                            ],
                          ),
                        ),
                        if (widget.recentConflicts.isNotEmpty) ...[
                          const SizedBox(width: 14),
                          Expanded(
                            child: InfoCard(
                              title: 'Recent Merge Conflicts',
                              accent: widget.accent,
                              children: widget.recentConflicts
                                  .take(6)
                                  .map(
                                    (c) => InfoLine(
                                      '${c.entityType}:${c.entityId} ${c.field}',
                                      'resolved="${c.resolvedValue}"',
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
