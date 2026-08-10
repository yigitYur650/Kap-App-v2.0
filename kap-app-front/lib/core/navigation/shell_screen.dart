import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

class ShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _previousIndex = 0;

  void _onTabSelect(int index) {
    if (index != widget.navigationShell.currentIndex) {
      setState(() {
        _previousIndex = widget.navigationShell.currentIndex;
      });
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final current = widget.navigationShell.currentIndex;
    if (velocity < -250 && current < 3) {
      // Swiped Left -> Go to next tab
      _onTabSelect(current + 1);
    } else if (velocity > 250 && current > 0) {
      // Swiped Right -> Go to previous tab
      _onTabSelect(current - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final localizations = AppLocalizations.of(context)!;
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Content area with swipe gesture support
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: _handleSwipe,
              behavior: HitTestBehavior.translucent,
              child: widget.navigationShell,
            ),
          ),
          
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 12,
                    bottom: bottomPadding > 0 ? bottomPadding : 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0E0F).withOpacity(0.9),
                    border: const Border(
                      top: BorderSide(
                        color: Color(0xFF242424),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          index: 0,
                          icon: Icons.grid_view,
                          label: localizations.nav_tab_hub,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 1,
                          icon: Icons.shopping_cart,
                          label: localizations.nav_tab_list,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 2,
                          icon: Icons.fitness_center,
                          label: 'Kişisel',
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 3,
                          icon: Icons.settings,
                          label: localizations.nav_tab_settings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    return Builder(
      builder: (context) {
        final isActive = widget.navigationShell.currentIndex == index;
        final color = isActive ? AppColors.primary : AppColors.secondary.withOpacity(0.5);

        return GestureDetector(
          onTap: () => _onTabSelect(index),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.labelSm.copyWith(
                    color: color,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                // Glowing active dot indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 4 : 0,
                  height: isActive ? 4 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
