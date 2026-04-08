import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/aoj_models.dart';
import '../widgets/desktop_widgets.dart';

class AOJDesktop extends StatefulWidget {
  const AOJDesktop({super.key});

  @override
  State<AOJDesktop> createState() => _AOJDesktopState();
}

class _AOJDesktopState extends State<AOJDesktop> {
  final List<DesktopAppItem> apps = const [
    DesktopAppItem(
      id: 'system',
      title: 'My System',
      icon: Icons.shield_outlined,
      accent: Color(0xFF7E8B63),
      subtitle: 'Command node',
    ),
    DesktopAppItem(
      id: 'event',
      title: 'Event Information',
      icon: Icons.map_outlined,
      accent: Color(0xFFB7A36B),
      subtitle: 'Mission brief',
    ),
    DesktopAppItem(
      id: 'bookings',
      title: 'Bookings',
      icon: Icons.assignment_outlined,
      accent: Color(0xFF8C6A52),
      subtitle: 'Attendance roster',
    ),
    DesktopAppItem(
      id: 'members',
      title: 'Member Information',
      icon: Icons.groups_outlined,
      accent: Color(0xFF5D7D7A),
      subtitle: 'Personnel records',
    ),
    DesktopAppItem(
      id: 'schedule',
      title: 'Schedule',
      icon: Icons.access_time_outlined,
      accent: Color(0xFF6D7F96),
      subtitle: 'Operations timing',
    ),
    DesktopAppItem(
      id: 'props',
      title: 'Prop System',
      icon: Icons.precision_manufacturing_outlined,
      accent: Color(0xFFA06B5C),
      subtitle: 'Field assets',
    ),
    DesktopAppItem(
      id: 'game_modes',
      title: 'Game Modes',
      icon: Icons.sports_esports_outlined,
      accent: Color(0xFF7A6C96),
      subtitle: 'Scenario library',
    ),
  ];

  late final Map<String, DesktopWindowData> windows;

  AppStateData appState = AppStateData(events: [], activeEventId: null);

  String? selectedIconId;
  int nextZ = 10;
  int? selectedBookingIndex;
  int? selectedMemberIndex;
  String bookingSearch = '';
  String gameModeSearch = '';
  String systemStatus = 'READY';
  String exportStatus = 'NO EXPORT YET';
  final TextEditingController propIpController =
      TextEditingController(text: '192.168.4.1');
  bool showPropControlPage = false;
  String propControlStatus = 'PROP CONSOLE OFFLINE';

  final List<String> paymentMethods = const [
    'Cash',
    'Credit Card',
    'Coupon',
    'QR Code',
    'Wire Transfer',
    'PayPal',
    'Imported',
  ];

  final List<String> paymentStatuses = const [
    'Unpaid',
    'Part Paid',
    'Paid',
    'Refunded',
  ];

  final List<String> checkInStatuses = const [
    'Not Checked In',
    'Checked In',
    'Cancelled',
    'No Show',
  ];

  final List<String> membershipLevels = const [
    'Admin',
    'Support',
    'Regular',
    'Elite',
  ];

  @override
  void initState() {
    super.initState();
    windows = {
      for (int i = 0; i < apps.length; i++)
        apps[i].id: DesktopWindowData(
          id: apps[i].id,
          title: apps[i].title,
          icon: apps[i].icon,
          accent: apps[i].accent,
          isOpen: false,
          isMinimized: false,
          isMaximized: false,
          position: Offset(170 + (i % 3) * 70, 90 + (i % 3) * 40),
          size: const Size(800, 540),
          restorePosition: Offset(170 + (i % 3) * 70, 90 + (i % 3) * 40),
          restoreSize: const Size(800, 540),
          zIndex: i,
        ),
    };
    _loadLocalState();
  }

  @override
  void dispose() {
    propIpController.dispose();
    super.dispose();
  }

  EventRecord? get activeEvent {
    if (appState.activeEventId == null) return null;
    for (final event in appState.events) {
      if (event.id == appState.activeEventId) return event;
    }
    return null;
  }

  MemberRecord? get selectedMember {
    final event = activeEvent;
    if (event == null || selectedMemberIndex == null) return null;
    if (selectedMemberIndex! < 0 || selectedMemberIndex! >= event.members.length) {
      return null;
    }
    return event.members[selectedMemberIndex!];
  }

  Future<File> _stateFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/aoj_app_state.json');
  }

  Future<void> _loadLocalState() async {
    try {
      final file = await _stateFile();
      if (await file.exists()) {
        final jsonText = await file.readAsString();
        final map = jsonDecode(jsonText) as Map<String, dynamic>;
        setState(() {
          appState = AppStateData.fromJson(map);
          selectedBookingIndex = 0;
          selectedMemberIndex = activeEvent?.members.isNotEmpty == true ? 0 : null;
          systemStatus = 'LOCAL DATA LOADED';
        });
      }
    } catch (_) {
      setState(() {
        systemStatus = 'LOAD FAILED';
      });
    }
  }

  Future<void> _saveLocalState() async {
    final file = await _stateFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(appState.toJson()),
      flush: true,
    );
    if (mounted) {
      setState(() {
        systemStatus = 'AUTO-SAVED';
      });
    }
  }

  void _bringToFront(String id) {
    setState(() {
      windows[id]!.zIndex = nextZ++;
    });
  }

  void _openWindow(String id) {
    setState(() {
      final window = windows[id]!;
      window.isOpen = true;
      window.isMinimized = false;
      window.zIndex = nextZ++;
      selectedIconId = id;
    });
  }

  void _toggleMinimize(String id) {
    setState(() {
      final window = windows[id]!;
      window.isMinimized = !window.isMinimized;
      if (!window.isMinimized) {
        window.zIndex = nextZ++;
      }
    });
  }

  void _toggleMaximize(String id, Size desktopSize) {
    setState(() {
      final window = windows[id]!;
      if (!window.isMaximized) {
        window.restorePosition = window.position;
        window.restoreSize = window.size;
        window.position = const Offset(8, 8);
        window.size = Size(desktopSize.width - 16, desktopSize.height - 80);
        window.isMaximized = true;
      } else {
        window.position = window.restorePosition;
        window.size = window.restoreSize;
        window.isMaximized = false;
      }
      window.zIndex = nextZ++;
    });
  }

  void _closeWindow(String id) {
    setState(()
