
import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/ui_components.dart';

class GameModesPanel extends StatelessWidget {
  final Color accent;
  final EventRecord? event;
  final List<GameModeRecord> modes;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onImportGameModes;

  const GameModesPanel({
    super.key,
    required this.accent,
    required this.event,
    required this.modes,
    required this.onSearchChanged,
    required this.onImportGameModes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'GAME MODES',
            subtitle: 'Imported game mode library with search',
            accent: accent,
            icon: Icons.sports_esports_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    labelText: 'Search game modes',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onImportGameModes,
                child: const Text('IMPORT GAME MODES'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (event == null)
            const Expanded(child: Center(child: Text('NO ACTIVE EVENT')))
          else if (event!.gameModes.isEmpty)
            const Expanded(child: Center(child: Text('NO GAME MODES IMPORTED')))
          else
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xCC101511),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: ListView.builder(
                  itemCount: modes.length,
                  itemBuilder: (context, index) {
                    final mode = modes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.03),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          if (mode.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              mode.description,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFAFB7AD)),
                            ),
                          ],
                          const SizedBox(height: 8),
                          ...mode.data.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
