// Updated HomeScreen using SharedBottomNav
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'chat_screen.dart';
import 'shopping_list_screen.dart';
import 'bill_screen.dart';
import 'shared_bottom_nav.dart'; 
import 'dart:math';
import 'settings_screen.dart';
import 'task_screen.dart';
import '../api/client.dart';
import '../api/auth_api.dart';
import '../api/room_api.dart';
import '../api/model.dart';

import '../utils/url_utils.dart';
import 'package:flutter/services.dart';
import '../api/bills_api.dart';
import '../api/bills_models.dart';
import '../api/tasks_api.dart';
import '../api/shopping_api.dart';
import '../api/tasks_models.dart';
import '../api/icon_map.dart';




class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _calendarController;
  late DateTime _currentDate;
  int _currentWeekIndex = 0;
  String? _userId;
  String? _roomId;
  bool _bootLoading = true;


  // apis
  late final ApiClient _api;
late final AuthApi _auth;
late final RoomApi _rooms;
late final TasksApi _tasksApi;
late final BillsApi _billsApi;
late final ShoppingApi _shoppingApi;

UserResponse? _me;
RoomResponse? _room;
List<UserResponse> _members = [];

List<TaskDto> _tasks = [];
List<BillResponse> _bills = [];
List<ShoppingItemDto> _shopping = [];

bool _loading = true;

int get _totalChores => _tasks.length; 
int get _totalShopping => _shopping.where((x) => !x.isBought).length;

List<BillResponse> get _unpaidBillsForMe {
  final uid = _me?.id;
  if (uid == null) return const [];
  return _bills.where((b) =>
    b.shares.any((s) => s.userId == uid && s.status != 'CONFIRMED')
  ).toList();
}

List<TaskDto> get _tasksForMe {
  final uid = _me?.id;
  if (uid == null) return [];
  return _tasks.where((t) => t.assignedTo == uid).toList();
}

List<TaskDto> get _homeTasks {
  final now = DateTime.now().toUtc();
  final list = List<TaskDto>.from(_tasksForMe); 
  list.sort((a, b) {
    final da = (a.nextDueDateUtc ?? a.createdDateUtc);
    final db = (b.nextDueDateUtc ?? b.createdDateUtc);
    return da.compareTo(db);
  });

  final upcoming = list.where((t) {
    final d = (t.nextDueDateUtc ?? t.createdDateUtc).toUtc();
    return d.isAfter(now);
  }).toList();

  if (upcoming.isNotEmpty) return [upcoming.first]; 
  return list.take(2).toList();
}


double get _totalOwedByMe {
  final uid = _me?.id;
  if (uid == null) return 0;
  double sum = 0;
  for (final b in _bills) {
    for (final s in b.shares) {
      if (s.userId == uid && s.status != 'CONFIRMED') sum += s.amount;
    }
  }
  return sum;
}

String _mon(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];


  
  // Expandable states
  final Map<String, bool> _choreExpanded = {};
  final Map<String, bool> _billExpanded = {};

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _calendarController = PageController(initialPage: 1000);
    _bootstrapIds(); 
  }


Future<void> _bootstrapIds() async {
  try {
    _api = ApiClient.dev();
    _auth = AuthApi(_api);
    _rooms = RoomApi(_api);
    _tasksApi = TasksApi(_api);
    _billsApi = BillsApi(_api);
    _shoppingApi = ShoppingApi(_api);

    final me = await _auth.getMe();
    final myRoom = await _rooms.getMyRoom();

    _me = me;
    _room = myRoom.room;
    _roomId = myRoom.room?.id;
    _userId = me.id;

    if (_roomId != null) {
      final results = await Future.wait([
        _rooms.getMembers(_roomId!),
        _tasksApi.listByRoom(_roomId!),
        _billsApi.listByRoom(_roomId!),
        _shoppingApi.list(_roomId!),
      ]);
      _members = results[0] as List<UserResponse>;
      _tasks   = results[1] as List<TaskDto>;
      _bills   = results[2] as List<BillResponse>;
      _shopping= results[3] as List<ShoppingItemDto>;
    }

    setState(() {
      _bootLoading = false;
      _loading = false;
    });
  } catch (_) {
    setState(() {
      _bootLoading = false;
      _loading = false;
    });
  }
}


  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  // Activity card tap handlers
  void _onActivityCardTap(String type) {
    switch (type) {
      case 'chores':
         if (_roomId == null || _userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create or join a room first')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TasksScreen(roomId: _roomId!, userId: _userId!),
        ),
      );
        break;
      case 'shopping':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShoppingListPage()),
        );
        break;
      case 'bills':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BillsScreen()),
        );
        break;
    }
  }

  Future<void> _openChat() async {
  if (_roomId == null || _userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create or join a room first')),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatScreen(roomId: _roomId!, userId: _userId!),
    ),
  );
}

