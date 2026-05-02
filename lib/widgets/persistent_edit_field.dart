import 'package:flutter/material.dart';

class PersistentEditField extends StatefulWidget {
  final String label;
  final String value;
  final Future<void> Function(String) onChanged;
  final ValueChanged<bool>? onDirtyChanged;
  final int maxLines;
  final bool enabled;
  final TextInputType? keyboardType;

  const PersistentEditField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onDirtyChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  State<PersistentEditField> createState() => _PersistentEditFieldState();
}

class _PersistentEditFieldState extends State<PersistentEditField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String _lastCommittedValue = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _lastCommittedValue = widget.value;
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant PersistentEditField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_focusNode.hasFocus && widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
      _lastCommittedValue = widget.value;
      widget.onDirtyChanged?.call(false);
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitIfNeeded();
    }
  }

  Future<void> _commitIfNeeded() async {
    final currentValue = _controller.text;

    if (currentValue == _lastCommittedValue) return;
    if (_isSaving) return;

    _isSaving = true;
    try {
      await widget.onChanged(currentValue);
      _lastCommittedValue = currentValue;
      widget.onDirtyChanged?.call(false);
    } finally {
      _isSaving = false;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        textInputAction:
            widget.maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onFieldSubmitted: (_) async {
          await _commitIfNeeded();
          if (mounted) {
            _focusNode.unfocus();
          }
        },
        onTapOutside: (_) async {
          await _commitIfNeeded();
          if (mounted) {
            _focusNode.unfocus();
          }
        },
        onChanged: (_) {
          widget.onDirtyChanged?.call(_controller.text != _lastCommittedValue);
        },
      ),
    );
  }
}
