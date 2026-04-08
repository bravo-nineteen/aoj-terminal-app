
import 'package:flutter/material.dart';

class PersistentEditField extends StatefulWidget {
  final String label;
  final String value;
  final Future<void> Function(String) onChanged;
  final int maxLines;

  const PersistentEditField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<PersistentEditField> createState() => _PersistentEditFieldState();
}

class _PersistentEditFieldState extends State<PersistentEditField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant PersistentEditField oldWidget) {
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
