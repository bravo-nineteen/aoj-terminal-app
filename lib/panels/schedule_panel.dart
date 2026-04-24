import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/aoj_models.dart';

class SchedulePanel extends StatefulWidget {
  final Color accent;
  final EventRecord? event;
  final List<GameModeRecord> gameModes;
  final Future<void> Function(String gameModeTitle) onOpenGameMode;
  final Future<void> Function() onSave;
  final VoidCallback onRefresh;

  const SchedulePanel({
    super.key,
    required this.accent,
    required this.event,
    required this.gameModes,
    required this.onOpenGameMode,
    required this.onSave,
    required this.onRefresh,
  });

  @override
  State<SchedulePanel> createState() => _SchedulePanelState();
}

class _SchedulePanelState extends State<SchedulePanel> {
  bool _isEditing = false;
  Uint8List? _cachedFieldMapBytes;
  String? _cachedFieldMapBase64;

  @override
  void initState() {
    super.initState();
    _refreshFieldMapCache();
  }

  @override
  void didUpdateWidget(covariant SchedulePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event?.fieldMapBase64 != widget.event?.fieldMapBase64) {
      _refreshFieldMapCache();
    }
  }

  void _refreshFieldMapCache() {
    final fieldMapBase64 = widget.event?.fieldMapBase64;
    if (fieldMapBase64 == null) {
      _cachedFieldMapBase64 = null;
      _cachedFieldMapBytes = null;
      return;
    }

    if (_cachedFieldMapBase64 == fieldMapBase64) return;

    _cachedFieldMapBase64 = fieldMapBase64;
    try {
      _cachedFieldMapBytes = base64Decode(fieldMapBase64);
    } catch (_) {
      _cachedFieldMapBytes = null;
    }
  }

  Uint8List? _fieldMapBytes() {
    if (widget.event == null || widget.event!.fieldMapBase64 == null) {
      return null;
    }
    return _cachedFieldMapBytes;
  }

  Future<void> _addRow() async {
    widget.event!.schedule.add(
      ScheduleRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        time: '',
        activity: '',
        location: '',
        notes: '',
      ),
    );
    await widget.onSave();
    widget.onRefresh();
    if (mounted) setState(() {});
  }

  Future<void> _deleteRow(int index) async {
    widget.event!.schedule.removeAt(index);
    await widget.onSave();
    widget.onRefresh();
    if (mounted) setState(() {});
  }

  Future<void> _pickGameModeForRow(ScheduleRecord row) async {
    if (widget.gameModes.isEmpty) return;

    String selected = row.gameModeTitle;
    final options = widget.gameModes
        .map((m) => m.title)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (selected.isNotEmpty && !options.contains(selected)) {
      selected = '';
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Link Game Mode'),
              content: DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Game Mode',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('None'),
                  ),
                  ...options.map(
                    (title) => DropdownMenuItem<String>(
                      value: title,
                      child: Text(title),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setLocal(() {
                    selected = value ?? '';
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    row.gameModeTitle = result.trim();
    if (row.gameModeTitle.isNotEmpty && row.activity.trim().isEmpty) {
      row.activity = row.gameModeTitle;
    }
    await widget.onSave();
    widget.onRefresh();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fieldMapBytes = _fieldMapBytes();
    final event = widget.event;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 14),
          if (event == null)
            const Expanded(child: Center(child: Text('NO ACTIVE EVENT')))
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(
                            color: widget.accent.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        children: [
                          // Header bar with edit toggle + add button
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18)),
                              color:
                                  widget.accent.withValues(alpha: 0.10),
                              border: Border(
                                bottom: BorderSide(
                                  color: widget.accent.withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'SCHEDULE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: widget.accent,
                                    ),
                                  ),
                                ),
                                if (_isEditing)
                                  IconButton(
                                    tooltip: 'Add row',
                                    onPressed: _addRow,
                                    icon: const Icon(Icons.add, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: _isEditing
                                      ? 'Done editing'
                                      : 'Edit schedule',
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = !_isEditing;
                                    });
                                  },
                                  icon: Icon(
                                    _isEditing
                                        ? Icons.check_circle_outline
                                        : Icons.edit_outlined,
                                    size: 18,
                                    color: widget.accent,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: event.schedule.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('NO SCHEDULE'),
                                        if (_isEditing) ...[
                                          const SizedBox(height: 10),
                                          TextButton.icon(
                                            onPressed: _addRow,
                                            icon: const Icon(Icons.add,
                                                size: 16),
                                            label:
                                                const Text('Add first entry'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: event.schedule.length,
                                    itemBuilder: (context, index) {
                                      final row = event.schedule[index];
                                      if (_isEditing) {
                                        return _ScheduleEditRow(
                                          key: ValueKey(row.id),
                                          row: row,
                                          gameModes: widget.gameModes,
                                          accent: widget.accent,
                                          onDelete: () => _deleteRow(index),
                                          onSave: () async {
                                            await widget.onSave();
                                          },
                                        );
                                      }
                                      // Read-only display
                                      final headerTime =
                                          row.time.trim().isNotEmpty
                                              ? row.time.trim()
                                              : 'Time TBC';
                                      final headerTitle =
                                          row.activity.trim().isNotEmpty
                                              ? row.activity.trim()
                                              : 'Untitled Activity';
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: row.gameModeTitle.trim().isEmpty
                                            ? null
                                            : () => widget.onOpenGameMode(
                                                  row.gameModeTitle.trim(),
                                                ),
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: Colors.white
                                                .withValues(alpha: 0.03),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.06),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '$headerTime - $headerTitle',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  if (widget.gameModes.isNotEmpty)
                                                    IconButton(
                                                      tooltip: 'Link game mode',
                                                      onPressed: () =>
                                                          _pickGameModeForRow(row),
                                                      icon: Icon(
                                                        row.gameModeTitle
                                                                .trim()
                                                                .isEmpty
                                                            ? Icons.link_outlined
                                                            : Icons.link,
                                                        size: 16,
                                                        color: widget.accent,
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                    ),
                                                ],
                                              ),
                                              if (row.gameModeTitle
                                                  .trim()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: widget.accent
                                                        .withValues(alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(999),
                                                  ),
                                                  child: Text(
                                                    'Game Mode: ${row.gameModeTitle.trim()}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: widget.accent,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (row.notes.trim().isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      left: 12),
                                                  child: Text(
                                                    row.notes.trim(),
                                                    style: const TextStyle(
                                                        fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(
                            color: widget.accent.withValues(alpha: 0.35)),
                      ),
                      child: fieldMapBytes == null
                          ? const Center(child: Text('NO FIELD MAP'))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: InteractiveViewer(
                                child: Image.memory(fieldMapBytes,
                                    fit: BoxFit.contain),
                              ),
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

/// Inline editing row for a single schedule entry.
class _ScheduleEditRow extends StatefulWidget {
  final ScheduleRecord row;
  final List<GameModeRecord> gameModes;
  final Color accent;
  final VoidCallback onDelete;
  final Future<void> Function() onSave;

  const _ScheduleEditRow({
    super.key,
    required this.row,
    required this.gameModes,
    required this.accent,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<_ScheduleEditRow> createState() => _ScheduleEditRowState();
}

class _ScheduleEditRowState extends State<_ScheduleEditRow> {
  late final TextEditingController _timeCtrl;
  late final TextEditingController _activityCtrl;
  late final TextEditingController _notesCtrl;
  String _gameModeTitle = '';

  @override
  void initState() {
    super.initState();
    _timeCtrl = TextEditingController(text: widget.row.time);
    _activityCtrl = TextEditingController(text: widget.row.activity);
    _notesCtrl = TextEditingController(text: widget.row.notes);
    _gameModeTitle = widget.row.gameModeTitle;
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _activityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    widget.row.time = _timeCtrl.text.trim();
    widget.row.activity = _activityCtrl.text.trim();
    widget.row.notes = _notesCtrl.text.trim();
    widget.row.gameModeTitle = _gameModeTitle.trim();
    await widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.accent.withValues(alpha: 0.06),
        border: Border.all(color: widget.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.gameModes.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue:
                  _gameModeTitle.isEmpty ? '' : _gameModeTitle,
              decoration: const InputDecoration(
                labelText: 'Game Mode Link',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('None'),
                ),
                ...widget.gameModes
                    .map((m) => m.title)
                    .toSet()
                    .toList()
                  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))
                    .map(
                      (title) => DropdownMenuItem<String>(
                        value: title,
                        child: Text(title),
                      ),
                    ),
              ],
              onChanged: (value) async {
                setState(() {
                  _gameModeTitle = value ?? '';
                  if (_gameModeTitle.isNotEmpty) {
                    _activityCtrl.text = _gameModeTitle;
                  }
                });
                await _commit();
              },
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onEditingComplete: _commit,
                  onTapOutside: (_) => _commit(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _activityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Activity',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onEditingComplete: _commit,
                  onTapOutside: (_) => _commit(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Delete row',
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                color: Colors.redAccent.withValues(alpha: 0.8),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: const TextStyle(fontSize: 11),
            maxLines: 2,
            onTapOutside: (_) => _commit(),
          ),
        ],
      ),
    );
  }
}
