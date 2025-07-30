import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;


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
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tthe top part
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
                  //those icpns
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
                  
                  // logo brought down
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
          
       
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'Get up and running',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'First name',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _firstNameController,
                        style: const TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 18,
                          color: AppColors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: '',
                          hintStyle: const TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            color: Color(0xFF999999),
                          ),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primaryBlue),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: Icon(
                            Icons.person_outline,
                            color: Color(0xFF999999),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Email Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 18,
                          color: AppColors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: '',
                          hintStyle: const TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            color: Color(0xFF999999),
                          ),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primaryBlue),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: Icon(
                            Icons.email_outlined,
                            color: Color(0xFF999999),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Password side
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),

                     TextField(
  controller: _passwordController,
  obscureText: _obscurePassword,
  style: const TextStyle(
    fontFamily: AppFonts.darkerGrotesque,
    fontSize: 18,
    color: AppColors.black,
  ),
  decoration: InputDecoration(
    hintText: '',
    hintStyle: const TextStyle(
      fontFamily: AppFonts.darkerGrotesque,
      color: Color(0xFF999999),
    ),
    border: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.primaryBlue),
    ),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
    suffixIcon: IconButton(
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: const Color(0xFF999999),
        size: 22,
      ),
      onPressed: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
    ),
  ),
),

                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  
                
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        // later impl of sign up
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Sign In Link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 16,
                            color: Color(0xFF666666),
                          ),
                          children: [
                            TextSpan(text: 'Got an account? '),
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
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
}