List<TaskDto> get _sortedByDate {
  final list = List<TaskDto>.from(_tasks);
  list.sort((a, b) {
    final da = (a.nextDueDateUtc ?? a.createdDateUtc);
    final db = (b.nextDueDateUtc ?? b.createdDateUtc);
    return da.compareTo(db);
  });
  return list;
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
 if (_bootLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }


    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCalendar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHouseActivities(),
                    const SizedBox(height: 24),
                    _buildUpcomingChores(),
                    const SizedBox(height: 24),
                    _buildExpenses(),
                    const SizedBox(height: 24),
                    _buildMessagesCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SharedBottomNav(
  currentIndex: 0,
  roomId: _roomId,
  userId: _userId,
),


    );
  }

  // Widget _buildHeader() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16),
  //     child: Row(
  //       children: [
  //         GestureDetector(
  //           onTap: () {
  //             Navigator.of(context).push(
  //     PageRouteBuilder(
  //       opaque: false, // let your transparent background show
  //       pageBuilder: (_, __, ___) => const SettingsScreen(),
  //       transitionsBuilder: (_, animation, __, child) {
  //         final offsetTween = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
  //             .chain(CurveTween(curve: Curves.easeOutCubic));
  //         return SlideTransition(position: animation.drive(offsetTween), child: child);
  //       },
  //     ),
  //   );
  //           },
  //           child: Container(
  //             width: 40,
  //             height: 40,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: AppColors.primaryBlue,
  //             ),
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(20),
  //               child: Image.asset(
  //                 'assets/images/avatar_1.png',
  //                 fit: BoxFit.cover,
  //               ),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         const Text(
  //           'Hi, Ola',
  //           style: TextStyle(
  //             fontFamily: AppFonts.darkerGrotesque,
  //             fontSize: 18,
  //             fontWeight: FontWeight.w600,
  //             color: AppColors.black,
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         Image.asset(
  //           'assets/images/star.png',
  //           width: 20,
  //           height: 20,
  //         ),
  //         const Spacer(),
  //         const Text(
  //           'Home',
  //           style: TextStyle(
  //             fontFamily: AppFonts.darkerGrotesque,
  //             fontSize: 20,
  //             fontWeight: FontWeight.w700,
  //             color: AppColors.black,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }



Widget _buildHeader() {
  final avatar = _me?.avatarImageUrl;
  final first = _me?.firstName ?? 'You';

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        GestureDetector(
          onTap: () {
           // Where you open Settings (e.g., HomeScreen)
Navigator.of(context).push(
  PageRouteBuilder(
    opaque: false,
    pageBuilder: (_, __, ___) => SettingsScreen(
      userId: _userId,   
      roomId: _roomId,  
    ),
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: a.drive(Tween(begin: const Offset(-1,0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic))),
      child: child,
    ),
  ),
);

          },
          child: Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlue),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: (avatar != null)
                  ? Image.network(absoluteUrl(avatar), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset('assets/images/avatar_1.png', fit: BoxFit.cover))
                  : Image.asset('assets/images/avatar_1.png', fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Hi, $first',
          style: const TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: 8),
        Image.asset('assets/images/star.png', width: 20, height: 20),
        const Spacer(),
        const Text('Home',
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
            _currentWeekIndex = index - 1000;
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
  final billsCount = _unpaidBillsForMe.length;
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
              title: '${_totalChores} Chores pending',
              icon: 'cleaning.png',
              color: const Color(0xFF4A90E2),
              onTap: () => _onActivityCardTap('chores'),
            ),
            const SizedBox(width: 12),
            _buildActivityCard(
              title: '${_totalShopping} shopping items',
              icon: 'shopping_cart.png',
              color: const Color(0xFF4A90E2),
              onTap: () => _onActivityCardTap('shopping'),
            ),
            const SizedBox(width: 12),
            _buildActivityCard(
              title: '$billsCount Bills due',
              icon: 'billhand.png',
              color: const Color(0xFFE74C93),
              onTap: () => _onActivityCardTap('bills'),
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  width: 48,
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
      ),
    );
  }


