import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';

/// Navigation entry for class menus (drawer and sidebar). Shows a hover
/// tint and a pointer cursor on mouse devices and is at least 48 tall. The
/// active entry gets the soft coral background and a coral dot unless it
/// carries its own [trailing] badge.
class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.coral : AppColors.homeInk;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.coral : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle:
          subtitle == null
              ? null
              : Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
      trailing:
          trailing ??
          (selected
              ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
              )
              : null),
      selected: selected,
      selectedColor: AppColors.coral,
      selectedTileColor: AppColors.coralSoft,
      hoverColor: AppColors.softGray,
      mouseCursor: SystemMouseCursors.click,
      minTileHeight: AppLayout.minTouchHeight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

/// Small count badge at the end of a menu entry ("12", "1건 대기").
class AppMenuBadge extends StatelessWidget {
  const AppMenuBadge(this.label, {super.key, this.accent = false});

  final String label;

  /// Sage badge for things waiting on the learner.
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: accent ? AppColors.sage : AppColors.noteHighlight,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: accent ? AppColors.homeSageDark : AppColors.homeMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
