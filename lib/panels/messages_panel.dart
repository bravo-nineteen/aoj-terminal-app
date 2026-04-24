import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../services/device_identity_service.dart';
import '../services/supabase_service.dart';

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
  List<MessageRecord> _messages = [];
  bool _loading = true;
  String _error = '';
  String _deviceUsername = '';

  final TextEditingController _bodyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _globalOnly = false;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _load();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final u = await DeviceIdentityService.getUsername();
    if (mounted) setState(() => _deviceUsername = u);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final all = await SupabaseService.fetchMessages();
      if (!mounted) return;
      setState(() {
        _messages = _globalOnly
            ? all.where((m) => m.eventId == null).toList()
            : all;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
    final eventId = _globalOnly ? null : widget.activeEventId;

    _bodyController.clear();

    try {
      await SupabaseService.sendMessage(
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
              const Spacer(),
              if (widget.activeEventId != null)
                Row(
                  children: [
                    const Text('Global only', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _globalOnly,
                      activeThumbColor: accent,
                      onChanged: (v) {
                        setState(() => _globalOnly = v);
                        _load();
                      },
                    ),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
                onPressed: _load,
              ),
            ],
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
              time,
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
}
