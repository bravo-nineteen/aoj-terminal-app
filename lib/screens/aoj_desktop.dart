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
  final TextEditingController propIpController = TextEditingController(text: '192.168.4.1');
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
    setState(() {
      final window = windows[id]!;
      window.isOpen = false;
      window.isMinimized = false;
      window.isMaximized = false;
    });
  }

  void _toggleFromTab(String id) {
    setState(() {
      final window = windows[id]!;
      if (!window.isOpen) {
        window.isOpen = true;
        window.isMinimized = false;
      } else if (window.isMinimized) {
        window.isMinimized = false;
      } else {
        window.isMinimized = true;
      }
      window.zIndex = nextZ++;
    });
  }

  double _parseMoney(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  double _ticketsTotal(BookingGroup group) {
    return group.tickets
        .where((t) => t.status != 'Cancelled')
        .fold(0.0, (sum, t) => sum + _parseMoney(t.price));
  }

  double _salesTotal(BookingGroup group) {
    return group.primary.sales.fold(0.0, (sum, s) => sum + _parseMoney(s.price));
  }

  double _paymentsTotal(BookingGroup group) {
    return group.primary.payments.fold(0.0, (sum, p) => sum + _parseMoney(p.amount));
  }

  double _grandTotal(BookingGroup group) {
    return _ticketsTotal(group) + _salesTotal(group);
  }

  double _balance(BookingGroup group) {
    return _grandTotal(group) - _paymentsTotal(group);
  }

  void _recalculateAllTotals(EventRecord event) {
    final groups = _groupedBookingsForEvent(event);
    for (final group in groups) {
      final total = _formatMoney(_grandTotal(group));
      final totalPaid = _formatMoney(_paymentsTotal(group));
      final balance = _grandTotal(group) - _paymentsTotal(group);
      final nextStatus = _paymentsTotal(group) <= 0
          ? 'Unpaid'
          : balance <= 0
              ? 'Paid'
              : 'Part Paid';
      for (final row in group.rows) {
        row.total = total;
        row.totalPaid = totalPaid;
        row.paymentStatus = nextStatus;
      }
    }
  }

  Future<void> _createEvent(String name) async {
    if (name.trim().isEmpty) return;

    final event = EventRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      venue: '',
      date: '',
      time: '',
      notes: '',
      fieldMapBase64: null,
      bookings: [],
      tickets: [],
      members: [],
      schedule: [],
      gameModes: [],
    );

    setState(() {
      appState.events.add(event);
      appState.activeEventId = event.id;
      selectedBookingIndex = 0;
      selectedMemberIndex = null;
      systemStatus = 'EVENT CREATED';
    });

    await _saveLocalState();
  }

  Future<void> _setActiveEvent(String? eventId) async {
    setState(() {
      appState.activeEventId = eventId;
      selectedBookingIndex = 0;
      selectedMemberIndex = activeEvent?.members.isNotEmpty == true ? 0 : null;
      systemStatus = 'ACTIVE EVENT CHANGED';
    });
    await _saveLocalState();
  }

  Future<void> _importBookingsCsv() async {
    final event = activeEvent;
    if (event == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    final rows = _parseCsv(utf8.decode(bytes));
    if (rows.isEmpty) return;

    final headerIndex = _findHeaderIndex(rows, const ['Name', 'Event']);
    final headers = rows[headerIndex];
    final imported = <BookingRecord>[];

    for (final row in rows.skip(headerIndex + 1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      final map = _rowToMap(headers, row);

      final name = _firstNonEmpty([map['Name']]);
      final firstName = _firstNonEmpty([map['First Name'], _splitFirstName(name)]);
      final lastName = _firstNonEmpty([map['Last Name'], _splitLastName(name)]);
      final rawImportedPaid = _firstNonEmpty([map['Total Paid']]);
      final importedMethod = _firstNonEmpty([
        map['AOJ Payment Method'],
        map['Payment Method'],
        'Cash',
      ]);
      final shouldImportPayment = _isImportedCardPayment(importedMethod) && _parseMoney(rawImportedPaid) > 0;
      final importedPaid = shouldImportPayment ? rawImportedPaid : '';

      final payments = <PaymentRecord>[];
      if (shouldImportPayment) {
        payments.add(
          PaymentRecord(
            id: '${DateTime.now().microsecondsSinceEpoch}${imported.length}',
            amount: importedPaid,
            method: importedMethod,
            note: 'Imported payment',
            date: _firstNonEmpty([map['Booking Date'], map['Date'], '']),
          ),
        );
      }

      imported.add(
        BookingRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString() + imported.length.toString(),
          bookingId: _firstNonEmpty([map['Booking ID'], map['ID']]),
          bookingDate: _firstNonEmpty([map['Booking Date'], map['Date'], map['Created']]),
          firstName: firstName,
          lastName: lastName,
          email: _firstNonEmpty([map['E-mail'], map['Email']]),
          phone: _cleanImportedPhone(_firstNonEmpty([map['Phone'], map['Phone Number'], map['Telephone']])),
          event: _firstNonEmpty([map['Event'], event.name]),
          total: _firstNonEmpty([map['Total']]),
          totalPaid: importedPaid,
          transactionId: _firstNonEmpty([map['Transaction ID']]),
          paymentMethod: _firstNonEmpty([
            map['AOJ Payment Method'],
            map['Payment Method'],
            'Cash',
          ]),
          paymentStatus: _firstNonEmpty([
            map['AOJ Manual Paid'],
            map['Manual Payment Status'],
            'Unpaid',
          ]),
          checkInStatus: _firstNonEmpty([
            map['AOJ Check In'],
            map['Checked In'],
            'Not Checked In',
          ]),
          notes: _firstNonEmpty([
            map['AOJ Notes'],
            map['Internal Notes'],
            map['Booking Comment'],
          ]),
          needsPickup: _looksTrue(_firstNonEmpty([
            map['Do you need pickup from the nearest station?'],
            map['Pickup'],
          ])),
          needsTraining: _looksTrue(_firstNonEmpty([
            map['Do you need beginners training?'],
            map['Training'],
          ])),
          guestNames: _firstNonEmpty([
            map['Guest Name(s) & Gender'],
            map['Guest Names'],
            map['Guests'],
          ]),
          languagePreference: _firstNonEmpty([
            map['Language Preference'],
            map['Language'],
          ]),
          ticketIds: [],
          sales: [],
          payments: payments,
        ),
      );
    }

    setState(() {
      event.bookings = imported;
      _linkTicketsToBookings(event);
      _recalculateAllTotals(event);
      selectedBookingIndex = 0;
      systemStatus = 'BOOKINGS IMPORTED';
    });

    await _saveLocalState();
  }

  Future<void> _importTicketsCsv() async {
    final event = activeEvent;
    if (event == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    final rows = _parseCsv(utf8.decode(bytes));
    if (rows.isEmpty) return;

    final headerIndex = _findHeaderIndex(rows, const ['Name']);
    final headers = rows[headerIndex];
    final imported = <TicketRecord>[];

    for (final row in rows.skip(headerIndex + 1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      final map = _rowToMap(headers, row);

      imported.add(
        TicketRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString() + imported.length.toString(),
          bookingId: _firstNonEmpty([map['Booking ID'], map['ID']]),
          bookingName: _firstNonEmpty([map['Name']]),
          ticketName: _firstNonEmpty([map['Ticket Name'], map['Ticket'], map['Item Name']]),
          price: _firstNonEmpty([map['Ticket Total'], map['Ticket Price'], map['Price'], map['Amount']]),
          spaces: _firstNonEmpty([map['Ticket Spaces'], map['Spaces'], '1']),
          status: _firstNonEmpty([map['Status'], 'Active']),
        ),
      );
    }

    setState(() {
      event.tickets = imported;
      _linkTicketsToBookings(event);
      _recalculateAllTotals(event);
      systemStatus = 'TICKETS IMPORTED';
    });

    await _saveLocalState();
  }

  Future<void> _importMembersCsv() async {
    final event = activeEvent;
    if (event == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    final rows = _parseCsv(utf8.decode(bytes));
    if (rows.isEmpty) return;
    final headers = rows.first;
    final imported = <MemberRecord>[];

    for (final row in rows.skip(1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      final map = _rowToMap(headers, row);
      final name = _firstNonEmpty([map['Name']]);

      imported.add(
        MemberRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString() + imported.length.toString(),
          firstName: _firstNonEmpty([map['First Name'], _splitFirstName(name)]),
          lastName: _firstNonEmpty([map['Last Name'], _splitLastName(name)]),
          dateOfBirth: _firstNonEmpty([map['Date of Birth'], map['DOB']]),
          gender: _firstNonEmpty([map['Gender']]),
          telephone: _firstNonEmpty([map['Telephone'], map['Phone']]),
          email: _firstNonEmpty([map['Email'], map['E-mail']]),
          membershipLevel: _firstNonEmpty([map['Membership Level'], 'Regular']),
        ),
      );
    }

    setState(() {
      event.members = imported;
      selectedMemberIndex = imported.isNotEmpty ? 0 : null;
      systemStatus = 'MEMBERS IMPORTED';
    });

    await _saveLocalState();
  }

  Future<void> _importScheduleCsv() async {
    final event = activeEvent;
    if (event == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    final rows = _parseCsv(utf8.decode(bytes));
    if (rows.isEmpty) return;
    final headers = rows.first;
    final imported = <ScheduleRecord>[];

    for (final row in rows.skip(1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      imported.add(ScheduleRecord(data: _rowToMap(headers, row)));
    }

    setState(() {
      event.schedule = imported;
      systemStatus = 'SCHEDULE IMPORTED';
    });

    await _saveLocalState();
  }

  Future<void> _importGameModesCsv() async {
    final event = activeEvent;
    if (event == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    final rows = _parseCsv(utf8.decode(bytes));
    if (rows.isEmpty) return;
    final headers = rows.first;
    final imported = <GameModeRecord>[];

    for (final row in rows.skip(1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      imported.add(GameModeRecord(data: _rowToMap(headers, row)));
    }

    setState(() {
      event.gameModes = imported;
      systemStatus = 'GAME MODES IMPORTED';
    });

    await _saveLocalState();
  }

  Future<void> _importFieldMap() async {
    final event = activeEvent;
    if (event == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    setState(() {
      event.fieldMapBase64 = base64Encode(bytes);
      systemStatus = 'FIELD MAP IMPORTED';
    });

    await _saveLocalState();
  }

  Future<void> _exportActiveEventJson() async {
    final event = activeEvent;
    if (event == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${event.name.replaceAll(' ', '_')}_export.json');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(event.toJson()),
      flush: true,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'AOJ event export: ${event.name}',
    );

    setState(() {
      exportStatus = 'EXPORTED ${event.name}';
    });
  }

  Future<void> _addManualMember() async {
    final event = activeEvent;
    if (event == null) return;

    setState(() {
      event.members.add(
        MemberRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          firstName: '',
          lastName: '',
          dateOfBirth: '',
          gender: '',
          telephone: '',
          email: '',
          membershipLevel: 'Regular',
        ),
      );
      selectedMemberIndex = event.members.length - 1;
      systemStatus = 'MEMBER ADDED';
    });

    await _saveLocalState();
  }

  Future<void> _deleteSelectedMember() async {
    final event = activeEvent;
    final member = selectedMember;
    if (event == null || member == null) return;

    setState(() {
      event.members.removeWhere((m) => m.id == member.id);
      selectedMemberIndex = null;
      systemStatus = 'MEMBER DELETED';
    });

    await _saveLocalState();
  }

  Future<void> _showEditContactDialog(BookingGroup group) async {
    final emailController = TextEditingController(text: group.primary.email);
    final phoneController = TextEditingController(text: group.primary.phone);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      group.primary.email = emailController.text.trim();
      group.primary.phone = phoneController.text.trim();
      await _saveGroupedBooking(group);
      setState(() {
        systemStatus = 'CONTACT UPDATED';
      });
    }
  }

  Future<void> _showAddTicketDialog(BookingGroup group) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController(text: '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ticket Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final event = activeEvent;
      if (event == null) return;

      final ticket = TicketRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        bookingId: group.primary.bookingId,
        bookingName: group.primary.fullName,
        ticketName: nameController.text.trim().isEmpty ? 'New Ticket' : nameController.text.trim(),
        price: priceController.text.trim().isEmpty ? '0' : priceController.text.trim(),
        spaces: '1',
        status: 'Active',
      );

      setState(() {
        event.tickets.add(ticket);
        _linkTicketsToBookings(event);
        _recalculateAllTotals(event);
        systemStatus = 'TICKET ADDED';
      });

      await _saveLocalState();
    }
  }

  Future<void> _showAddPaymentDialog(BookingGroup group) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String method = paymentMethods.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Add Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: method,
                    items: paymentMethods
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setLocal(() {
                          method = v;
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Method'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      group.primary.payments.add(
        PaymentRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          amount: amountController.text.trim().isEmpty ? '0' : amountController.text.trim(),
          method: method,
          note: noteController.text.trim(),
          date: DateTime.now().toIso8601String(),
        ),
      );
      await _saveGroupedBooking(group);
      final event = activeEvent;
      if (event != null) {
        _recalculateAllTotals(event);
        await _saveLocalState();
      }
      setState(() {
        systemStatus = 'PAYMENT ADDED';
      });
    }
  }

  Future<void> _deletePaymentFromGroup(BookingGroup group, String paymentId) async {
    group.primary.payments.removeWhere((p) => p.id == paymentId);
    await _saveGroupedBooking(group);
    final event = activeEvent;
    if (event != null) {
      _recalculateAllTotals(event);
      await _saveLocalState();
    }
    setState(() {
      systemStatus = 'PAYMENT DELETED';
    });
  }

  Future<void> _addSaleToGroup(BookingGroup group) async {
    group.primary.sales.add(
      SaleRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        product: '',
        price: '0',
      ),
    );
    await _saveGroupedBooking(group);
    final event = activeEvent;
    if (event != null) {
      _recalculateAllTotals(event);
      await _saveLocalState();
    }
    setState(() {
      systemStatus = 'SALE ADDED';
    });
  }

  Future<void> _deleteSaleFromGroup(BookingGroup group, String saleId) async {
    group.primary.sales.removeWhere((s) => s.id == saleId);
    await _saveGroupedBooking(group);
    final event = activeEvent;
    if (event != null) {
      _recalculateAllTotals(event);
      await _saveLocalState();
    }
    setState(() {
      systemStatus = 'SALE DELETED';
    });
  }

  List<BookingGroup> _groupedBookingsForEvent(EventRecord event) {
    final Map<String, List<BookingRecord>> grouped = {};

    for (final booking in event.bookings) {
      final key = _bookingGroupKey(booking);
      grouped.putIfAbsent(key, () => []).add(booking);
    }

    final result = grouped.entries.map((entry) {
      final rows = entry.value;
      final primary = rows.first;

      final ticketIds = <String>{};
      for (final row in rows) {
        ticketIds.addAll(row.ticketIds);
      }

      final tickets = event.tickets.where((t) {
        if (ticketIds.contains(t.id)) return true;
        if (primary.bookingId.isNotEmpty && t.bookingId.isNotEmpty) {
          if (primary.bookingId == t.bookingId) return true;
        }
        return t.bookingName.trim().toLowerCase() ==
            primary.fullName.trim().toLowerCase();
      }).toList();

      return BookingGroup(
        key: entry.key,
        primary: primary,
        rows: rows,
        tickets: tickets,
      );
    }).toList();

    result.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return result;
  }

  List<BookingGroup> _groupedBookingsForActiveEvent() {
    final event = activeEvent;
    if (event == null) return [];
    final groups = _groupedBookingsForEvent(event);

    if (bookingSearch.trim().isEmpty) return groups;
    final q = bookingSearch.trim().toLowerCase();

    return groups.where((g) {
      return g.displayName.toLowerCase().contains(q) ||
          g.email.toLowerCase().contains(q) ||
          g.phone.toLowerCase().contains(q) ||
          g.bookingId.toLowerCase().contains(q) ||
          g.guestNames.toLowerCase().contains(q);
    }).toList();
  }

  List<GameModeRecord> _filteredGameModes() {
    final event = activeEvent;
    if (event == null) return [];
    if (gameModeSearch.trim().isEmpty) return event.gameModes;

    final q = gameModeSearch.trim().toLowerCase();
    return event.gameModes.where((g) => g.data.values.join(' ').toLowerCase().contains(q)).toList();
  }

  String _bookingGroupKey(BookingRecord booking) {
    final bookingId = booking.bookingId.trim().toLowerCase();
    final email = booking.email.trim().toLowerCase();
    final name = booking.fullName.trim().toLowerCase();
    final eventName = booking.event.trim().toLowerCase();

    if (bookingId.isNotEmpty) return 'booking:$eventName:$bookingId';
    if (email.isNotEmpty) return 'email:$eventName:$email';
    return 'name:$eventName:$name';
  }

  Future<void> _deleteBookingGroup(BookingGroup group) async {
    final event = activeEvent;
    if (event == null) return;

    final bookingIds = group.rows.map((r) => r.id).toSet();
    final ticketIds = group.tickets.map((t) => t.id).toSet();

    setState(() {
      event.bookings.removeWhere((b) => bookingIds.contains(b.id));
      event.tickets.removeWhere((t) => ticketIds.contains(t.id));
      selectedBookingIndex = 0;
      systemStatus = 'BOOKING DELETED';
    });

    await _saveLocalState();
  }

  Future<void> _saveGroupedBooking(BookingGroup group) async {
    for (final row in group.rows) {
      row.bookingId = group.primary.bookingId;
      row.bookingDate = group.primary.bookingDate;
      row.firstName = group.primary.firstName;
      row.lastName = group.primary.lastName;
      row.email = group.primary.email;
      row.phone = group.primary.phone;
      row.event = group.primary.event;
      row.total = group.primary.total;
      row.totalPaid = group.primary.totalPaid;
      row.transactionId = group.primary.transactionId;
      row.paymentMethod = group.primary.paymentMethod;
      row.paymentStatus = group.primary.paymentStatus;
      row.checkInStatus = group.primary.checkInStatus;
      row.notes = group.primary.notes;
      row.needsPickup = group.primary.needsPickup;
      row.needsTraining = group.primary.needsTraining;
      row.guestNames = group.primary.guestNames;
      row.languagePreference = group.primary.languagePreference;
      row.sales = group.primary.sales
          .map((s) => SaleRecord(id: s.id, product: s.product, price: s.price))
          .toList();
      row.payments = group.primary.payments
          .map((p) => PaymentRecord(id: p.id, amount: p.amount, method: p.method, note: p.note, date: p.date))
          .toList();
    }

    await _saveLocalState();
  }

  void _linkTicketsToBookings(EventRecord event) {
    for (final booking in event.bookings) {
      booking.ticketIds.clear();
    }

    for (final ticket in event.tickets) {
      final matches = event.bookings.where((booking) {
        final bookingName = booking.fullName.trim().toLowerCase();
        final ticketName = ticket.bookingName.trim().toLowerCase();

        if (ticket.bookingId.isNotEmpty && booking.bookingId.isNotEmpty) {
          if (ticket.bookingId == booking.bookingId) return true;
        }

        return bookingName == ticketName;
      }).toList();

      if (matches.isNotEmpty) {
        matches.first.ticketIds.add(ticket.id);
      }
    }
  }

  bool _looksTrue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return normalized == 'yes' ||
        normalized == 'y' ||
        normalized == 'true' ||
        normalized == '1' ||
        normalized == 'checked in' ||
        normalized == 'paid';
  }

  bool _ticketIsActive(TicketRecord ticket) {
    final status = ticket.status.trim().toLowerCase();
    return status != 'cancelled' && status != 'refunded' && status != 'void';
  }

  bool _ticketIsRental(TicketRecord ticket) {
    final name = ticket.ticketName.toLowerCase();
    return name.contains('rental') ||
        name.contains('gun set') ||
        name.contains('full set') ||
        name.contains('rental set');
  }

  int _ticketQuantity(TicketRecord ticket) {
    final cleaned = ticket.spaces.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleaned) ?? 1;
  }

  int _groupPersonCount(BookingGroup group) {
    final guestCount = _guestListFromRaw(group.guestNames).length;
    return 1 + guestCount;
  }

  int _groupRentalCount(BookingGroup group) {
    return group.tickets
        .where((t) => _ticketIsActive(t) && _ticketIsRental(t))
        .fold<int>(0, (sum, t) => sum + _ticketQuantity(t));
  }

  int _eventBookedPersons(EventRecord event) {
    return _groupedBookingsForEvent(event)
        .fold<int>(0, (sum, g) => sum + _groupPersonCount(g));
  }

  double _eventTicketValue(EventRecord event) {
    return _groupedBookingsForEvent(event)
        .fold<double>(0, (sum, g) => sum + _ticketsTotal(g));
  }

  double _eventSalesValue(EventRecord event) {
    return _groupedBookingsForEvent(event)
        .fold<double>(0, (sum, g) => sum + _salesTotal(g));
  }

  int _eventRentalCount(EventRecord event) {
    return _groupedBookingsForEvent(event)
        .fold<int>(0, (sum, g) => sum + _groupRentalCount(g));
  }

  List<BookingGroup> _pickupGroups(EventRecord event) {
    return _groupedBookingsForEvent(event).where((g) => g.needsPickup).toList();
  }

  List<BookingGroup> _trainingGroups(EventRecord event) {
    return _groupedBookingsForEvent(event).where((g) => g.needsTraining).toList();
  }

  List<String> _guestListFromRaw(String raw) {
    return raw
        .split(RegExp(r'[\n;/]+'))
        .expand((part) => part.split(','))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _toggleCheckInForGroup(BookingGroup group) async {
    final current = group.primary.checkInStatus.trim();
    group.primary.checkInStatus = current == 'Checked In' ? 'Not Checked In' : 'Checked In';
    await _saveGroupedBooking(group);
    setState(() {
      systemStatus = group.primary.checkInStatus == 'Checked In' ? 'CHECKED IN' : 'CHECK-IN CLEARED';
    });
  }

  Future<void> _deleteActiveEvent() async {
    final event = activeEvent;
    if (event == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: Text('Delete ${event.name}? This removes bookings, tickets, members, schedule and game modes for this event.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      appState.events.removeWhere((e) => e.id == event.id);
      appState.activeEventId = appState.events.isNotEmpty ? appState.events.first.id : null;
      selectedBookingIndex = 0;
      selectedMemberIndex = activeEvent?.members.isNotEmpty == true ? 0 : null;
      systemStatus = 'EVENT DELETED';
    });

    await _saveLocalState();
  }

  Uint8List? _fieldMapBytes() {
    final event = activeEvent;
    if (event == null || event.fieldMapBase64 == null) return null;
    try {
      return base64Decode(event.fieldMapBase64!);
    } catch (_) {
      return null;
    }
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(cell.toString());
        cell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        row.add(cell.toString());
        cell.clear();
        rows.add(List<String>.from(row));
        row.clear();
      } else {
        cell.write(char);
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(List<String>.from(row));
    }

    return rows;
  }

  int _findHeaderIndex(List<List<String>> rows, List<String> required) {
    for (int i = 0; i < rows.length; i++) {
      final lower = rows[i].map((e) => e.trim().toLowerCase()).toList();
      final ok = required.every((r) => lower.contains(r.toLowerCase()));
      if (ok) return i;
    }
    return 0;
  }

  Map<String, String> _rowToMap(List<String> headers, List<String> row) {
    final map = <String, String>{};
    for (int i = 0; i < headers.length; i++) {
      map[headers[i]] = i < row.length ? row[i] : '';
    }
    return map;
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final v = value?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _cleanImportedPhone(String value) {
    var cleaned = value.trim();
    if (cleaned.startsWith("'")) {
      cleaned = cleaned.substring(1);
    }
    return cleaned.trim();
  }

  bool _isImportedCardPayment(String method) {
    final normalized = method.trim().toLowerCase();
    return normalized.contains('credit');
  }

  String _splitFirstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '';
  }

  String _splitLastName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ');
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF98A197),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleWindows = windows.values.where((w) => w.isOpen && !w.isMinimized).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    final openTabs = windows.values.where((w) => w.isOpen).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktopSize = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              const AOJDesktopBackground(),
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 0, 0),
                            child: _buildDesktopIcons(),
                          ),
                        ),
                      ),
                      ...visibleWindows.map((w) => _buildWindow(w, desktopSize)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildOpenTabsBar(openTabs),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopIcons() {
    const iconsPerColumn = 5;
    final columnCount = (apps.length / iconsPerColumn).ceil();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(columnCount, (columnIndex) {
        final start = columnIndex * iconsPerColumn;
        final end = math.min(start + iconsPerColumn, apps.length);
        final columnApps = apps.sublist(start, end);

        return Padding(
          padding: EdgeInsets.only(right: columnIndex == columnCount - 1 ? 0 : 18),
          child: SizedBox(
            width: 94,
            child: Column(
              children: columnApps.map((app) {
                final selected = selectedIconId == app.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIconId = app.id;
                      });
                    },
                    onDoubleTap: () => _openWindow(app.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 94,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0x66161F18) : const Color(0x33101812),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? app.accent.withOpacity(0.75) : Colors.white.withOpacity(0.08),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.30),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AOJDesktopIcon(icon: app.icon, accent: app.accent),
                          const SizedBox(height: 8),
                          Text(
                            app.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWindow(DesktopWindowData window, Size desktopSize) {
    return Positioned(
      left: window.position.dx,
      top: window.position.dy,
      width: window.size.width,
      height: window.size.height,
      child: GestureDetector(
        onTap: () => _bringToFront(window.id),
        onPanStart: (_) {
          if (!window.isMaximized) {
            _bringToFront(window.id);
          }
        },
        onPanUpdate: (details) {
          if (!window.isMaximized) {
            setState(() {
              window.position = Offset(
                window.position.dx + details.delta.dx,
                window.position.dy + details.delta.dy,
              );
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: window.accent.withOpacity(0.65), width: 1.3),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF19211B),
                Color(0xFF111612),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    _buildWindowTitleBar(window, desktopSize),
                    Expanded(
                      child: KeyboardSafeArea(
                        child: _buildWindowBody(window),
                      ),
                    ),
                  ],
                ),
              ),
              if (!window.isMaximized)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        final double newWidth =
                            math.max(520.0, window.size.width + details.delta.dx).toDouble();
                        final double newHeight =
                            math.max(340.0, window.size.height + details.delta.dy).toDouble();
                        window.size = Size(newWidth, newHeight);
                        window.restoreSize = window.size;
                      });
                    },
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: window.accent.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: window.accent.withOpacity(0.7)),
                      ),
                      child: const Icon(Icons.open_in_full, size: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowTitleBar(DesktopWindowData window, Size desktopSize) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [window.accent.withOpacity(0.35), const Color(0xFF162019)],
        ),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Icon(window.icon, size: 18, color: window.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              window.title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
          ),
          WindowButton(
            icon: window.isMaximized ? Icons.filter_none : Icons.crop_square,
            color: const Color(0xFF7E8B63),
            onPressed: () => _toggleMaximize(window.id, desktopSize),
          ),
          const SizedBox(width: 8),
          WindowButton(
            icon: Icons.remove,
            color: const Color(0xFFB7A36B),
            onPressed: () => _toggleMinimize(window.id),
          ),
          const SizedBox(width: 8),
          WindowButton(
            icon: Icons.close,
            color: const Color(0xFF9A5A52),
            onPressed: () => _closeWindow(window.id),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowBody(DesktopWindowData window) {
    switch (window.id) {
      case 'system':
        return _buildSystemPanel(window);
      case 'event':
        return _buildEventPanel(window);
      case 'bookings':
        return _buildBookingsPanel(window);
      case 'members':
        return _buildMembersPanel(window);
      case 'schedule':
        return _buildSchedulePanel(window);
      case 'props':
        return _buildPropsPanel(window);
      case 'game_modes':
        return _buildGameModesPanel(window);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSystemPanel(DesktopWindowData window) {
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'AOJ CENTRAL COMMAND',
            subtitle: 'Offline event management and import control',
            accent: window.accent,
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
                onPressed: () => _createEvent(controller.text),
                child: const Text('ADD EVENT'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _exportActiveEventJson,
                child: const Text('EXPORT EVENT'),
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
                    accent: window.accent,
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
                    accent: window.accent,
                    children: [
                      ActionLine(label: 'Bookings CSV', onTap: _importBookingsCsv),
                      ActionLine(label: 'Tickets CSV', onTap: _importTicketsCsv),
                      ActionLine(label: 'Members CSV', onTap: _importMembersCsv),
                      ActionLine(label: 'Schedule CSV', onTap: _importScheduleCsv),
                      ActionLine(label: 'Game Modes CSV', onTap: _importGameModesCsv),
                      ActionLine(label: 'Field Map Image', onTap: _importFieldMap),
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

  Widget _buildEventPanel(DesktopWindowData window) {
    final event = activeEvent;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'MISSION BRIEF',
            subtitle: 'Active event selection, field information and logistics overview',
            accent: window.accent,
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: appState.activeEventId,
                  decoration: const InputDecoration(
                    labelText: 'Active Event',
                    border: OutlineInputBorder(),
                  ),
                  items: appState.events
                      .map((e) => DropdownMenuItem<String>(value: e.id, child: Text(e.name)))
                      .toList(),
                  onChanged: _setActiveEvent,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: event == null ? null : _deleteActiveEvent,
                icon: const Icon(Icons.delete_outline),
                label: const Text('DELETE EVENT'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (event == null)
            const Expanded(child: Center(child: Text('NO ACTIVE EVENT')))
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: ListView(
                      children: [
                        _editField('Event Name', event.name, (v) async {
                          event.name = v;
                          await _saveLocalState();
                          setState(() {});
                        }),
                        _editField('Venue', event.venue, (v) async {
                          event.venue = v;
                          await _saveLocalState();
                        }),
                        _editField('Date', event.date, (v) async {
                          event.date = v;
                          await _saveLocalState();
                        }),
                        _editField('Notes', event.notes, (v) async {
                          event.notes = v;
                          await _saveLocalState();
                        }, maxLines: 5),
                        const SizedBox(height: 6),
                        InfoCard(
                          title: 'Event Totals',
                          accent: window.accent,
                          children: [
                            InfoLine('Booked Persons', _eventBookedPersons(event).toString()),
                            InfoLine('Ticket Value', '¥ ${_formatMoney(_eventTicketValue(event))}'),
                            InfoLine('Sales Value', '¥ ${_formatMoney(_eventSalesValue(event))}'),
                            InfoLine('Rental Gun Sets', _eventRentalCount(event).toString()),
                            InfoLine('Pickup Bookings', _pickupGroups(event).length.toString()),
                            InfoLine('Training Requests', _trainingGroups(event).length.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(color: window.accent.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pickup Roster', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: window.accent)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: _pickupGroups(event).isEmpty
                                      ? const Center(child: Text('NO PICKUPS'))
                                      : ListView.builder(
                                          itemCount: _pickupGroups(event).length,
                                          itemBuilder: (context, index) {
                                            final group = _pickupGroups(event)[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Text(
                                                '${group.displayName}  ·  ${group.phone.isNotEmpty ? group.phone : group.email}',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Training Requests', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: window.accent)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: _trainingGroups(event).isEmpty
                                      ? const Center(child: Text('NO TRAINING BOOKINGS'))
                                      : ListView.builder(
                                          itemCount: _trainingGroups(event).length,
                                          itemBuilder: (context, index) {
                                            final group = _trainingGroups(event)[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Text(
                                                '${group.displayName}${group.languagePreference.isNotEmpty ? '  ·  ${group.languagePreference}' : ''}',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            );
                                          },
                                        ),
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
            ),
        ],
      ),
    );
  }

  Widget _buildBookingsPanel(DesktopWindowData window) {
    final event = activeEvent;
    final groups = _groupedBookingsForActiveEvent();

    BookingGroup? selectedGroup;
    if (selectedBookingIndex != null &&
        selectedBookingIndex! >= 0 &&
        selectedBookingIndex! < groups.length) {
      selectedGroup = groups[selectedBookingIndex!];
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'LOGISTICS / BOOKING DETAILS',
            subtitle: 'One person per booking with logistics, tickets, payments and sales',
            accent: window.accent,
            icon: Icons.assignment_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: appState.activeEventId,
                  decoration: const InputDecoration(
                    labelText: 'Event',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: appState.events
                      .map((e) => DropdownMenuItem<String>(value: e.id, child: Text(e.name)))
                      .toList(),
                  onChanged: (value) async {
                    await _setActiveEvent(value);
                    setState(() {
                      selectedBookingIndex = 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (v) {
                    setState(() {
                      bookingSearch = v;
                      selectedBookingIndex = 0;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search name / email / phone / booking ID / guest',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (event == null)
            const Expanded(child: Center(child: Text('NO ACTIVE EVENT')))
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(color: window.accent.withOpacity(0.35)),
                      ),
                      child: groups.isEmpty
                          ? const Center(child: Text('NO BOOKINGS FOR THIS EVENT'))
                          : ListView.separated(
                              itemCount: groups.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.06),
                              ),
                              itemBuilder: (context, index) {
                                final group = groups[index];
                                final active = index == selectedBookingIndex;

                                return ListTile(
                                  selected: active,
                                  selectedTileColor: window.accent.withOpacity(0.16),
                                  title: Text(
                                    group.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    group.email.isNotEmpty ? group.email : group.phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('¥ ${_formatMoney(_grandTotal(group))}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                      Text('Balance ¥ ${_formatMoney(_balance(group))}', style: const TextStyle(fontSize: 10)),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      selectedBookingIndex = index;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(color: window.accent.withOpacity(0.35)),
                      ),
                      child: selectedGroup == null
                          ? const Center(child: Text('SELECT A PERSON'))
                          : ListView(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedGroup.displayName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _toggleCheckInForGroup(selectedGroup!),
                                      icon: Icon(selectedGroup!.primary.checkInStatus == 'Checked In'
                                          ? Icons.how_to_reg
                                          : Icons.login),
                                      label: Text(selectedGroup.primary.checkInStatus == 'Checked In'
                                          ? 'UNDO CHECK-IN'
                                          : 'CHECK IN'),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _showEditContactDialog(selectedGroup!),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    const SizedBox(width: 4),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await _deleteBookingGroup(selectedGroup!);
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('DELETE'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedGroup.primary.email,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFAFB7AD)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedGroup.primary.phone,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFAFB7AD)),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: window.accent.withOpacity(0.10),
                                    border: Border.all(color: window.accent.withOpacity(0.35)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('LOGISTICS / BOOKING DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: window.accent)),
                                      const SizedBox(height: 8),
                                      _summaryLine('Pickup', selectedGroup.needsPickup ? 'YES' : 'NO'),
                                      _summaryLine('Training', selectedGroup.needsTraining ? 'YES' : 'NO'),
                                      _summaryLine('Guest Names', selectedGroup.guestNames.isEmpty ? 'None' : selectedGroup.guestNames),
                                      _summaryLine('Language', selectedGroup.languagePreference.isEmpty ? '-' : selectedGroup.languagePreference),
                                      _summaryLine('Rental Gun Sets', _groupRentalCount(selectedGroup).toString()),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _summaryLine('Booking ID', selectedGroup.bookingId),
                                _summaryLine('Transaction ID', selectedGroup.primary.transactionId),
                                _summaryLine('Tickets Total', '¥ ${_formatMoney(_ticketsTotal(selectedGroup))}'),
                                _summaryLine('Sales Total', '¥ ${_formatMoney(_salesTotal(selectedGroup))}'),
                                _summaryLine('Grand Total', '¥ ${_formatMoney(_grandTotal(selectedGroup))}'),
                                _summaryLine('Paid', '¥ ${_formatMoney(_paymentsTotal(selectedGroup))}'),
                                _summaryLine('Balance', '¥ ${_formatMoney(_balance(selectedGroup))}'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _dropdownField(
                                        'Payment Status',
                                        paymentStatuses,
                                        selectedGroup.primary.paymentStatus.isEmpty
                                            ? 'Unpaid'
                                            : selectedGroup.primary.paymentStatus,
                                        (v) async {
                                          selectedGroup!.primary.paymentStatus = v;
                                          await _saveGroupedBooking(selectedGroup);
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _dropdownField(
                                        'Check In',
                                        checkInStatuses,
                                        selectedGroup.primary.checkInStatus.isEmpty
                                            ? 'Not Checked In'
                                            : selectedGroup.primary.checkInStatus,
                                        (v) async {
                                          selectedGroup!.primary.checkInStatus = v;
                                          await _saveGroupedBooking(selectedGroup);
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                _editField('Notes', selectedGroup.primary.notes, (v) async {
                                  selectedGroup!.primary.notes = v;
                                  await _saveGroupedBooking(selectedGroup);
                                  setState(() {});
                                }),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Tickets',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _showAddTicketDialog(selectedGroup!),
                                      child: const Text('ADD TICKET'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...selectedGroup.tickets.map((ticket) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withOpacity(0.03),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ticket.ticketName,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Text('${ticket.quantity} × ', style: const TextStyle(fontSize: 12)),
                                                  SizedBox(
                                                    width: 120,
                                                    child: _editField('Price', ticket.price, (v) async {
                                                      ticket.price = v;
                                                      if (event != null) {
                                                        _recalculateAllTotals(event);
                                                      }
                                                      await _saveLocalState();
                                                      setState(() {});
                                                    }),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownButton<String>(
                                          value: ticket.status == 'Cancelled' ? 'Cancelled' : 'Active',
                                          items: const [
                                            DropdownMenuItem(value: 'Active', child: Text('Keep')),
                                            DropdownMenuItem(value: 'Cancelled', child: Text('Cancel')),
                                          ],
                                          onChanged: (value) async {
                                            if (value == null) return;
                                            setState(() {
                                              ticket.status = value;
                                              if (event != null) {
                                                _recalculateAllTotals(event);
                                              }
                                            });
                                            await _saveLocalState();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Payments',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _showAddPaymentDialog(selectedGroup!),
                                      child: const Text('ADD PAYMENT'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...selectedGroup.primary.payments.map((payment) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withOpacity(0.03),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '¥ ${payment.amount}  -  ${payment.method}',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                              ),
                                              if (payment.note.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    payment.note,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFFAFB7AD),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _deletePaymentFromGroup(selectedGroup!, payment.id),
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Sales',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _addSaleToGroup(selectedGroup!),
                                      child: const Text('ADD SALE'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...selectedGroup.primary.sales.map((sale) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withOpacity(0.03),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _editField('Product', sale.product, (v) async {
                                            sale.product = v;
                                            await _saveGroupedBooking(selectedGroup!);
                                          }),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 120,
                                          child: _editField('Price', sale.price, (v) async {
                                            sale.price = v;
                                            if (event != null) {
                                              _recalculateAllTotals(event);
                                            }
                                            await _saveGroupedBooking(selectedGroup!);
                                            await _saveLocalState();
                                            setState(() {});
                                          }),
                                        ),
                                        IconButton(
                                          onPressed: () => _deleteSaleFromGroup(selectedGroup!, sale.id),
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
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

  Widget _buildMembersPanel(DesktopWindowData window) {
    final event = activeEvent;
    final member = selectedMember;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'PERSONNEL RECORDS',
            subtitle: 'Member data, manual add, edit and delete',
            accent: window.accent,
            icon: Icons.groups_outlined,
          ),
          const SizedBox(height: 14),
          if (event == null)
            const Expanded(child: Center(child: Text('NO ACTIVE EVENT')))
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: _addManualMember,
                            child: const Text('ADD MEMBER'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: const Color(0xCC101511),
                              border: Border.all(color: window.accent.withOpacity(0.35)),
                            ),
                            child: event.members.isEmpty
                                ? const Center(child: Text('NO MEMBERS'))
                                : ListView.builder(
                                    itemCount: event.members.length,
                                    itemBuilder: (context, index) {
                                      final row = event.members[index];
                                      final active = index == selectedMemberIndex;
                                      return ListTile(
                                        selected: active,
                                        selectedTileColor: window.accent.withOpacity(0.16),
                                        title: Text(
                                          row.fullName.isEmpty ? 'Unnamed Member' : row.fullName,
                                        ),
                                        subtitle: Text(row.email),
                                        trailing: Text(
                                          row.membershipLevel,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            selectedMemberIndex = index;
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(color: window.accent.withOpacity(0.35)),
                      ),
                      child: member == null
                          ? const Center(child: Text('SELECT A MEMBER'))
                          : ListView(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        member.fullName.isEmpty ? 'Unnamed Member' : member.fullName,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _deleteSelectedMember,
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('DELETE'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _editField('First Name', member.firstName, (v) async {
                                  member.firstName = v;
                                  await _saveLocalState();
                                  setState(() {});
                                }),
                                _editField('Last Name', member.lastName, (v) async {
                                  member.lastName = v;
                                  await _saveLocalState();
                                  setState(() {});
                                }),
                                _editField('Date of Birth', member.dateOfBirth, (v) async {
                                  member.dateOfBirth = v;
                                  await _saveLocalState();
                                }),
                                _editField('Gender', member.gender, (v) async {
                                  member.gender = v;
                                  await _saveLocalState();
                                }),
                                _editField('Telephone', member.telephone, (v) async {
                                  member.telephone = v;
                                  await _saveLocalState();
                                }),
                                _editField('Email', member.email, (v) async {
                                  member.email = v;
                                  await _saveLocalState();
                                }),
                                _dropdownField(
                                  'Membership Level',
                                  membershipLevels,
                                  member.membershipLevel.isEmpty ? 'Regular' : member.membershipLevel,
                                  (v) async {
                                    member.membershipLevel = v;
                                    await _saveLocalState();
                                    setState(() {});
                                  },
                                ),
                              ],
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

  Widget _buildSchedulePanel(DesktopWindowData window) {
    final event = activeEvent;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'OPERATIONS TIMING',
            subtitle: 'Imported schedule for active event',
            accent: window.accent,
            icon: Icons.access_time_outlined,
          ),
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
                        border: Border.all(color: window.accent.withOpacity(0.35)),
                      ),
                      child: event.schedule.isEmpty
                          ? const Center(child: Text('NO SCHEDULE IMPORTED'))
                          : ListView.builder(
                              itemCount: event.schedule.length,
                              itemBuilder: (context, index) {
                                final row = event.schedule[index];
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
                        border: Border.all(color: window.accent.withOpacity(0.35)),
                      ),
                      child: _fieldMapBytes() == null
                          ? const Center(child: Text('NO FIELD MAP'))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: InteractiveViewer(
                                child: Image.memory(_fieldMapBytes()!, fit: BoxFit.contain),
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

  String _normalizedPropUrl() {
    final raw = propIpController.text.trim();
    if (raw.isEmpty) return 'http://192.168.4.1';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return 'http://$raw';
  }

  void _openPropControlPage() {
    FocusScope.of(context).unfocus();
    setState(() {
      showPropControlPage = true;
      propControlStatus = 'PROP CONSOLE OPEN';
    });
  }

  void _closePropControlPage() {
    setState(() {
      showPropControlPage = false;
      propControlStatus = 'PROP CONSOLE OFFLINE';
    });
  }

  Widget _buildPropsPanel(DesktopWindowData window) {
    final event = activeEvent;
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
            accent: window.accent,
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
                  accent: window.accent,
                  children: [
                    InfoLine('Field Map', event.fieldMapBase64 == null ? 'NOT LOADED' : 'LOADED'),
                    InfoLine('Notes', event.notes.isEmpty ? 'NONE' : 'SEE EVENT INFO'),
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
                            onPressed: _openPropControlPage,
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
                            onPressed: showPropControlPage ? _closePropControlPage : null,
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
                    border: Border.all(color: window.accent.withOpacity(0.35)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: showPropControlPage
                        ? PropWebView(
                            url: _normalizedPropUrl(),
                            onPageStarted: () {
                              if (!mounted) return;
                              setState(() {
                                propControlStatus = 'CONNECTING TO PROP';
                              });
                            },
                            onPageFinished: () {
                              if (!mounted) return;
                              setState(() {
                                propControlStatus = 'PROP CONSOLE LINKED';
                              });
                            },
                            onWebError: (message) {
                              if (!mounted) return;
                              setState(() {
                                propControlStatus = message;
                              });
                            },
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


  Widget _buildGameModesPanel(DesktopWindowData window) {
    final event = activeEvent;
    final modes = _filteredGameModes();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'GAME MODES',
            subtitle: 'Imported game mode library with search',
            accent: window.accent,
            icon: Icons.sports_esports_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) {
                    setState(() {
                      gameModeSearch = v;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search game modes',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _importGameModesCsv,
                child: const Text('IMPORT GAME MODES'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (event == null)
            const Expanded(child: Center(child: Text('NO ACTIVE EVENT')))
          else if (event.gameModes.isEmpty)
            const Expanded(child: Center(child: Text('NO GAME MODES IMPORTED')))
          else
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xCC101511),
                  border: Border.all(color: window.accent.withOpacity(0.35)),
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

  Widget _buildOpenTabsBar(List<DesktopWindowData> openTabs) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC0C120D),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF121813),
              border: Border.all(color: const Color(0x337E8B63)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF7E8B63)),
                const SizedBox(width: 8),
                Text(
                  activeEvent?.name ?? 'NO ACTIVE EVENT',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: openTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = openTabs[index];
                final active = !tab.isMinimized;
                return GestureDetector(
                  onTap: () => _toggleFromTab(tab.id),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: active ? tab.accent.withOpacity(0.20) : const Color(0xFF121813),
                      border: Border.all(
                        color: active ? tab.accent.withOpacity(0.85) : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(tab.icon, size: 16, color: tab.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tab.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(
    String label,
    String value,
    Future<void> Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return _PersistentEditField(
      label: label,
      value: value,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
  class _PersistentEditField extends StatefulWidget {
  final String label;
  final String value;
  final Future<void> Function(String) onChanged;
  final int maxLines;

  const _PersistentEditField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<_PersistentEditField> createState() => _PersistentEditFieldState();
}

class _PersistentEditFieldState extends State<_PersistentEditField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _PersistentEditField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _controller,
        focusNode: _focus,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (v) {
          widget.onChanged(v);
        },
      ),
    );
  }
}
  Widget _dropdownField(
    String label,
    List<String> items,
    String value,
    Future<void> Function(String) onChanged,
  ) {
    final safeValue = items.contains(value) ? value : items.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) {
            onChanged(v);
          }
        },
      ),
    );
  }
}
