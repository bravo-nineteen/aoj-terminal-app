
import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/ui_components.dart';
import '../widgets/prop_webview.dart';

class PropsPanel extends StatelessWidget {
  final Color accent;
  final EventRecord? event;
  final TextEditingController propIpController;
  final bool showPropControlPage;
  final String propControlStatus;
  final VoidCallback onOpenPropControlPage;
  final VoidCallback onClosePropControlPage;
  final String Function() normalizedPropUrl;
  final VoidCallback onPageStarted;
  final VoidCallback onPageFinished;
  final ValueChanged<String> onWebError;

  const PropsPanel({
    super.key,
    required this.accent,
    required this.event,
    required this.propIpController,
    required this.showPropControlPage,
    required this.propControlStatus,
    required this.onOpenPropControlPage,
    required this.onClosePropControlPage,
    required this.normalizedPropUrl,
    required this.onPageStarted,
    required this.onPageFinished,
    required this.onWebError,
  });

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return const Center(child: Text('NO ACTIVE EVENT'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'FIELD ASSETS',
            subtitle: 'Connect to prop Wi-Fi and open on-device control at 192.168.4.1',
            accent: accent,
            icon: Icons.precision_manufacturing_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: InfoCard(
                  title: 'Prop Console',
                  accent: accent,
                  children: [
                    InfoLine('Field Map', event!.fieldMapBase64 == null ? 'NOT LOADED' : 'LOADED'),
                    InfoLine('Notes', event!.notes.isEmpty ? 'NONE' : 'SEE EVENT INFO'),
                    InfoLine('Console', propControlStatus),
                    const InfoLine('Wi-Fi', 'JOIN PROP NETWORK FIRST'),
                    TextField(
                      controller: propIpController,
                      decoration: const InputDecoration(
                        labelText: 'Prop IP / URL',
                        hintText: '192.168.4.1',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onOpenPropControlPage,
                            icon: const Icon(Icons.wifi_find),
                            label: const Text('OPEN PROP PAGE'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: showPropControlPage ? onClosePropControlPage : null,
                            icon: const Icon(Icons.link_off),
                            label: const Text('CLOSE PAGE'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.03),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: const Text(
                        'This does not switch Wi-Fi automatically. Connect the tablet to the prop Wi-Fi first, then open the prop page here.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFAFB7AD), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xCC101511),
                    border: Border.all(color: accent.withOpacity(0.35)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: showPropControlPage
                        ? PropWebView(
                            url: normalizedPropUrl(),
                            onPageStarted: onPageStarted,
                            onPageFinished: onPageFinished,
                            onWebError: onWebError,
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.router_outlined, size: 52, color: Color(0xFF7E8B63)),
                                  SizedBox(height: 12),
                                  Text(
                                    'PROP PAGE STANDBY',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Connect to the prop Wi-Fi network, then open 192.168.4.1 here to change prop settings.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Color(0xFFAFB7AD), height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
