import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../services/device_identity_service.dart';
import '../services/messages_service.dart';

class MessagesPanel extends StatefulWidget {
  final Color accent;
  final String? activeEventId;

  const MessagesPanel({
    super.key,
    required this.accent,
    this.activeEventId,
  });

  @override
  State<MessagesPanel> createState() => _MessagesPanelState();
}

class _MessagesPanelState extends State<MessagesPanel> {
  List<MessageRecord> _allMessages = [];
  List<MessageRecord> _messages = [];
  bool _loading = true;
  String _error = '';
  String _deviceUsername = '';
  String _searchQuery = '';
  DateTime? _lastReadAt;
  int _unreadCount = 0;

  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  _MessageScope _scope = _MessageScope.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadUsername();
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _bodyController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final u = await DeviceIdentityService.getUsername();
    if (mounted) {
      setState(() {
        _deviceUsername = u;
        _unreadCount = _computeUnreadCount(_messages);
      });
    }
  }

  void _handleScroll() {
    if (_isNearBottom() && _unreadCount > 0) {
      _markAsRead();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final all = await MessagesService.fetchMessages();
      if (!mounted) return;
      if (_lastReadAt == null) {
        _lastReadAt = DateTime.now();
      }
      setState(() {
        _allMessages = all;
        _messages = _applyFilters(all);
        _unreadCount = _computeUnreadCount(_messages);
        _loading = false;
      });
      _scrollToBottom();
      _markAsReadIfNearBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<MessageRecord> _applyFilters(List<MessageRecord> source) {
    Iterable<MessageRecord> filtered = source;
    if (_scope == _MessageScope.globalOnly) {
      filtered = filtered.where((m) => m.eventId == null);
    } else if (_scope == _MessageScope.activeEventOnly) {
      final activeId = widget.activeEventId;
      filtered = filtered.where((m) => m.eventId == activeId);
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((m) {
        final sender = m.sender.toLowerCase();
        final body = m.body.toLowerCase();
        return sender.contains(q) || body.contains(q);
      });
    }
    return filtered.toList();
  }

  int _computeUnreadCount(List<MessageRecord> rows) {
    final lastRead = _lastReadAt;
    if (lastRead == null) return 0;
    var count = 0;
    for (final m in rows) {
      final isMine = _deviceUsername.isNotEmpty && m.sender == _deviceUsername;
      if (isMine) continue;
      DateTime? created;
      try {
        created = DateTime.parse(m.createdAt).toLocal();
      } catch (_) {
        created = null;
      }
      if (created != null && created.isAfter(lastRead)) {
        count++;
      }
    }
    return count;
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) < 80;
  }

  void _markAsRead() {
    setState(() {
      _lastReadAt = DateTime.now();
      _unreadCount = 0;
    });
  }

  void _markAsReadIfNearBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isNearBottom()) {
        _markAsRead();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;

    final sender = _deviceUsername.isEmpty ? 'Anonymous' : _deviceUsername;
    final eventId =
      _scope == _MessageScope.globalOnly ? null : widget.activeEventId;

    _bodyController.clear();

    try {
      await MessagesService.sendMessage(
        sender: sender,
        body: body,
        eventId: eventId,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'MESSAGES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              if (_unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$_unreadCount new',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: _markAsRead,
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Mark read'),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _scope == _MessageScope.all,
                onSelected: (_) {
                  setState(() {
                    _scope = _MessageScope.all;
                    _messages = _applyFilters(_allMessages);
                    _unreadCount = _computeUnreadCount(_messages);
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Global'),
                selected: _scope == _MessageScope.globalOnly,
                onSelected: (_) {
                  setState(() {
                    _scope = _MessageScope.globalOnly;
                    _messages = _applyFilters(_allMessages);
                    _unreadCount = _computeUnreadCount(_messages);
                  });
                },
              ),
              if (widget.activeEventId != null)
                ChoiceChip(
                  label: const Text('Active Event'),
                  selected: _scope == _MessageScope.activeEventOnly,
                  onSelected: (_) {
                    setState(() {
                      _scope = _MessageScope.activeEventOnly;
                      _messages = _applyFilters(_allMessages);
                      _unreadCount = _computeUnreadCount(_messages);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: 'Search sender or message',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _messages = _applyFilters(_allMessages);
                _unreadCount = _computeUnreadCount(_messages);
              });
            },
          ),
          const Divider(height: 8),
          // Sender identity hint
          if (_deviceUsername.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Set your device username in System → Settings to show your name.',
                style: TextStyle(
                  fontSize: 11,
                  color: accent.withAlpha(180),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          // Message list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text('Error: $_error'))
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              'No messages yet.',
                              style: TextStyle(color: accent.withAlpha(140)),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final m = _messages[i];
                              final isMine = m.sender == _deviceUsername &&
                                  _deviceUsername.isNotEmpty;
                              return _MessageBubble(
                                message: m,
                                isMine: isMine,
                                accent: accent,
                              );
                            },
                          ),
          ),
          const SizedBox(height: 8),
          // Compose row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _send,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
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

class _MessageBubble extends StatelessWidget {
  final MessageRecord message;
  final bool isMine;
  final Color accent;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(message.createdAt);
    final relative = _formatRelativeTime(message.createdAt);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? accent.withAlpha(200)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.sender.isEmpty ? 'Anonymous' : message.sender,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isMine ? Colors.white70 : accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.body,
              style: TextStyle(
                color: isMine ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              relative.isEmpty ? time : '$time - $relative',
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white54 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final date = DateTime(dt.year, dt.month, dt.day);
      final today = DateTime(now.year, now.month, now.day);
      final prefix = date == today
          ? ''
          : '${dt.day}/${dt.month} ';
      return '$prefix${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _formatRelativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w ago';
    } catch (_) {
      return '';
    }
  }
}

enum _MessageScope {
  all,
  globalOnly,
  activeEventOnly,
}
