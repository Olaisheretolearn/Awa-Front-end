import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'chat_screen.dart';
import 'shopping_list_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _calendarController;
  late DateTime _currentDate;
  int _currentWeekIndex = 0;
  
  // Expandable states
  final Map<String, bool> _choreExpanded = {};
  final Map<String, bool> _billExpanded = {};

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _calendarController = PageController(initialPage: 1000); // Start in middle for infinite scroll
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  List<DateTime> _getWeekDates(DateTime baseDate, int weekOffset) {
    final startOfWeek = baseDate.subtract(Duration(days: baseDate.weekday - 1));
    final weekStart = startOfWeek.add(Duration(days: weekOffset * 7));
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Calendar
            _buildCalendar(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // What's up in the house today?
                    _buildHouseActivities(),
                    
                    const SizedBox(height: 24),
                    
                    // Upcoming Chores
                    _buildUpcomingChores(),
                    
                    const SizedBox(height: 24),
                    
                    // Your Expenses
                    _buildExpenses(),
                    
                    const SizedBox(height: 24),
                    
                    // Messages Card
                    _buildMessagesCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Navigate to settings
              print('Navigate to settings');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/avatar_1.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Hi, Ola',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/star.png',
            width: 20,
            height: 20,
          ),
          const Spacer(),
          const Text(
            'Home',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      height: 80,
      child: PageView.builder(
        controller: _calendarController,
        onPageChanged: (index) {
          setState(() {
            _currentWeekIndex = index - 1000; // Offset for infinite scroll
          });
        },
        itemBuilder: (context, index) {
          final weekOffset = index - 1000;
          final weekDates = _getWeekDates(_currentDate, weekOffset);
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDates.map((date) {
                final isToday = date.day == DateTime.now().day && 
                               date.month == DateTime.now().month &&
                               date.year == DateTime.now().year;
                
                return Container(
                  width: 40,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primaryYellow : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date.weekday),
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isToday ? AppColors.white : const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isToday ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHouseActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s up in the house today?',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildActivityCard(
                title: '2 Chores pending',
                icon: 'cleaning.png',
                color: const Color(0xFF4A90E2),
              ),
              const SizedBox(width: 12),
              _buildActivityCard(
                title: '10+ shopping items',
                icon: 'shopping_cart.png',
                color: const Color(0xFF4A90E2),
              ),
              const SizedBox(width: 12),
              _buildActivityCard(
                title: '3 Bills due',
                icon: 'billhand.png',
                color: const Color(0xFFE74C93),
              ),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildActivityCard({
  required String title,
  required String icon,
  required Color color,
}) {
  return Container(
    width: 140,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: Image.asset(
              'assets/images/$icon',
              width: 48, // or 56 for bigger
              height: 48,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

 
  Widget _buildUpcomingChores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Chores',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildChoreItem(
          id: 'bathroom',
          date: 'Aug\n7',
          icon: 'bathroom_icon.png',
          title: 'Clean the bathroom',
          subtitle: 'Bob Ross',
          isCompleted: false,
        ),
        _buildChoreItem(
          id: 'plants',
          date: 'Aug\n7',
          icon: 'watering_can.png',
          title: 'Water indoor plants',
          subtitle: 'Christine Oke',
          isCompleted: true,
        ),
      ],
    );
  }

  Widget _buildChoreItem({
    required String id,
    required String date,
    required String icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    final isExpanded = _choreExpanded[id] ?? false;
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _choreExpanded[id] = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  child: Text(
                    date,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/$icon',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF666666),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) _buildChoreDropdown(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildChoreDropdown() {
    return Container(
      margin: const EdgeInsets.only(left: 72, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chore Details',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clean bathroom thoroughly, including toilet, shower, and sink.',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Mark Complete',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Expenses',
              style: TextStyle(
                fontFamily: AppFonts.darkerGrotesque,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Settle Up',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBillItem(
          id: 'gas',
          date: 'Aug\n12',
          title: 'Gas Bill',
          subtitle: '\$12.50 from Jim',
          amount: '\$50.00',
          amountSubtitle: 'Bob paid',
          icon: '🔥',
        ),
        _buildBillItem(
          id: 'water',
          date: 'Aug\n22',
          title: 'Water Bill',
          subtitle: '\$12.50 from Jim',
          amount: '\$50.00',
          amountSubtitle: 'Bob paid',
          icon: '💧',
        ),
      ],
    );
  }

  Widget _buildBillItem({
    required String id,
    required String date,
    required String title,
    required String subtitle,
    required String amount,
    required String amountSubtitle,
    required String icon,
  }) {
    final isExpanded = _billExpanded[id] ?? false;
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _billExpanded[id] = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  child: Text(
                    date,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: const TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      amountSubtitle,
                      style: const TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF666666),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) _buildBillDropdown(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBillDropdown() {
    return Container(
      margin: const EdgeInsets.only(left: 72, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monthly gas bill for the house. Bob has already paid this bill.',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Settle Up',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



Widget _buildMessagesCard() {
  final random = Random();

  // Randomize 2–4 icons
  final allIcons = ['pizza.png', 'money.png', 'star.png'];
  final iconsToShow = List.generate(
    random.nextInt(3) + 2, // 2 to 4 icons
    (_) => allIcons[random.nextInt(allIcons.length)],
  );

  // You can change avatars here
  final avatars = ['avatar_1.png', 'avatar_3.png', 'avatar_5.png', 'avatar_8.png'];

  return Container(
    height: 140,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4A90E2),
          Color(0xFF357ABD),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        /// LEFT SIDE: Avatars + icons
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              /// Avatars (overlapping)
              for (int i = 0; i < avatars.length; i++)
                Positioned(
                  left: i * 24,
                  top: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: AssetImage('assets/images/${avatars[i]}'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

              /// Message Text
              Positioned(
                left: 0,
                top: 50,
                child: const Text(
                  'You have 5\nmessages from\nyour flatmates',
                  style: TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
              ),

              /// Floating Icons
              for (int i = 0; i < iconsToShow.length; i++)
                Positioned(
                top: (10 + random.nextInt(40)).toDouble(),
left: (100 + random.nextInt(40)).toDouble(),

                  child: Image.asset(
                    'assets/images/${iconsToShow[i]}',
                    width: 40, // ⬅️ Larger size
                    height: 40,
                  ),
                ),
            ],
          ),
        ),

        /// RIGHT SIDE: Flipped man
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(3.1416),
          child: Image.asset(
            'assets/images/stretching_man.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ],
    ),
  );
}

int _selectedIndex = 0;

Widget _buildBottomNav() {
  return SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, "Home", 0),
          _buildNavItem(Icons.shopping_bag, "Shopping", 1),
          _buildNavItem(Icons.attach_money, "Bills", 2),
          _buildNavItem(Icons.chat_bubble_outline, "Chat", 3),
        ],
      ),
    ),
  );
}


Widget _buildNavItem(IconData icon, String label, int index) {
  final bool isSelected = _selectedIndex == index;

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedIndex = index;
      });

      // Navigation logic based on index
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  ShoppingListPage()),
        );
      } else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      }
    },
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