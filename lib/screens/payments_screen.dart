import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: From me, 2: With me

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Payments header card
                    _buildPaymentsHeaderCard(),
                    
                    // Filter buttons
                    _buildFilterButtons(),
                    
                    // Payments list
                    Expanded(
                      child: _buildPaymentsList(),
                    ),
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
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Image.asset(
            'assets/images/money.png',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Bills',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          // Floating money icons (decorative)
          Stack(
            children: [
              Image.asset('assets/images/money.png', width: 20, height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
     color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payments',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              TextButton(
                onPressed: _exportPayments,
                child: const Text(
                  'Export',
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
          const SizedBox(height: 16),
          // Decorative icons and text
          Stack(
            children: [
              Container(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/money.png', width: 30, height: 30),
                    const SizedBox(width: 8),
                    const Text(
                      '💰',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Image.asset('assets/images/star.png', width: 24, height: 24),
                    const SizedBox(width: 16),
                    Image.asset('assets/images/money.png', width: 32, height: 32),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'All payments made',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton('All', 0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton('From me', 1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton('With me', 2),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title, int index) {
    final isSelected = _selectedFilterIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPaymentItem(
          name: 'Ola',
          date: 'Aug 5',
          amount: '\$22.33',
          avatar: 'avatar_1.png',
        ),
        _buildPaymentItem(
          name: 'Kanyin',
          date: 'July 15',
          amount: '\$18.64',
          avatar: 'avatar_2.png',
        ),
        _buildPaymentItem(
          name: 'Sade',
          date: 'July 19',
          amount: '\$50.00',
          subtitle: 'Bob paid',
          avatar: 'avatar_3.png',
        ),
        _buildPaymentItem(
          name: 'Sade',
          date: 'July 19',
          amount: '\$50.00',
          subtitle: 'Bob paid',
          avatar: 'avatar_4.png',
        ),
        _buildPaymentItem(
          name: 'Sade',
          date: 'July 19',
          amount: '\$50.00',
          subtitle: 'Bob paid',
          avatar: 'avatar_5.png',
        ),
      ],
    );
  }

  Widget _buildPaymentItem({
    required String name,
    required String date,
    required String amount,
    required String avatar,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                image: AssetImage('assets/images/$avatar'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  date,
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
              if (subtitle != null)
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
        ],
      ),
    );
  }

  void _exportPayments() {
    // TODO: Implement PDF export functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Export Payments',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Export payments as PDF?',
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppFonts.darkerGrotesque,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual PDF export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'PDF export feature coming soon!',
                    style: TextStyle(fontFamily: AppFonts.darkerGrotesque),
                  ),
                ),
              );
            },
            child: const Text(
              'Export',
              style: TextStyle(
                fontFamily: AppFonts.darkerGrotesque,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            _buildNavItem(Icons.home, "Home", 0, false),
            _buildNavItem(Icons.shopping_bag, "Shopping", 1, false),
            _buildNavItem(Icons.attach_money, "Bills", 2, true),
            _buildNavItem(Icons.chat_bubble_outline, "Chat", 3, false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isSelected) {
    return Column(
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
    );
  }
}