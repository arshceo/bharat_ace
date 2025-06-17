import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyNotesSelectionControls extends MaterialTextSelectionControls {
  final Function(String) onAddToKeyNotes;

  KeyNotesSelectionControls({required this.onAddToKeyNotes});

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? clipboardStatusOffset,
  ) {
    final List<Widget Function(BuildContext, int, int)> buttonBuilders = [];
    final TextEditingValue value = delegate.textEditingValue;

    final bool isSelectionValid =
        value.selection.isValid && !value.selection.isCollapsed;

    // Check if Copy should be available
    if (isSelectionValid) {
      buttonBuilders.add((ctx, index, total) => TextSelectionToolbarTextButton(
            padding: TextSelectionToolbarTextButton.getPadding(index, total),
            onPressed: () => handleCopy(delegate),
            child: const Text('Copy'),
          ));
    }

    // Check if Select All should be available
    final bool canSelectAll = value.text.isNotEmpty &&
        !(value.selection.start == 0 &&
            value.selection.end == value.text.length);
    if (canSelectAll) {
      buttonBuilders.add((ctx, index, total) => TextSelectionToolbarTextButton(
            padding: TextSelectionToolbarTextButton.getPadding(index, total),
            onPressed: () => handleSelectAll(delegate),
            child: const Text('Select All'),
          ));
    }

    // Add custom "Add to Key Notes" button
    final String selectedText = value.selection.textInside(value.text);
    if (selectedText.isNotEmpty) {
      buttonBuilders.add((ctx, index, total) => TextSelectionToolbarTextButton(
            padding: TextSelectionToolbarTextButton.getPadding(index, total),
            onPressed: () {
              onAddToKeyNotes(selectedText);
              delegate.hideToolbar(); // Hide toolbar after action
            },
            child: const Text('Add to Key Notes'),
          ));
    }

    if (buttonBuilders.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build the actual list of Widgets
    final List<Widget> items = [];
    for (int i = 0; i < buttonBuilders.length; i++) {
      items.add(buttonBuilders[i](context, i, buttonBuilders.length));
    }

    return TextSelectionToolbar(
      anchorAbove: endpoints.first.point,
      anchorBelow: endpoints.last.point + Offset(0.0, textLineHeight),
      toolbarBuilder: (context, child) => Material(
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        elevation: 4.0,
        color: Theme.of(context).colorScheme.surface,
        child: child,
      ),
      children: items,
    );
  }
}
