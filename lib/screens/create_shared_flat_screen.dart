import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../api/client.dart';
import '../api/room_api.dart';
import '../api/auth_api.dart';
import 'home_screen.dart';

class CreateSharedFlatScreen extends StatefulWidget {
  const CreateSharedFlatScreen({super.key});

  @override
  State<CreateSharedFlatScreen> createState() => _CreateSharedFlatScreenState();
}

class _CreateSharedFlatScreenState extends State<CreateSharedFlatScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  final TextEditingController _flatNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _floatingController.repeat();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _flatNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Widget _buildFloatingIcons() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: [
            // Pizza slice - top left
            Positioned(
              left: 20,
              top: 60 + (8 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.2,
                child: Image.asset(
                  'assets/images/pizza.png',
                  width: 48,
                  height: 48,
                ),
              ),
            ),

            // Pizza slice - top right
            Positioned(
              right: 20,
              top: 100 + (6 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.3,
                child: Image.asset(
                  'assets/images/pizza.png',
                  width: 42,
                  height: 42,
                ),
              ),
            ),

            // Money - top right
            Positioned(
              right: 80,
              top: 50 + (6 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.15,
                child: Image.asset(
                  'assets/images/money.png',
                  width: 44,
                  height: 44,
                ),
              ),
            ),

            // Vacuum - center left
            Positioned(
              left: 40,
              top: 180 + (10 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.1,
                child: Image.asset(
                  'assets/images/vaccum.png',
                  width: 56,
                  height: 56,
                ),
              ),
            ),

            // Spray bottle - center right
            Positioned(
              right: 40,
              top: 160 + (7 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.2,
                child: Image.asset(
                  'assets/images/spraybottle.png',
                  width: 50,
                  height: 50,
                ),
              ),
            ),

            // Stars scattered
            Positioned(
              left: 120,
              top: 80 + (4 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.5,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),

            Positioned(
              right: 120,
              top: 130 + (6 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.3,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 28,
                  height: 28,
                ),
              ),
            ),

            Positioned(
              left: 150,
              top: 200 + (7 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.4,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 26,
                  height: 26,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiClient.dev();
    final roomApi = RoomApi(api);
    final authApi = AuthApi(api);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBlue,
              Color(0xFF4A7EDF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with floating icons and logo
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    // Floating icons background
                    _buildFloatingIcons(),

                    // Logo centered
                    Center(
                      child: Text(
                        'àwà',
                        style: TextStyle(
                          fontFamily: AppFonts.boulder,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom section with form
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Create your shared flat',
                          style: TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Flat name field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name of your shared flat',
                              style: TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _flatNameController,
                              style: const TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 18,
                                color: AppColors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: '123 random address bay',
                                hintStyle: const TextStyle(
                                  fontFamily: AppFonts.darkerGrotesque,
                                  color: Color(0xFF999999),
                                ),
                                border: const UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: AppColors.primaryBlue),
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // City field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name of your City',
                              style: TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _cityController,
                              style: const TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 18,
                                color: AppColors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Winnipeg',
                                hintStyle: const TextStyle(
                                  fontFamily: AppFonts.darkerGrotesque,
                                  color: Color(0xFF999999),
                                ),
                                border: const UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: AppColors.primaryBlue),
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Next button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = _flatNameController.text.trim();
                              final city = _cityController.text.trim().isEmpty
                                  ? null
                                  : _cityController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Enter a name')));
                                return;
                              }
                              try {
                                // if you already store userId after login, use that here:
                                final me =
                                    await authApi.getMe(); // UserResponse
                                final room = await roomApi.createRoom(
                                    name: name, ownerId: me.id, city: city);

                                if (!mounted) return;
                                await showDialog(
                                    context: context,
                                    builder: (_) {
                                      return AlertDialog(
                                        title: const Text('Room created'),
                                        content: Text(
                                            'Share this code with roommates:\n${room.code}'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('OK'))
                                        ],
                                      );
                                    });

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HomeScreen()),
                                  (route) => false,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Create failed: $e')));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'NEXT',
                              style: TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // "I have a code, instead" link
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              // Handle go to invitation code
                              print('I have a code, instead pressed');
                              Navigator.pop(context);
                            },
                            child: Text(
                              'I have a code, instead',
                              style: TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
