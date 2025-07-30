import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'create_shared_flat_screen.dart';
import 'enter_code_screen.dart';

class CreateJoinFlatScreen extends StatefulWidget {
  const CreateJoinFlatScreen({super.key});

  @override
  State<CreateJoinFlatScreen> createState() => _CreateJoinFlatScreenState();
}

class _CreateJoinFlatScreenState extends State<CreateJoinFlatScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;

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
            
            // Money - left side
            Positioned(
              left: 60,
              top: 120 + (9 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.25,
                child: Image.asset(
                  'assets/images/money.png',
                  width: 40,
                  height: 40,
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
            
            // Gloves - left side
            Positioned(
              left: 80,
              top: 240 + (5 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.25,
                child: Image.asset(
                  'assets/images/glove.png',
                  width: 52,
                  height: 52,
                ),
              ),
            ),
            
            // Shopping cart - right side
            Positioned(
              right: 60,
              top: 220 + (8 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.1,
                child: Image.asset(
                  'assets/images/shopping_cart.png',
                  width: 54,
                  height: 54,
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
            
            Positioned(
              right: 140,
              top: 180 + (5 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.6,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 22,
                  height: 22,
                ),
              ),
            ),
            
            Positioned(
              left: 180,
              top: 150 + (8 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.35,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
            
            Positioned(
              right: 180,
              top: 240 + (6 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.45,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 20,
                  height: 20,
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
          child: Stack(
            children: [
              // Floating icons background
              _buildFloatingIcons(),
              
              // Main content
              Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  
                 
                  const Spacer(flex: 2),
                  
                  
                  Text(
                    'awa',
                    style: TextStyle(
                      fontFamily: AppFonts.boulder,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Title and subtitle
                  Text(
                    "Let's get started",
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    "Create a shared flat or enter an invitation code.",
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // Spacer to push buttons down
                  const Spacer(flex: 2),
                  
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // Create a shared flat button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CreateSharedFlatScreen(),
    ),
  );
},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Create a shared flat.',
                                  style: TextStyle(
                                    fontFamily: AppFonts.darkerGrotesque,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.black,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Enter invitation code button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle enter invitation code action
                            Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const InvitationCodeScreen(),
  ),
);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppColors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Enter an invitation code.',
                                  style: TextStyle(
                                    fontFamily: AppFonts.darkerGrotesque,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}