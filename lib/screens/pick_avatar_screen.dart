import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'create_join_flat_screen.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _buttonFadeController;
  int? _selectedAvatarIndex;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _buttonFadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _floatingController.repeat();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _buttonFadeController.dispose();
    super.dispose();
  }

  void _selectAvatar(int index) {
    setState(() {
      _selectedAvatarIndex = index;
    });
    _buttonFadeController.forward();
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
              top: 40 + (8 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.2,
                child: Image.asset(
                  'assets/images/pizza.png',
                  width: 48,
                  height: 48,
                ),
              ),
            ),
            
            // Pizza slice - second position
            Positioned(
              right: 20,
              bottom: 80 + (6 * (_floatingController.value * 2 - 1).abs()),
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
              right: 30,
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
            
            // Money - second position
            Positioned(
              left: 30,
              bottom: 100 + (9 * (_floatingController.value * 2 - 1).abs()),
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
              top: 100 + (10 * (_floatingController.value * 2 - 1).abs()),
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
              top: 90 + (7 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.2,
                child: Image.asset(
                  'assets/images/spraybottle.png',
                  width: 50,
                  height: 50,
                ),
              ),
            ),
            
            // Gloves - bottom left
            Positioned(
              left: 60,
              bottom: 40 + (5 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.25,
                child: Image.asset(
                  'assets/images/glove.png',
                  width: 52,
                  height: 52,
                ),
              ),
            ),
            
            // Shopping cart - bottom right
            Positioned(
              right: 50,
              bottom: 50 + (8 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: -_floatingController.value * 0.1,
                child: Image.asset(
                  'assets/images/shopping_cart.png',
                  width: 54,
                  height: 54,
                ),
              ),
            ),
            
            // Stars scattered - original 3
            Positioned(
              left: 80,
              top: 60 + (4 * (_floatingController.value * 2 - 1).abs()),
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
              right: 80,
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
              left: 120,
              bottom: 60 + (7 * (_floatingController.value * 2 - 1).abs()),
              child: Transform.rotate(
                angle: _floatingController.value * 0.4,
                child: Image.asset(
                  'assets/images/star.png',
                  width: 26,
                  height: 26,
                ),
              ),
            ),
            
            // Additional stars - 3 more
            Positioned(
              left: 140,
              top: 80 + (5 * (_floatingController.value * 2 - 1).abs()),
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
              right: 120,
              bottom: 80 + (8 * (_floatingController.value * 2 - 1).abs()),
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
              left: 160,
              top: 120 + (6 * (_floatingController.value * 2 - 1).abs()),
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
      body: Column(
        children: [
          // Top blue section with floating icons and logo
          Expanded(
            flex: 2,
            child: Container(
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
              child: Stack(
                children: [
                  // Floating icons background
                  _buildFloatingIcons(),


                   Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
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
                  // Logo positioned lower in the blue area
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Text(
                        'awa',
                        style: TextStyle(
                          fontFamily: AppFonts.boulder,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          
          // Bottom white section with avatar selection
          Expanded(
            flex: 3,
            child: Container(
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Pick your vibe',
                      style: TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Avatar grid
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedAvatarIndex == index;
                          return GestureDetector(
                            onTap: () => _selectAvatar(index),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primaryBlue,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: AssetImage('assets/images/avatar_${index + 1}.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: AppColors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Continue button with fade animation
                    AnimatedBuilder(
                      animation: _buttonFadeController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _selectedAvatarIndex != null ? _buttonFadeController.value : 0.3,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _selectedAvatarIndex != null
                                  ? () {
                                      // Handle continue action
                                         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateJoinFlatScreen(),
          ),
        );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                disabledBackgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Yes, more like me',
                                style: TextStyle(
                                  fontFamily: AppFonts.darkerGrotesque,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}