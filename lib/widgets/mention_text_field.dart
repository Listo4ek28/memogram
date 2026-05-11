import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/linking.dart';

class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final int userId;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final InputDecoration? decoration;

  const MentionTextField({
    super.key,
    required this.controller,
    required this.userId,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.enabled = true,
    this.decoration,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  String _lastPrefix = '';
  Timer? _debounce;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    // Найти текущее слово, начинающееся с @ или ##
    final cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0) return;
    
    final beforeCursor = text.substring(0, cursorPos);
    final lastAt = beforeCursor.lastIndexOf('@');
    final lastHash = beforeCursor.lastIndexOf('##');
    final startIndex = lastAt > lastHash ? lastAt : lastHash;
    
    if (startIndex >= 0) {
      final prefix = beforeCursor.substring(startIndex);
      // Проверяем, что префикс корректен
      if (prefix.startsWith('@') || prefix.startsWith('##')) {
        if (prefix != _lastPrefix) {
          _lastPrefix = prefix;
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            _fetchSuggestions(prefix);
          });
          return;
        }
      }
    }
    _hideOverlay();
  }

  Future<void> _fetchSuggestions(String prefix) async {
    final suggestions = await MentionLinkifier.getSuggestions(prefix, widget.userId);
    if (mounted && suggestions.isNotEmpty) {
      setState(() => _suggestions = suggestions);
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -200),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade800,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  title: Text(_suggestions[i], style: const TextStyle(color: Colors.white)),
                  onTap: () => _selectSuggestion(_suggestions[i]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _selectSuggestion(String suggestion) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPos);
    final lastAt = beforeCursor.lastIndexOf('@');
    final lastHash = beforeCursor.lastIndexOf('##');
    final startIndex = lastAt > lastHash ? lastAt : lastHash;
    
    final newText = text.substring(0, startIndex) + suggestion + ' ' + text.substring(cursorPos);
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: startIndex + suggestion.length + 1),
    );
    _hideOverlay();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        onChanged: _onTextChanged,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        enabled: widget.enabled,
        decoration: widget.decoration ?? InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          filled: true,
          fillColor: Colors.grey.shade800,
        ),
      ),
    );
  }
}