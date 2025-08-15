// shared_bottom_nav.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'home_screen.dart';
import 'shopping_list_screen.dart';
import 'bill_screen.dart';
import 'chat_screen.dart';
import 'task_screen.dart';
import '../api/client.dart';
import '../api/room_api.dart';
import '../api/auth_api.dart';
import '../api/tasks_api.dart';



class SharedBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool shouldPop;

  final String? roomId;
  final String? userId;

  const SharedBottomNav({
       Key? key,
    required this.currentIndex,
    this.shouldPop = true,
    this.roomId,
    this.userId,
  }) : super(key: key);

  void _navigateToScreen(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget screen;
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = ShoppingListPage();
        break;
      case 2:
        screen = const BillsScreen();
        break;
      case 3:
        screen = const ChatScreen();
        break;
      case 4: 
        if (roomId != null && userId != null) {
          screen = TasksScreen(roomId: roomId!, userId: userId!);
        } else {
        
          screen = const _TasksGate();
        }
        break;
      default:
        return;
    }

 final route = MaterialPageRoute(builder: (context) => screen);
    if (shouldPop) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
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
            _buildNavItem(context, Icons.home, "Home", 0),
            _buildNavItem(context, Icons.shopping_bag, "Shopping", 1),
            _buildNavItem(context, Icons.attach_money, "Bills", 2),
            _buildNavItem(context, Icons.chat_bubble_outline, "Chat", 3),
            _buildNavItem(context, Icons.check_circle_outline, "Tasks", 4),
          ],
        ),
      ),
    );
  }


  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;

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
              color: isSelected ? AppColors.primaryBlue : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksGate extends StatefulWidget {
  const _TasksGate({Key? key}) : super(key: key);

  @override
  State<_TasksGate> createState() => _TasksGateState();
}

class _TasksGateState extends State<_TasksGate> {
  final _api = ApiClient.dev();

  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    try {
      final auth = AuthApi(_api);
      final roomApi = RoomApi(_api);

      final me = await auth.getMe();           // has user id
      final myRoom = await roomApi.getMyRoom(); // or get room via /rooms/me
      final roomId = myRoom.room?.id;

      if (!mounted) return;
      if (roomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No room yet — create or join first')),
        );
        Navigator.pop(context);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TasksScreen(roomId: roomId, userId: me.id)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Tasks: $e')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}


