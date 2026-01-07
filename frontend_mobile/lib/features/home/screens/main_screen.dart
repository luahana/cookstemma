import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          elevation: 0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, '홈'),
                _buildNavItem(1, Icons.restaurant, '레시피'),
                _buildCenterButton(context),
                _buildNavItem(2, Icons.book, '로그'),
                _buildNavItem(3, Icons.person, '마이'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/recipe/create'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = navigationShell.currentIndex == index;
    return InkWell(
      onTap: () => _onTap(index),
      child: Icon(
        icon,
        color: isSelected ? Colors.orange : Colors.grey,
        size: 28,
      ),
    );
  }
}
