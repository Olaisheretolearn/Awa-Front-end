import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../widgets/currency_picker_bottom_sheet.dart';
import '../screens/create_join_flat_screen.dart';
import '../api/app_error.dart';

import '../api/client.dart';
import '../api/auth_api.dart';
import '../api/room_api.dart';
import '../api/model.dart';
import '../utils/url_utils.dart';

class SettingsScreen extends StatefulWidget {
    final String? userId;
  final String? roomId;
 const SettingsScreen({super.key, this.userId, this.roomId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ApiClient _api;
  late final AuthApi _auth;
  late final RoomApi _rooms;

  bool _loading = true;
  UserResponse? _me;
  String? _roomCode;

  @override
  void initState() {
    super.initState();
    _api = ApiClient.dev();
    _auth = AuthApi(_api);
    _rooms = RoomApi(_api);
    _bootstrap();
  }

Future<void> _bootstrap() async {
  try {

    UserResponse me = (widget.userId != null)
        ? await _auth.getUserById(widget.userId!)
        : await _auth.getMe();

    String? avatarUrl = me.avatarImageUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarUrl = absoluteUrl(avatarUrl); // <— prepend base url
    } else if (me.avatarId != null && me.avatarId!.isNotEmpty) {
      avatarUrl = absoluteUrl("/avatars/${me.avatarId!.toLowerCase()}.png");
    }

    final resolvedMe = UserResponse(
      id: me.id,
      firstName: me.firstName,
      email: me.email,
      createdAt: me.createdAt,
      role: me.role,
      roomId: me.roomId,
      avatarId: me.avatarId,
      avatarImageUrl: avatarUrl,
    );

    
    setState(() {
      _me = resolvedMe;
      _loading = false;
    });

    String? code;
    try {
      final myRoom = await _rooms.getMyRoom();
      code = myRoom.room?.code;
    } catch (_) {
  
    }

    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      setState(() => _roomCode = code);
    }

  } catch (e) {
    if (!mounted) return;
    setState(() => _loading = false);
  }
}


Future<void> _leaveHousehold() async {
  if (_me == null) return;

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Leave household?'),
      content: const Text(
        'You’ll lose access to chat, chores, bills, and shopping for this room.'
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Leave')),
      ],
    ),
  );

  if (ok != true) return;


  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await _rooms.leaveRoom(_me!.id); 
    if (!mounted) return;

   
    setState(() {
      _roomCode = null;
      _me = _me!.copyWith(roomId: null); 
    });

    // close loader
    Navigator.of(context).pop();

   
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CreateJoinFlatScreen()),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;
    Navigator.of(context).pop();

    final err = mapDioError(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(friendlyMessage(err))),
    );
  }
}



  void _notImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature not yet implemented')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
       
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildUserProfile(),
                                const SizedBox(height: 30),
                                _buildSettingsSection([
                                  _buildSettingsItem(
                                    icon: Icons.person_add,
                                    title: 'Invite a flatmate?',
                                    subtitle:
                                        'Share your household’s code with a new member',
                                    color: AppColors.primaryBlue,
                                    onTap: () => _showInviteFlatmateBottomSheet(
                                      context,
                                      code: _roomCode,
                                    ),
                                  ),
                                  _buildSettingsItem(
                                    icon: Icons.edit,
                                    title: 'Edit & Share Expense',
                                    subtitle:
                                        'Add / update the email you receive transfers to',
                                    color: AppColors.primaryBlue,
                                    onTap: () =>
                                        _showEditShareExpenseBottomSheet(
                                      context,
                                      email: _me?.email ?? '',
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 20),
                                _buildSettingsSection([
                                  _buildSimpleSettingsItem(
                                    icon: Icons.language,
                                    title: 'Languages',
                                    color: AppColors.primaryBlue,
                                    onTap: _notImplemented,
                                  ),
                                  _buildSimpleSettingsItem(
                                    icon: Icons.euro,
                                    title: 'Currencies',
                                    color: AppColors.primaryBlue,
                                    onTap: () => _showCurrenciesBottomSheet(context),
                                  ),
                                  _buildSimpleSettingsItem(
                                    icon: Icons.thumb_up,
                                    title: 'Rate App',
                                    color: AppColors.primaryBlue,
                                    onTap: _notImplemented,
                                  ),
                                  _buildSimpleSettingsItem(
                                    icon: Icons.article,
                                    title: 'News',
                                    color: AppColors.primaryBlue,
                                    onTap: _notImplemented,
                                  ),
                                ]),
                                const SizedBox(height: 20),
                                _buildSettingsSection([
                                  _buildSimpleSettingsItem(
                                    icon: Icons.logout,
                                    title: 'Leave household',
                                    color: Colors.red,
                                    onTap: _leaveHousehold,
                                  ),
                                  _buildSimpleSettingsItem(
                                    icon: Icons.delete,
                                    title: 'Delete Account',
                                    color: Colors.red,
                                    onTap: _notImplemented,
                                  ),
                                ]),
                                const SizedBox(height: 30),
                                _buildFooter(),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black26),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.black, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
  final name = (_me?.firstName.isNotEmpty ?? false) ? _me!.firstName : '—';
  final email = _me?.email ?? '—';
  final avatarUrl = _me?.avatarImageUrl;

  return Row(
    children: [
      Container(
        width: 50, height: 50,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlue),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? Image.network(
                  absoluteUrl(avatarUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.asset('assets/images/avatar_1.png', fit: BoxFit.cover),
                )
              : Image.asset('assets/images/avatar_1.png', fit: BoxFit.cover),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(
              fontFamily: AppFonts.darkerGrotesque, fontSize: 20,
              fontWeight: FontWeight.w600, color: AppColors.black)),
            Text(email, style: const TextStyle(
              fontFamily: AppFonts.darkerGrotesque, fontSize: 14,
              color: Color(0xFF666666))),
          ],
        ),
      ),
    ],
  );
}


  Widget _buildSettingsSection(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: items.map((item) {
          final isLast = items.last == item;
          return Column(children: [
            item,
            if (!isLast)
              const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 60),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF666666), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSettingsItem({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color == Colors.red ? Colors.red : AppColors.black,
                ),
              ),
            ),
            if (color != Colors.red)
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF666666), size: 16),
          ],
        ),
      ),
    );
  }

  void _showCurrenciesBottomSheet(BuildContext context) {
    final panelWidth = MediaQuery.of(context).size.width * 0.8;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      isScrollControlled: true,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: GestureDetector(
            onTap: () {}, 
            child: SizedBox(
              width: panelWidth,
              child: const CurrencyPickerBottomSheet(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(onPressed: _notImplemented, child: const Text('Credits',
                style: TextStyle(fontFamily: AppFonts.darkerGrotesque, fontSize: 12, color: AppColors.primaryBlue))),
            TextButton(onPressed: _notImplemented, child: const Text('Terms and Conditions',
                style: TextStyle(fontFamily: AppFonts.darkerGrotesque, fontSize: 12, color: AppColors.primaryBlue))),
            TextButton(onPressed: _notImplemented, child: const Text('Data privacy',
                style: TextStyle(fontFamily: AppFonts.darkerGrotesque, fontSize: 12, color: AppColors.primaryBlue))),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Version 1.0.0',
            style: TextStyle(fontFamily: AppFonts.darkerGrotesque, fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }



  void _showInviteFlatmateBottomSheet(BuildContext context, {String? code}) {
    final panelWidth = MediaQuery.of(context).size.width * 0.8;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: panelWidth,
              child: InviteFlatmateBottomSheet(roomCode: code),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditShareExpenseBottomSheet(BuildContext context, {required String email}) {
    final panelWidth = MediaQuery.of(context).size.width * 0.8;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: panelWidth,
              child: EditShareExpenseBottomSheet(initialEmail: email),
            ),
          ),
        ),
      ),
    );
  }
}



