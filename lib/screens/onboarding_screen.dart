import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'signup_screen.dart';
import 'signin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animationController.forward();
    _floatingController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo
                    FadeTransition(
                      opacity: _animationController,
                      child: const Text(
                        'Awa',
                        style: TextStyle(
                          fontFamily: AppFonts.boulder,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 160), // Much more space to push content down
                    
                    // Main content area - Title and subtitle only
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOutBack,
                      )),
                      child: FadeTransition(
                        opacity: _animationController,
                        child: Column(
                          children: [
                            // Title
                            const Text(
                              'Shared space,\nshared rhythm',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppFonts.boulder,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                height: 1.2,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Subtitle
                            const Text(
                              'Awa keeps everything from cleaning\nto groceries in sync',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: AppColors.white,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const Spacer(), 
                    
                    // Buttons - Side by side at bottom
                    Row(
                      children: [
                        // Log In Button
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignInScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.white,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'LOG IN',
                                style: TextStyle(
                                  fontFamily: AppFonts.darkerGrotesque,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Sign Up Button
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'SIGN UP',
                                style: TextStyle(
                                  fontFamily: AppFonts.darkerGrotesque,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              top: 120 + (10 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.2,
                child: Image.asset(
                  'assets/images/pizza.png',
                  width: 64,
                  height: 64,
                ),
              ),
            ),
            
            // Pizza slice duplicate - lower center
            Positioned(
              left: 120,
              top: 350 + (8 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.15,
                child: Image.asset(
                  'assets/images/pizza.png',
                  width: 56,
                  height: 56,
                ),
              ),
            ),
            
            // Money - top right
            Positioned(
              right: 10,
              top: 100 + (8 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.15,
                child: Image.asset(
                  'assets/images/money.png',
                  width: 60,
                  height: 60,
                ),
              ),
            ),
            
            // Money duplicate - bottom left
            Positioned(
              left: 10,
              bottom: 200 + (12 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.1,
                child: Image.asset(
                  'assets/images/money.png',
                  width: 58,
                  height: 58,
                ),
              ),
            ),
            
            // Vacuum - middle center
            Positioned(
              left: 150,
              top: 220 + (12 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.1,
                child: Image.asset(
                  'assets/images/vaccum.png',
                  width: 72,
                  height: 72,
                ),
              ),
            ),
            
            // Spray bottle - middle right
            Positioned(
              right: 20,
              top: 180 + (6 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.2,
                child: Image.asset(
                  'assets/images/spraybottle.png',
                  width: 62,
                  height: 62,
                ),
              ),
            ),
            
            // Spray bottle duplicate - bottom right  
            Positioned(
              right: 15,
              bottom: 240 + (7 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.25,
                child: Image.asset(
                  'assets/images/spraybottle.png',
                  width: 58,
                  height: 58,
                ),
              ),
            ),
            
            // Glove - bottom center
            Positioned(
              left: 140,
              bottom: 140 + (8 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.25,
                child: Image.asset(
                  'assets/images/glove.png',
                  width: 68,
                  height: 68,
                ),
              ),
            ),
            
            // Glove duplicate - top center-right
            Positioned(
              right: 80,
              top: 150 + (9 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.3,
                child: Image.asset(
                  'assets/images/glove.png',
                  width: 52,
                  height: 52,
                ),
              ),
            ),
            
            // Shopping cart - bottom right corner
            Positioned(
              right: 5,
              bottom: 140 + (10 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.1,
                child: Image.asset(
                  'assets/images/shopping_cart.png',
                  width: 70,
                  height: 70,
                ),
              ),
            ),
            
            // Star - scattered around more
            Positioned(
              left: 80,
              top: 160 + (5 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.5,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            
            Positioned(
              right: 80,
              bottom: 250 + (7 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.3,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 44,
                  height: 44,
                ),
              ),
            ),
            
            // Additional stars
            Positioned(
              right: 120,
              top: 240 + (6 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.4,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 36,
                  height: 36,
                ),
              ),
            ),
            
            Positioned(
              left: 160,
              bottom: 300 + (8 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.2,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 38,
                  height: 38,
                ),
              ),
            ),
            
            Positioned(
              right: 160,
              top: 180 + (4 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.6,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 32,
                  height: 32,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}