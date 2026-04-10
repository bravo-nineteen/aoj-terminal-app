import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../panels/accounting_panel.dart';
import '../panels/booking_editor_panel.dart';
import '../panels/bookings_panel.dart';
import '../panels/event_panel.dart';
import '../panels/game_modes_panel.dart';
import '../panels/members_panel.dart';
import '../panels/props_panel.dart';
import '../panels/schedule_panel.dart';
import '../panels/system_panel.dart';
import '../services/app_state_service.dart';
import '../services/csv_import_service.dart';
import '../services/export_service.dart';
import '../utils/booking_utils.dart';
import '../widgets/desktop_widgets.dart';

class AOJDesktop extends StatefulWidget {
  const AOJDesktop({super.key});

  @override
  State<AOJDesktop> createState() => _AOJDesktopState();
}

class _AOJDesktopState extends State<AOJDesktop> {
  static const double _windowMinWidth = 520;
  static const double _windowMinHeight = 340;
  static const double _tabBarHeight = 44;
  static const double _desktopPadding = 8;

  final List<DesktopAppItem> apps = const [
    DesktopAppItem(
      id: 'system',
      title: 'My System',
      icon: Icons.shield_outlined,
      accent: Color(0xFF7E8B63),
      subtitle: 'Command node',
    ),
    DesktopAppItem(
      id: 'accounts',
      title: 'Account Management',
      icon: Icons.account_balance_wallet_outlined,
      accent: Color(0xFF6F8A5E),
      subtitle: 'Finance and deductions',
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
    if (selectedMemberIndex! < 0 ||
        selectedMemberIndex! >= event.members.length) {
      return null;
    }
    return event.members[selectedMemberIndex!];
  }

  Rect _desktopRect(BuildContext context, Size size) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final width = math.max(0, size.width - (_desktopPadding * 2));
    final height = math.max(
      0,
      size.height - _tabBarHeight - bottomInset - (_desktopPadding * 2),
    );
    return Rect.fromLTWH(
      _desktopPadding,
      _desktopPadding,
      width,
      height,
    );
  }

  Offset _clampPosition(Offset position, Size windowSize, Rect desktopRect) {
    final maxX = desktopRect.right - windowSize.width;
    final maxY = desktopRect.bottom - windowSize.height;
    return Offset(
      position.dx.clamp(desktopRect.left, maxX),
      position.dy.clamp(desktopRect.top, maxY),
    );
  }

  void _maximizeWindowToRect(DesktopWindowData window, Rect desktopRect) {
    if (!window.isMaximized) {
      window.restorePosition = window.position;
      window.restoreSize = window.size;
    }
    window.position = desktopRect.topLeft;
    window.size = desktopRect.size;
    window.isMaximized = true;
  }

  void _snapWindowLeft(DesktopWindowData window, Rect desktopRect) {
    if (!window.isMaximized) {
      window.restorePosition = window.position;
      window.restoreSize = window.size;
    }
    final halfWidth = desktopRect.width / 2;
    window.position = desktopRect.topLeft;
    window.size = Size(halfWidth - 4, desktopRect.height);
    window.isMaximized = false;
  }

  void _snapWindowRight(DesktopWindowData window, Rect desktopRect) {
    if (!window.isMaximized) {
      window.restorePosition = window.position;
      window.restoreSize = window.size;
    }
    final halfWidth = desktopRect.width / 2;
    window.position = Offset(desktopRect.left + halfWidth + 4, desktopRect.top);
    window.size = Size(halfWidth - 4, desktopRect.height);
    window.isMaximized = false;
  }

