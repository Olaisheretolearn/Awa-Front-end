import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Settings panel
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildUserProfile(),
                          const SizedBox(height: 30),
                          _buildSettingsSection([
                            _buildSettingsItem(
                              icon: Icons.person_add,
                              title: 'Invite a flatmate?',
                              subtitle: 'Do you want to add a flat member to your household?',
                              color: AppColors.primaryBlue,
                              onTap: () => _showInviteFlatmateBottomSheet(context),
                            ),
                            _buildSettingsItem(
                              icon: Icons.edit,
                              title: 'Edit & Share Expense',
                              subtitle: 'Customize your expense and Chat More with flatmates',
                              color: AppColors.primaryBlue,
                              onTap: () => _showEditShareExpenseBottomSheet(context),
                            ),
                          ]),
                          const SizedBox(height: 20),
                          _buildSettingsSection([
                            _buildSimpleSettingsItem(
                              icon: Icons.language,
                              title: 'Languages',
                              color: AppColors.primaryBlue,
                            ),
                            _buildSimpleSettingsItem(
                              icon: Icons.euro,
                              title: 'Currencies',
                              color: AppColors.primaryBlue,
                            ),
                            _buildSimpleSettingsItem(
                              icon: Icons.thumb_up,
                              title: 'Rate App',
                              color: AppColors.primaryBlue,
                            ),
                            _buildSimpleSettingsItem(
                              icon: Icons.article,
                              title: 'News',
                              color: AppColors.primaryBlue,
                            ),
                          ]),
                          const SizedBox(height: 20),
                          _buildSettingsSection([
                            _buildSimpleSettingsItem(
                              icon: Icons.logout,
                              title: 'Leave household',
                              color: Colors.red,
                            ),
                            _buildSimpleSettingsItem(
                              icon: Icons.delete,
                              title: 'Delete Account',
                              color: Colors.red,
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
          // Transparent overlay for the rest of the screen
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

void _showInviteFlatmateBottomSheet(BuildContext context) {
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
            child: const InviteFlatmateBottomSheet(),
          ),
        ),
      ),
    ),
  );
}

void _showEditShareExpenseBottomSheet(BuildContext context) {
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
            child: const EditShareExpenseBottomSheet(),
          ),
        ),
      ),
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
            icon: const Icon(
              Icons.close,
              color: AppColors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset(
              'assets/images/realhand.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ola',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              Text(
                'ola@example.com',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
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
          return Column(
            children: [
              item,
              if (!isLast)
                const Divider(
                  height: 1,
                  color: Color(0xFFF0F0F0),
                  indent: 60,
                ),
            ],
          );
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
              child: Icon(
                icon,
                color: color,
                size: 20,
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
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF666666),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSettingsItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
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
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF666666),
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'Credits',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Data privacy',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Version 1.0.0',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}

class InviteFlatmateBottomSheet extends StatelessWidget {
  const InviteFlatmateBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return SafeArea(
      top: false,
      child: Container(
        height: h * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
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

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // App icon and title
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/realhand.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Share this access code to your flatmates to access',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
                    const Text(
                      'this home expenses to the other family member',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Access code container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'XUJRQO',
                            style: TextStyle(
                              fontFamily: AppFonts.darkerGrotesque,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              letterSpacing: 4,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Deactivate access code',
                            style: TextStyle(
                              fontFamily: AppFonts.darkerGrotesque,
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Share button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Add share functionality here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
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
  const EditShareExpenseBottomSheet({super.key});

  @override
  State<EditShareExpenseBottomSheet> createState() => _EditShareExpenseBottomSheetState();
}

class _EditShareExpenseBottomSheetState extends State<EditShareExpenseBottomSheet> {
  final TextEditingController _emailController = TextEditingController(text: 'olasunkanmi234@gmail.com');

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
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
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

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // App icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          'assets/images/interac.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title and description
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
                      'Kindly share your interac e transfer to receive money for monthly expenses, You can always edit ut if youre not using the same email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                 
                    const SizedBox(height: 40),

                    // Email input container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
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
                          ),
                          const SizedBox(height: 12),
                        
                        ],
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

                    // Edit email button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle edit email functionality
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Edit email',
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