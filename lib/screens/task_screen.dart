import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'shared_bottom_nav.dart';
import '../api/client.dart';
import '../api/tasks_api.dart';
import '../api/tasks_models.dart';
import '../api/icon_map.dart';
import '../api/room_api.dart';
import '../api/model.dart';
import '../utils/url_utils.dart';
import '../widgets/exit_app_guard.dart';

class TasksScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  const TasksScreen({super.key, required this.roomId, required this.userId});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final TasksApi _api;
  List<TaskDto> _tasks = [];
  bool _loading = true;
  String? _error;
  bool _loadingRoommates = true;
  Map<String, String> _roommatesByName = {};
  Map<String, String> _nameById = {};
  final Set<String> _expandedTasks = <String>{};
  List<UserResponse> _members = [];

  @override
  void initState() {
    super.initState();
    _api = TasksApi(ApiClient.dev());
    _load();
    _loadRoommates();
  }

  Future<void> _loadRoommates() async {
    try {
      final roomApi = RoomApi(ApiClient.dev());
      final members = await roomApi.getMembers(widget.roomId);

      final me = members.firstWhere((m) => m.id == widget.userId,
          orElse: () => members.first);
      final others = members.where((m) => m.id != widget.userId).toList();

      setState(() {
        _members = members;

        _roommatesByName = {
          'You': widget.userId,
          for (final m in others) m.firstName: m.id,
        };

        _nameById = {
          for (final m in members)
            m.id: (m.id == widget.userId ? 'You' : m.firstName),
        };

        _loadingRoommates = false;
      });
    } catch (_) {
      setState(() => _loadingRoommates = false);
    }
  }

  UserResponse? _findMemberById(String id) {
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> _load() async {
    try {
      final items = await _api.listByRoom(widget.roomId);
      setState(() {
        _tasks = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load tasks';
        _loading = false;
      });
    }
  }

//   Future<void> _loadRoommates() async {
//   final members = await _api.getRoommates(widget.roomId);
//   setState(() {
//     _roommates = members;
//   });
// }
// //
//  Set<String> expandedTasks = <String>{};
//  List<Roommate> _roommates = [];

  @override
  Widget build(BuildContext context) {
      return ExitAppGuard(
    rootOnly: true, 
    child: Scaffold(
     backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _tasks.isEmpty
                            ? _buildEmpty() 
                            : _buildTasksList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskBottomSheet,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: AppColors.white, size: 28),
      ),
      bottomNavigationBar: SharedBottomNav(
  currentIndex: 4,                // Tasks tab index
  roomId: widget.roomId,
  userId: widget.userId,
),
    ),
  );
  }

  Widget _buildEmpty() => const Center(
        child: Text('No Tasks yet ✨',
            style:
                TextStyle(fontFamily: AppFonts.darkerGrotesque, fontSize: 16)),
      );

  Widget _buildHeader() {
    final me = _findMemberById(widget.userId);
    final avatarUrl = me?.avatarImageUrl; // e.g. "/avatars/ava_03.png"

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.menu, color: AppColors.white, size: 24),
          const SizedBox(width: 16),
          const Text(
            'Tasks',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: (avatarUrl != null)
                  ? Image.network(
                      absoluteUrl(avatarUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/avatar_1.png',
                          fit: BoxFit.cover),
                    )
                  : Image.asset('assets/images/avatar_1.png',
                      fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (_, i) {
          final t = _tasks[i];
          final assignedName = t.assignedTo != null
              ? (_nameById[t.assignedTo!] ?? t.assignedTo!)
              : 'Unassigned';
          return _buildTaskItem(t, assignedName);
        },
      );

  Widget _buildTaskItem(TaskDto task, String assignedName) {
    final isExpanded = _expandedTasks.contains(task.id);
    final d = task.nextDueDateUtc ?? task.createdDateUtc;
    final month = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][d.month - 1];
    final assetIcon =
        assetFromIconEnum(task.iconId); // your mapper: enum -> asset name

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded
                    ? _expandedTasks.remove(task.id)
                    : _expandedTasks.add(task.id);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$month\n${d.day}',
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
                      color: AppColors.primaryYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: task.iconImageUrl != null
                          ? Image.network(absoluteUrl(task.iconImageUrl),
                              width: 24, height: 24)
                          : Image.asset('assets/images/$assetIcon',
                              width: 24, height: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: const TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          assignedName,
                          style: const TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),

                        // Description preview
                        if ((task.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppFonts.darkerGrotesque,
                              fontSize: 13,
                              color: Color(0xFF8A8A8A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF666666),
                      size: 20),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildTaskDropdown(task),
        ],
      ),
    );
  }

  Widget _buildTaskDropdown(TaskDto task) {
    return Container(
      margin: const EdgeInsets.only(left: 62, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((task.description ?? '').isNotEmpty) ...[
            Text(
              task.description!,
              style: const TextStyle(
                fontFamily: AppFonts.darkerGrotesque,
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'Task Actions',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final updated = await _api.markComplete(
                          widget.roomId, task.id, widget.userId);
                      setState(() {
                        _tasks = _tasks
                            .map((t) => t.id == updated.id ? updated : t)
                            .toList();
                        _expandedTasks.remove(task.id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Yayyyyyyy Task done!")),
                      );
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Sure that's your task? 😅")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
                onPressed: () async {
                  try {
                    await _api.delete(widget.roomId, task.id);
                    setState(() {
                      _tasks.removeWhere((t) => t.id == task.id);
                      _expandedTasks.remove(task.id);
                    });
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not delete task')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
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



String friendlyCompleteError({
  int? status,
  String? serverMessage,
  required String assigneeName,
}) {
  final msg = (serverMessage ?? '').toLowerCase();

  if (status == 403 && msg.contains('not assigned')) {
    return "uhm… looks like $assigneeName was assigned to that task 😅\n"
           "feeling hyper? because that's not your task 🙈";
  }

  if (status == 403 && msg.contains('room') && msg.contains('member')) {
    return "you’re not a member of this room yet 🚪\nask for an invite first!";
  }

  if ((status == 409) || (msg.contains('already') && msg.contains('complete'))) {
    return "this one’s already done ✅ nice try!";
  }

  return "couldn’t mark it complete right now 🤖\ntry again in a bit!";
}








  void _showCreateTaskBottomSheet() {
    if (_loadingRoommates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still loading roommates…')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTaskBottomSheet(
        onSubmit: (TaskCreateReq req) async {
          try {
            final created = await _api.create(widget.roomId, req);
            setState(() => _tasks = [..._tasks, created]);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Task created!',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.primaryBlue,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to create task')));
          }
        },
        currentUserId: widget.userId,
        roommatesByName: _roommatesByName,
        members: _members,
      ),
    );
  }
}

class CreateTaskBottomSheet extends StatefulWidget {
  final Future<void> Function(TaskCreateReq) onSubmit;
  final String? currentUserId;
  final Map<String, String> roommatesByName;
  final List<UserResponse> members;

  const CreateTaskBottomSheet(
      {super.key,
      required this.onSubmit,
      required this.currentUserId,
      required this.roommatesByName,
      required this.members});

  @override
  State<CreateTaskBottomSheet> createState() => _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends State<CreateTaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedIcon = 'cleaning.png';
  String? _selectedAssigneeId;
  List<String> get _assigneeNames => widget.roommatesByName.keys.toList();

  @override
  void initState() {
    super.initState();
    _selectedAssigneeId = widget.currentUserId;
  }

  UserResponse? _findMemberById(String id) {
    for (final m in widget.members) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<MapEntry<String, String>> get _assigneeEntries =>
      widget.roommatesByName.entries.toList();

  void _onAssigneeSelected(String name) {
    setState(() {
      _selectedAssigneeId = widget.roommatesByName[name];
    });
  }

  final List<String> _availableIcons = [
    'cleaning.png',
    'glove.png',
    'bathroom_icon.png',
    'watering_can.png',
    'shopping_cart.png',
    'money.png',
    'spraybottle.png',
    'pizza.png',
  ];

  // final List<Map<String, dynamic>> _assignees = [
  //   {'name': 'yourself', 'avatar': 'avatar_1.png', 'color': AppColors.primaryBlue},
  //   {'name': 'Ole', 'avatar': 'avatar_2.png', 'color': Colors.orange},
  //   {'name': 'Ross', 'avatar': 'avatar_3.png', 'color': AppColors.primaryBlue},
  //   {'name': 'Mifa', 'avatar': 'avatar_4.png', 'color': Colors.orange},
  // ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildBottomSheetHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTaskTitleField(),
                  const SizedBox(height: 16),
                  _buildTaskDescriptionField(),
                  const SizedBox(height: 16),
                  _buildDueDateSection(),
                  const SizedBox(height: 24),
                  _buildIconSelector(),
                  const SizedBox(height: 24),
                  _buildAssigneeSelector(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppFonts.darkerGrotesque,
                fontSize: 16,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const Text(
            'Create a Task',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          TextButton(
            onPressed: _createTask,
            child: const Text(
              'Done',
              style: TextStyle(
                fontFamily: AppFonts.darkerGrotesque,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Title',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter task title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
          style: const TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Description',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter task description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
          style: const TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDueDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due Date',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Choose the best matching icon',
                  style: TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 16,
                    color: _selectedDate != null
                        ? AppColors.black
                        : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose the best matching icon',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableIcons.map((icon) {
            final isSelected = _selectedIcon == icon;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIcon = icon;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppColors.primaryBlue, width: 2)
                      : null,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/$icon',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssigneeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Who are you assigning',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              color: Color(0xFF666666),
            )),
        const SizedBox(height: 12),
        Column(
          children: _assigneeEntries.map((e) {
            final label = e.key; // "You" or "harvey" etc.
            final id = e.value; // userId
            final isSelected = _selectedAssigneeId == id;

            final member = _findMemberById(id);
            final avatarUrl = member?.avatarImageUrl;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedAssigneeId = id),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : const Color(0xFFE0E0E0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: (avatarUrl != null)
                              ? Image.network(
                                  absoluteUrl(avatarUrl),
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 16),
                                )
                              : const Icon(Icons.person,
                                  color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CalendarBottomSheet(
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
      ),
    );
  }

  void _createTask() async {
    if (_titleController.text.trim().isEmpty || _selectedDate == null) return;

    final localNoon = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 12);
    final dueUtc = localNoon.toUtc();

    final req = TaskCreateReq(
      name: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      assignedTo: _selectedAssigneeId,
      recurrence: Recurrence.NONE,
      nextDueDateUtc: dueUtc,
      icon: iconEnumFromAsset(_selectedIcon),
    );

    try {
      await widget.onSubmit(req);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create task')),
      );
    }
  }
}

class CalendarBottomSheet extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const CalendarBottomSheet({
    super.key,
    required this.onDateSelected,
  });

  @override
  State<CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<CalendarBottomSheet> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          _buildWeekDayHeaders(),
          Expanded(child: _buildCalendarGrid()),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
            child: const Icon(
              Icons.chevron_left,
              color: AppColors.white,
              size: 24,
            ),
          ),
          Text(
            '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
            style: const TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
            child: const Icon(
              Icons.chevron_right,
              color: AppColors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayHeaders() {
    const weekDays = ['S', 'M', 'T', 'W', 'Th', 'F', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((day) {
          return Text(
            day,
            style: const TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: firstWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < firstWeekday) {
          return Container();
        }

        final day = index - firstWeekday + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final isSelected = _selectedDate?.day == day &&
            _selectedDate?.month == _currentMonth.month &&
            _selectedDate?.year == _currentMonth.year;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
            widget.onDateSelected(date);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primaryBlue : AppColors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month];
  }
}
