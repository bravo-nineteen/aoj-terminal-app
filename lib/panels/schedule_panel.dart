
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/aoj_models.dart';

class SchedulePanel extends StatelessWidget {
  final Color accent;
  final EventRecord? event;

  const SchedulePanel({
    super.key,
    required this.accent,
    required this.event,
  });

  Uint8List? _fieldMapBytes() {
    if (event == null || event!.fieldMapBase64 == null) return null;
    try {
      return base64Decode(event!.fieldMapBase64!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldMapBytes = _fieldMapBytes();

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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: event!.schedule.isEmpty
                          ? const Center(child: Text('NO SCHEDULE IMPORTED'))
                          : ListView.builder(
                              itemCount: event!.schedule.length,
                              itemBuilder: (context, index) {
                                final row = event!.schedule[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white.withOpacity(0.03),
                                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: row.data.entries.map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '${entry.key}: ${entry.value}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
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
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: fieldMapBytes == null
                          ? const Center(child: Text('NO FIELD MAP'))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: InteractiveViewer(
                                child: Image.memory(fieldMapBytes, fit: BoxFit.contain),
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
