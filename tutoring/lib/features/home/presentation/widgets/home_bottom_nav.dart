import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';

enum HomeTab { home, my }

/// 홈 · 마이 tabs shared by the home and 마이 screens; shown below desktop
/// only (desktop reaches 마이 through the avatar menu).
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.selected});

  final HomeTab selected;

  static const _assetRoot = 'assets/images/home';

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.homeDivider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  asset: '$_assetRoot/home.svg',
                  label: '홈',
                  selected: selected == HomeTab.home,
                  onTap:
                      selected == HomeTab.home
                          ? null
                          : () => context.go(AppRoutes.home),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  asset: '$_assetRoot/my.svg',
                  label: '마이',
                  selected: selected == HomeTab.my,
                  onTap:
                      selected == HomeTab.my
                          ? null
                          : () => context.go(AppRoutes.my),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.homeBrown : AppColors.homeMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            asset,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}
