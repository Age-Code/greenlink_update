import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';

/// One action in a [ReaderSelectionToolbar].
class ReaderToolbarItem {
  const ReaderToolbarItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
}

/// Dark floating toolbar shown over selected note text (Figma 06). It is a
/// [TextSelectionToolbar], so Flutter keeps it inside the screen and moves
/// the items that do not fit on a narrow phone into an overflow page.
class ReaderSelectionToolbar extends StatelessWidget {
  const ReaderSelectionToolbar({
    super.key,
    required this.anchors,
    required this.items,
  });

  final TextSelectionToolbarAnchors anchors;
  final List<ReaderToolbarItem> items;

  @override
  Widget build(BuildContext context) => IconTheme.merge(
    data: const IconThemeData(color: Colors.white, size: 18),
    child: TextSelectionToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      toolbarBuilder:
          (context, child) => Material(
            color: AppColors.noteCode,
            elevation: 6,
            shadowColor: Colors.black38,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
      children: [for (final item in items) _ToolbarButton(item: item)],
    ),
  );
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.item});

  final ReaderToolbarItem item;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: item.onPressed,
    style: TextButton.styleFrom(
      foregroundColor: item.color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      minimumSize: const Size(0, 44),
      shape: const RoundedRectangleBorder(),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    icon: Icon(item.icon, size: 14),
    label: Text(item.label),
  );
}
