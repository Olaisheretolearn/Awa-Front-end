import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../navigation/room_required_route.dart';
import '../state/app_flow_state.dart';
import 'bill_screen.dart';
import 'chat_screen.dart';
import 'shopping_list_screen.dart';
import 'task_screen.dart';

class SharedBottomNav extends StatelessWidget {
  const SharedBottomNav({
    super.key,
    required this.currentIndex,
    required this.roomSession,
  });

  final int currentIndex;
  final RoomSession roomSession;

  void _navigateToScreen(BuildContext context, int index) {
    if (index == currentIndex) return;

    final navigator = Navigator.of(context);
    if (index == 0) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    final route = RoomRequiredRoute.build<void>((_, latestSession) {
      switch (index) {
        case 1:
          return ShoppingListPage(roomSession: latestSession);
        case 2:
          return BillsScreen(roomSession: latestSession);
        case 3:
          return ChatScreen(roomSession: latestSession);
        case 4:
          return TasksScreen(roomSession: latestSession);
        default:
          return const SizedBox.shrink();
      }
    });

    // Keep the app-flow gate as the first route and replace only feature pages.
    navigator.pushAndRemoveUntil(route, (existing) => existing.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, Icons.home, 'Home', 0),
            _buildNavItem(context, Icons.shopping_bag, 'Shopping', 1),
            _buildNavItem(context, Icons.attach_money, 'Bills', 2),
            _buildNavItem(context, Icons.chat_bubble_outline, 'Chat', 3),
            _buildNavItem(context, Icons.check_circle_outline, 'Tasks', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => _navigateToScreen(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.white : const Color(0xFF666666),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? AppColors.primaryBlue : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}
