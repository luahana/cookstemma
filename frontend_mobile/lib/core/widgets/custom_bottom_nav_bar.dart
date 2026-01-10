import 'package:flutter/material.dart';
import 'nav_progress_ring.dart';

/// Custom bottom navigation bar with pill-style active indicators
/// and progress ring on profile tab
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final double? levelProgress;
  final int? level;
  final bool isGuest;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    this.levelProgress,
    this.level,
    this.isGuest = false,
  });

  static const _primaryColor = Color(0xFFE67E22);
  static const _inactiveColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                semanticLabel: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.restaurant_outlined,
                activeIcon: Icons.restaurant,
                semanticLabel: 'Recipes',
              ),
              _buildFabButton(),
              _buildNavItem(
                index: 2,
                icon: Icons.book_outlined,
                activeIcon: Icons.book,
                semanticLabel: 'Logs',
              ),
              _buildProfileNavItem(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String semanticLabel,
  }) {
    final isActive = currentIndex == index;

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? _primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isActive ? activeIcon : icon,
            color: isActive ? _primaryColor : _inactiveColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFabButton() {
    return Semantics(
      label: 'Create',
      button: true,
      child: GestureDetector(
        onTap: onFabTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem() {
    final isActive = currentIndex == 3;
    final showProgress = !isGuest && levelProgress != null;

    return Semantics(
      label: 'Profile',
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: () => onTap(3),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? _primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: showProgress
              ? NavProgressRing(
                  progress: levelProgress!,
                  level: level,
                  isActive: isActive,
                  size: 40,
                  strokeWidth: 3,
                  progressColor: _primaryColor,
                  child: Icon(
                    isActive ? Icons.person : Icons.person_outline,
                    color: isActive ? _primaryColor : _inactiveColor,
                    size: 22,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isActive ? Icons.person : Icons.person_outline,
                    color: isActive ? _primaryColor : _inactiveColor,
                    size: 24,
                  ),
                ),
        ),
      ),
    );
  }
}