  void _applyEdgeSnap(DesktopWindowData window, Rect desktopRect) {
    final leftEdge = window.position.dx;
    final rightEdge = window.position.dx + window.size.width;
    final topEdge = window.position.dy;

    if (topEdge <= desktopRect.top + 16) {
      _maximizeWindowToRect(window, desktopRect);
      return;
    }

    if (leftEdge <= desktopRect.left + 16) {
      _snapWindowLeft(window, desktopRect);
      return;
    }

    if (rightEdge >= desktopRect.right - 16) {
      _snapWindowRight(window, desktopRect);
      return;
    }

    window.position = _clampPosition(window.position, window.size, desktopRect);
  }

  Future<void> _loadLocalState() async {
    try {
      final loaded = await AppStateService.load();
      if (loaded == null) return;
      setState(() {
        appState = loaded;
        selectedBookingIndex = 0;
        selectedMemberIndex = activeEvent?.members.isNotEmpty == true ? 0 : null;
        systemStatus = 'LOCAL DATA LOADED';
      });
    } catch (_) {
      setState(() {
        systemStatus = 'LOAD FAILED';
      });
    }
  }

  Future<void> _saveLocalState() async {
    await AppStateService.save(appState);
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

  void _toggleMaximize(String id, Rect desktopRect) {
    setState(() {
      final window = windows[id]!;
      if (!window.isMaximized) {
        _maximizeWindowToRect(window, desktopRect);
      } else {
        window.position =
            _clampPosition(window.restorePosition, window.restoreSize, desktopRect);
        window.size = Size(
          math.max(_windowMinWidth, window.restoreSize.width),
          math.max(_windowMinHeight, window.restoreSize.height),
        );
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

  Future<void> _createEvent(String name) async {
    if (name.trim().isEmpty) return;

    final event = EventRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      venue: '',
      date: '',
      time: '',
      notes: '',
      ticketCostPerPerson: '0',
      trainingTrainer: '',
      fieldMapBase64: null,
      bookings: [],
      tickets: [],
      members: [],
      schedule: [],
      gameModes: [],
      expenses: [],
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

  Future<void> _importWorkbookXlsx() async {
    final event = activeEvent;
    if (event == null) return;

    final result = await CsvImportService.importWorkbookXlsx(event);
    if (!result.success) {
      setState(() {
        systemStatus = 'WORKBOOK IMPORT FAILED';
      });
      return;
    }

    setState(() {
      selectedBookingIndex = event.bookings.isNotEmpty ? 0 : null;
      selectedMemberIndex = event.members.isNotEmpty ? 0 : null;
      systemStatus =
          'WORKBOOK IMPORTED: ${result.totalImported} ITEMS / ${result.importedSheets.join(", ")}';
    });

    await _saveLocalState();
  }

  Future<void> _importBookingsCsv() async {
    final event = activeEvent;
    if (event == null) return;
    final ok = await CsvImportService.importBookingsCsv(event);
    if (!ok) return;
    setState(() {
      selectedBookingIndex = 0;
      systemStatus = 'BOOKINGS IMPORTED';
    });
    await _saveLocalState();
  }

  Future<void> _importTicketsCsv() async {
    final event = activeEvent;
    if (event == null) return;
    final ok = await CsvImportService.importTicketsCsv(event);
    if (!ok) return;
    setState(() {
      systemStatus = 'TICKETS IMPORTED';
    });
    await _saveLocalState();
  }

  Future<void> _importMembersCsv() async {
    final event = activeEvent;
    if (event == null) return;
    final ok = await CsvImportService.importMembersCsv(event);
    if (!ok) return;
    setState(() {
      selectedMemberIndex = event.members.isNotEmpty ? 0 : null;
      systemStatus = 'MEMBERS IMPORTED';
    });
    await _saveLocalState();
  }

  Future<void> _importScheduleCsv() async {
    final event = activeEvent;
    if (event == null) return;
    final ok = await CsvImportService.importScheduleCsv(event);
    if (!ok) return;
    setState(() {
      systemStatus = 'SCHEDULE IMPORTED';
    });
    await _saveLocalState();
  }

  Future<void> _importGameModesCsv() async {
    final event = activeEvent;
    if (event == null) return;
    final ok = await CsvImportService.importGameModesCsv(event);
    if (!ok) return;
    setState(() {
      systemStatus = 'GAME MODES IMPORTED';
    });
    await _saveLocalState();
  }

  Future<void> _importFieldMap() async {
    final event = activeEvent;
    if (event == null) return;
    final ok = await CsvImportService.importFieldMap(event);
    if (!ok) return;
    setState(() {
      systemStatus = 'FIELD MAP IMPORTED';
    });
    await _saveLocalState();
  }

  Future<void> _exportActiveEventJson() async {
    final event = activeEvent;
    if (event == null) return;
    final status = await ExportService.exportActiveEventJson(event);
    setState(() {
      exportStatus = status;
    });
  }

  Future<void> _exportActiveEventFullCsv() async {
    final event = activeEvent;
    if (event == null) return;
    final status = await ExportService.exportActiveEventFullCsv(event);
    setState(() {
      exportStatus = status;
      systemStatus = status;
    });
  }

  Future<void> _exportBookingsCsv() async {
    final event = activeEvent;
    if (event == null) return;
    final status = await ExportService.exportBookingsCsv(event);
    setState(() {
      exportStatus = status;
    });
  }

  Future<void> _showAddExpenseDialog() async {
    final event = activeEvent;
    if (event == null) return;

    final itemController = TextEditingController();
    final amountController = TextEditingController(text: '0');
    final noteController = TextEditingController();
    final categoryController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemController,
                decoration: const InputDecoration(labelText: 'Item'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
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

    if (result != true) return;

    setState(() {
      event.expenses.add(
        ExpenseRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          item: itemController.text.trim(),
          amount: amountController.text.trim().isEmpty
              ? '0'
              : amountController.text.trim(),
          note: noteController.text.trim(),
          date: DateTime.now().toIso8601String(),
          category: categoryController.text.trim(),
        ),
      );
      systemStatus = 'EXPENSE ADDED';
    });

    await _saveLocalState();
  }

  Future<void> _deleteExpenseFromActiveEvent(String expenseId) async {
    final event = activeEvent;
    if (event == null) return;

    setState(() {
      event.expenses.removeWhere((e) => e.id == expenseId);
      systemStatus = 'EXPENSE DELETED';
    });

    await _saveLocalState();
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
          username: '',
          dateOfBirth: '',
          gender: '',
          telephone: '',
          email: '',
          membershipLevel: 'Regular',
          rating: 0,
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
        ticketName: nameController.text.trim().isEmpty
            ? 'New Ticket'
            : nameController.text.trim(),
        price: priceController.text.trim().isEmpty
            ? '0'
            : priceController.text.trim(),
        spaces: '1',
        status: 'Active',
      );

      setState(() {
        event.tickets.add(ticket);
        BookingUtils.linkTicketsToBookings(event);
        BookingUtils.recalculateAllTotals(event);
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
          amount: amountController.text.trim().isEmpty
              ? '0'
              : amountController.text.trim(),
          method: method,
          note: noteController.text.trim(),
          date: DateTime.now().toIso8601String(),
        ),
      );
      await _saveGroupedBooking(group);
      final event = activeEvent;
      if (event != null) {
        BookingUtils.recalculateAllTotals(event);
        await _saveLocalState();
      }
      setState(() {
        systemStatus = 'PAYMENT ADDED';
      });
    }
  }

  Future<void> _deletePaymentFromGroup(
    BookingGroup group,
    String paymentId,
  ) async {
    group.primary.payments.removeWhere((p) => p.id == paymentId);
    await _saveGroupedBooking(group);
    final event = activeEvent;
    if (event != null) {
      BookingUtils.recalculateAllTotals(event);
      await _saveLocalState();
    }
    setState(() {
      systemStatus = 'PAYMENT DELETED';
    });
  }

  Future<void> _showAddSaleDialog(BookingGroup group) async {
    final productController = TextEditingController();
    final priceController = TextEditingController(text: '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Sale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productController,
                decoration: const InputDecoration(labelText: 'Product'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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

    if (result != true) return;

    group.primary.sales.add(
      SaleRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        product: productController.text.trim(),
        price: priceController.text.trim().isEmpty
            ? '0'
            : priceController.text.trim(),
      ),
    );

    await _saveGroupedBooking(group);
    final event = activeEvent;
    if (event != null) {
      BookingUtils.recalculateAllTotals(event);
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
      BookingUtils.recalculateAllTotals(event);
      await _saveLocalState();
    }
    setState(() {
      systemStatus = 'SALE DELETED';
    });
  }

  List<BookingGroup> _groupedBookingsForActiveEvent() {
    final event = activeEvent;
    if (event == null) return [];
    final groups = BookingUtils.groupedBookingsForEvent(event);

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

  BookingGroup? _findBookingGroupByPrimaryId(String primaryId) {
    final event = activeEvent;
    if (event == null) return null;

    final groups = BookingUtils.groupedBookingsForEvent(event);
    for (final group in groups) {
      if (group.primary.id == primaryId) return group;
    }
    return null;
  }

  String _membershipLevelForGroup(EventRecord? event, BookingGroup group) {
    if (event == null) return '';

    for (final member in event.members) {
      final memberEmail = member.email.trim().toLowerCase();
      final memberPhone = member.telephone.trim().toLowerCase();
      final memberName = member.fullName.trim().toLowerCase();

      final groupEmail = group.email.trim().toLowerCase();
      final groupPhone = group.phone.trim().toLowerCase();
      final groupName = group.displayName.trim().toLowerCase();

      final emailMatch =
          memberEmail.isNotEmpty &&
          groupEmail.isNotEmpty &&
          memberEmail == groupEmail;

      final phoneMatch =
          memberPhone.isNotEmpty &&
          groupPhone.isNotEmpty &&
          memberPhone == groupPhone;

      final nameMatch =
          memberName.isNotEmpty &&
          groupName.isNotEmpty &&
          memberName == groupName;

      if (emailMatch || phoneMatch || nameMatch) {
        return member.membershipLevel;
      }
    }

    return '';
  }

  Future<void> _quickSetCheckInStatus(
    BookingGroup group,
    String status,
  ) async {
    group.primary.checkInStatus = status;
    await _saveGroupedBooking(group);
    setState(() {
      systemStatus = 'CHECK-IN STATUS UPDATED';
    });
  }

  Future<void> _openBookingEditorWindow(BookingGroup group) async {
    final windowId = 'booking_editor::${group.primary.id}';

    if (!windows.containsKey(windowId)) {
      windows[windowId] = DesktopWindowData(
        id: windowId,
        title: 'Booking - ${group.displayName}',
        icon: Icons.assignment_ind_outlined,
        accent: const Color(0xFF8C6A52),
        isOpen: true,
        isMinimized: false,
        isMaximized: true,
        position: const Offset(8, 8),
        size: const Size(1180, 760),
        restorePosition: const Offset(220, 110),
        restoreSize: const Size(1180, 760),
        zIndex: nextZ++,
      );
    }

    setState(() {
      final window = windows[windowId]!;
      window.title = 'Booking - ${group.displayName}';
      window.isOpen = true;
      window.isMinimized = false;
      window.isMaximized = true;
      window.zIndex = nextZ++;
    });
  }

  Future<void> _openTicketEditorWindow(BookingGroup group) async {
    await _showTicketManagementDialog(group);
  }

  Future<void> _showTicketManagementDialog(BookingGroup group) async {
    final event = activeEvent;
    if (event == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              return Container(
                width: 760,
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ticket Editor - ${group.displayName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            BookingUtils.recalculateAllTotals(event);
                            await _saveLocalState();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: const Text('SAVE'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ...group.tickets.map((ticket) {
                            final nameController =
                                TextEditingController(text: ticket.ticketName);
                            final qtyController = TextEditingController(
                              text: ticket.quantity.toString(),
                            );
                            final priceController =
                                TextEditingController(text: ticket.price);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ticket Name',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) {
                                      ticket.ticketName = v;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: qtyController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Quantity',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (v) {
                                            ticket.spaces =
                                                v.trim().isEmpty ? '1' : v.trim();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: priceController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'Price',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (v) {
                                            ticket.price = v;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          event.tickets.removeWhere(
                                            (t) => t.id == ticket.id,
                                          );
                                          BookingUtils.linkTicketsToBookings(event);
                                          BookingUtils.recalculateAllTotals(event);
                                          setLocal(() {});
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _showAddTicketDialog(group);
                              setLocal(() {});
                              setState(() {});
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('ADD NEW TICKET'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<GameModeRecord> _filteredGameModes() {
    final event = activeEvent;
    if (event == null) return [];
    if (gameModeSearch.trim().isEmpty) return event.gameModes;

    final q = gameModeSearch.trim().toLowerCase();
    return event.gameModes
        .where((g) => g.data.values.join(' ').toLowerCase().contains(q))
        .toList();
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
          .map(
            (p) => PaymentRecord(
              id: p.id,
              amount: p.amount,
              method: p.method,
              note: p.note,
              date: p.date,
            ),
          )
          .toList();
    }

    await _saveLocalState();
  }

  Future<void> _toggleCheckInForGroup(BookingGroup group) async {
    final current = group.primary.checkInStatus.trim();
    group.primary.checkInStatus =
        current == 'Checked In' ? 'Not Checked In' : 'Checked In';
    await _saveGroupedBooking(group);
    setState(() {
      systemStatus = group.primary.checkInStatus == 'Checked In'
          ? 'CHECKED IN'
          : 'CHECK-IN CLEARED';
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
          content: Text(
            'Delete ${event.name}? This removes bookings, tickets, members, schedule and game modes for this event.',
          ),
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
      appState.activeEventId =
          appState.events.isNotEmpty ? appState.events.first.id : null;
      selectedBookingIndex = 0;
      selectedMemberIndex = activeEvent?.members.isNotEmpty == true ? 0 : null;
      systemStatus = 'EVENT DELETED';
    });

    await _saveLocalState();
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

  @override
  Widget build(BuildContext context) {
    final visibleWindows =
        windows.values.where((w) => w.isOpen && !w.isMinimized).toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    final openTabs = windows.values.where((w) => w.isOpen).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktopSize = Size(constraints.maxWidth, constraints.maxHeight);
          final desktopRect = _desktopRect(context, desktopSize);

          for (final window in windows.values) {
            if (window.isOpen && !window.isMinimized) {
              if (window.isMaximized) {
                window.position = desktopRect.topLeft;
                window.size = desktopRect.size;
              } else {
                window.position =
                    _clampPosition(window.position, window.size, desktopRect);
              }
            }
          }

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
                      ...visibleWindows.map(
                        (w) => _buildWindow(w, desktopRect),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom,
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
          padding:
              EdgeInsets.only(right: columnIndex == columnCount - 1 ? 0 : 18),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0x66161F18)
                            : const Color(0x33101812),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? app.accent.withOpacity(0.75)
                              : Colors.white.withOpacity(0.08),
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

  Widget _buildWindow(DesktopWindowData window, Rect desktopRect) {
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
              window.position = _clampPosition(
                Offset(
                  window.position.dx + details.delta.dx,
                  window.position.dy + details.delta.dy,
                ),
                window.size,
                desktopRect,
              );
            });
          }
        },
        onPanEnd: (_) {
          if (!window.isMaximized) {
            setState(() {
              _applyEdgeSnap(window, desktopRect);
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: window.accent.withOpacity(0.65),
              width: 1.3,
            ),
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
                    _buildWindowTitleBar(window, desktopRect),
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
                        final newWidth = math.max(
                          _windowMinWidth,
                          window.size.width + details.delta.dx,
                        );
                        final newHeight = math.max(
                          _windowMinHeight,
                          window.size.height + details.delta.dy,
                        );

                        window.size = Size(newWidth, newHeight);
                        window.position = _clampPosition(
                          window.position,
                          window.size,
                          desktopRect,
                        );
                        window.restoreSize = window.size;
                      });
                    },
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: window.accent.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: window.accent.withOpacity(0.7),
                        ),
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

  Widget _buildWindowTitleBar(DesktopWindowData window, Rect desktopRect) {
    return GestureDetector(
      onDoubleTap: () => _toggleMaximize(window.id, desktopRect),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [window.accent.withOpacity(0.35), const Color(0xFF162019)],
          ),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        child: Row(
          children: [
            Icon(window.icon, size: 17, color: window.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                window.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
            ),
            WindowButton(
              icon: Icons.vertical_align_top,
              color: const Color(0xFF6D7F96),
              onPressed: () {
                setState(() {
                  final win = windows[window.id]!;
                  _snapWindowLeft(win, desktopRect);
                  win.zIndex = nextZ++;
                });
              },
            ),
            const SizedBox(width: 6),
            WindowButton(
              icon: Icons.vertical_align_bottom,
              color: const Color(0xFF6D7F96),
              onPressed: () {
                setState(() {
                  final win = windows[window.id]!;
                  _snapWindowRight(win, desktopRect);
                  win.zIndex = nextZ++;
                });
              },
            ),
            const SizedBox(width: 6),
            WindowButton(
              icon: window.isMaximized ? Icons.filter_none : Icons.crop_square,
              color: const Color(0xFF7E8B63),
              onPressed: () => _toggleMaximize(window.id, desktopRect),
            ),
            const SizedBox(width: 6),
            WindowButton(
              icon: Icons.remove,
              color: const Color(0xFFB7A36B),
              onPressed: () => _toggleMinimize(window.id),
            ),
            const SizedBox(width: 6),
            WindowButton(
              icon: Icons.close,
              color: const Color(0xFF9A5A52),
              onPressed: () => _closeWindow(window.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowBody(DesktopWindowData window) {
    if (window.id.startsWith('booking_editor::')) {
      final primaryId = window.id.replaceFirst('booking_editor::', '');
      final event = activeEvent;
      final group = _findBookingGroupByPrimaryId(primaryId);

      if (event == null || group == null) {
        return const Center(
          child: Text('BOOKING NO LONGER AVAILABLE'),
        );
      }

      return BookingEditorPanel(
        accent: window.accent,
        event: event,
        group: group,
        membershipLevel: _membershipLevelForGroup(event, group),
        paymentStatuses: paymentStatuses,
        checkInStatuses: checkInStatuses,
        onToggleCheckIn: _toggleCheckInForGroup,
        onEditContact: _showEditContactDialog,
        onDeleteGroup: _deleteBookingGroup,
        onAddTicket: _showAddTicketDialog,
        onAddPayment: _showAddPaymentDialog,
        onDeletePayment: _deletePaymentFromGroup,
        onAddSale: _showAddSaleDialog,
        onDeleteSale: _deleteSaleFromGroup,
        onSaveGroup: _saveGroupedBooking,
        onSave: _saveLocalState,
        onRefresh: () => setState(() {}),
        onOpenTicketEditor: _openTicketEditorWindow,
      );
    }

    switch (window.id) {
      case 'system':
        return SystemPanel(
          accent: window.accent,
          appState: appState,
          activeEvent: activeEvent,
          systemStatus: systemStatus,
          exportStatus: exportStatus,
          onCreateEvent: _createEvent,
          onExportEvent: _exportActiveEventJson,
          onExportBookings: _exportBookingsCsv,
          onImportWorkbook: _importWorkbookXlsx,
          onImportBookings: _importBookingsCsv,
          onImportTickets: _importTicketsCsv,
          onImportMembers: _importMembersCsv,
          onImportSchedule: _importScheduleCsv,
          onImportGameModes: _importGameModesCsv,
          onImportFieldMap: _importFieldMap,
        );
      case 'event':
        return EventPanel(
          accent: window.accent,
          appState: appState,
          event: activeEvent,
          onSetActiveEvent: _setActiveEvent,
          onDeleteEvent: _deleteActiveEvent,
          onSave: _saveLocalState,
          onRefresh: () => setState(() {}),
        );
      case 'bookings':
        return BookingsPanel(
          accent: window.accent,
          appState: appState,
          event: activeEvent,
          groups: _groupedBookingsForActiveEvent(),
          selectedBookingIndex: selectedBookingIndex,
          checkInStatuses: checkInStatuses,
          onSetActiveEvent: (value) async {
            await _setActiveEvent(value);
            setState(() {
              selectedBookingIndex = 0;
            });
          },
          onSearchChanged: (v) {
            setState(() {
              bookingSearch = v;
              selectedBookingIndex = 0;
            });
          },
          onSelectBooking: (index) {
            setState(() {
              selectedBookingIndex = index;
            });
          },
          onQuickSetCheckInStatus: _quickSetCheckInStatus,
          onOpenBookingEditor: _openBookingEditorWindow,
        );
      case 'accounts':
        return AccountingPanel(
          accent: window.accent,
          event: activeEvent,
          onExportFullCsv: _exportActiveEventFullCsv,
          onAddExpense: _showAddExpenseDialog,
          onDeleteExpense: _deleteExpenseFromActiveEvent,
        );
      case 'members':
        return MembersPanel(
          accent: window.accent,
          event: activeEvent,
          selectedMember: selectedMember,
          selectedMemberIndex: selectedMemberIndex,
          membershipLevels: membershipLevels,
          onAddMember: _addManualMember,
          onDeleteMember: _deleteSelectedMember,
          onSelectMember: (index) {
            setState(() {
              selectedMemberIndex = index;
            });
          },
          onSave: _saveLocalState,
          onRefresh: () => setState(() {}),
        );
      case 'schedule':
        return SchedulePanel(
          accent: window.accent,
          event: activeEvent,
        );
      case 'props':
        return PropsPanel(
          accent: window.accent,
          event: activeEvent,
          propIpController: propIpController,
          showPropControlPage: showPropControlPage,
          propControlStatus: propControlStatus,
          onOpenPropControlPage: _openPropControlPage,
          onClosePropControlPage: _closePropControlPage,
          normalizedPropUrl: _normalizedPropUrl,
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
        );
      case 'game_modes':
        return GameModesPanel(
          accent: window.accent,
          event: activeEvent,
          modes: _filteredGameModes(),
          onSearchChanged: (v) {
            setState(() {
              gameModeSearch = v;
            });
          },
          onImportGameModes: _importGameModesCsv,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOpenTabsBar(List<DesktopWindowData> openTabs) {
    return Container(
      height: _tabBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC0C120D),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF121813),
              border: Border.all(color: const Color(0x337E8B63)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: Color(0xFF7E8B63),
                ),
                const SizedBox(width: 6),
                Text(
                  activeEvent?.name ?? 'NO ACTIVE EVENT',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: openTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final tab = openTabs[index];
                final active = !tab.isMinimized;
                return GestureDetector(
                  onTap: () => _toggleFromTab(tab.id),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: active
                          ? tab.accent.withOpacity(0.20)
                          : const Color(0xFF121813),
                      border: Border.all(
                        color: active
                            ? tab.accent.withOpacity(0.85)
                            : Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(tab.icon, size: 14, color: tab.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tab.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
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
}