Widget _buildUpcomingChores() {
  if (_loading) {
    return const Center(child: Padding(
      padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
  }

if (_homeTasks.isEmpty) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text(
        'Upcoming Chores',
        style: TextStyle(
          fontFamily: AppFonts.darkerGrotesque,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      SizedBox(height: 8),
      Center(
        child: Text(
          'You have no tasks right now.\nMaybe take a stretch, or just vibe ✨',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 14,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}


  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Upcoming Chores',
        style: TextStyle(
          fontFamily: AppFonts.darkerGrotesque,
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black)),
      const SizedBox(height: 12),
      ..._homeTasks.map((t) {
        final d = (t.nextDueDateUtc ?? t.createdDateUtc).toLocal();
        final date = '${_mon(d.month)}\n${d.day.toString().padLeft(2,'0')}';
        final subtitle = () {
          final assigneeId = t.assignedTo;
          final name = _members.firstWhere(
            (m) => m.id == assigneeId,
            orElse: () => UserResponse(id: '', firstName: 'Unassigned', email: '', createdAt: '', role: 'MEMBER'),
          ).firstName;
          return name.isEmpty ? 'Unassigned' : name;
        }();
       final iconName = assetFromIconEnum(t.iconId);
       return _buildChoreItem(
        id: t.id,
        date:date,
        icon:iconName,
        title:t.name,
        subtitle:subtitle,
        isCompleted:false,
       );
      }),
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

// REPLACE _buildExpenses()
Widget _buildExpenses() {
  final items = _unpaidBillsForMe..sort((a,b) => a.dueDate.compareTo(b.dueDate));
  final top = items.take(2).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Your Expenses',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black)),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Settle Up',
              style: TextStyle(
                fontFamily: AppFonts.darkerGrotesque,
                fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      const SizedBox(height: 12),

      if (top.isEmpty) ...[
        const Text(
          'No upcoming expenses\nBreathe in. Breathe out.\nYour wallet is at peace. (Or maybe offline 😅)',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 14, color: Color(0xFF666666))),
      ] else ...top.map((b) {
        final my = b.shares.firstWhere(
          (s) => s.userId == _me!.id, orElse: () => BillShare(userId: '', amount: 0, status: 'CONFIRMED'));
        final d = b.dueDate.toLocal();
        final date = '${_mon(d.month)}\n${d.day.toString().padLeft(2,'0')}';
        final amount = my.amount.toStringAsFixed(2);
        final whoPaid = (b.paidByUserId == _me!.id) ? 'You paid' : 'Someone else paid';
        final icon = '💸';
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsScreen())),
          child: _buildBillItem(
            id: b.id,
            date: date,
            title: b.name,
            subtitle: 'You owe \$${amount}',
            amount: '\$${b.amount.toStringAsFixed(2)}',
            amountSubtitle: whoPaid,
            icon: icon,
          ),
        );
      }),
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
  final avatars = _members.take(5).map((m) => m.avatarImageUrl).toList();

  return GestureDetector(
    onTap: _openChat,
    child: Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < avatars.length; i++)
                  Positioned(
                    left: i * 24,
                    top: 0,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: DecorationImage(
                          image: (avatars[i] != null)
                            ? NetworkImage(absoluteUrl(avatars[i]!))
                            : const AssetImage('assets/images/avatar_1.png') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                const Positioned(
                  left: 0, top: 50,
                  child: Text(
                    'You may have\nmessages',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.1416),
            child: Image.asset('assets/images/stretching_man.png',
              width: 120, height: 120, fit: BoxFit.contain),
          ),
        ],
      ),
    ),
  );
}

}