class InviteFlatmateBottomSheet extends StatelessWidget {
  final String? roomCode; 
  const InviteFlatmateBottomSheet({super.key, this.roomCode});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final code = (roomCode == null || roomCode!.isEmpty) ? 'NO-ROOM' : roomCode!;

    return SafeArea(
      top: false,
      child: Container(
        height: h * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset('assets/images/realhand.png', fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Share this access code with your flatmates',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: AppFonts.darkerGrotesque, fontSize: 16, color: AppColors.white),
                    ),
                    const SizedBox(height: 40),

                    // Access code
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Text(
                            code,
                            style: const TextStyle(
                              fontFamily: AppFonts.darkerGrotesque,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied')),
                              );
                            },
                            child: const Text(
                              'Tap to copy',
                              style: TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

             
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                  
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied. Share anywhere!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: const Text(
                          'Share code',
                          style: TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class EditShareExpenseBottomSheet extends StatefulWidget {
  final String initialEmail;
  const EditShareExpenseBottomSheet({super.key, required this.initialEmail});

  @override
  State<EditShareExpenseBottomSheet> createState() => _EditShareExpenseBottomSheetState();
}

class _EditShareExpenseBottomSheetState extends State<EditShareExpenseBottomSheet> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return SafeArea(
      top: false,
      child: Container(
        height: h * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppColors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: AppColors.primaryYellow, borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset('assets/images/interac.png', fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Settle up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share the email you receive e-transfers on. You can change it anytime.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: AppFonts.darkerGrotesque, fontSize: 14, color: AppColors.white),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                      child: TextFormField(
                        controller: _emailController,
                        style: const TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Not the same as sign up email?',
                      style: TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 15,
                        color: Color.fromARGB(255, 240, 236, 236),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Persist later when implemented
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Feature not yet implemented')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: const Text(
                          'Save email',
                          style: TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
