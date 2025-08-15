import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'payments_screen.dart';
import 'payment_page.dart';
import 'shared_bottom_nav.dart'; // Import the shared bottom nav

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab Bar
            _buildTabBar(),
            
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
                child: _selectedTabIndex == 0 
                    ? _buildOverviewContent() 
                    : _buildContractsContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPage(selectedItems: ['New Expense']),
            ),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(
          Icons.add,
          color: AppColors.white,
          size: 32,
        ),
      ),
      // Use the shared bottom navigation with index 2 for Bills
      bottomNavigationBar: const SharedBottomNav(currentIndex: 2),
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
          // Decorative icons
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

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 
                      ? AppColors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Overview',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedTabIndex == 0 
                          ? AppColors.white 
                          : AppColors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 
                      ? AppColors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Contracts',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedTabIndex == 1 
                          ? AppColors.white 
                          : AppColors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent() {
    return Column(
      children: [
        // You're owed card
        Container(
          width: double.infinity,
           margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "You're owed",
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '\$0.00',
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        
        // Bills list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildBillItem(
                date: 'Aug\n12',
                title: 'Some Groceries',
                subtitle: 'you owe 12.50',
                amount: '\$50.00',
                amountSubtitle: 'Bob paid',
                hasReceipt: false,
              ),
              _buildBillItem(
                date: 'Aug\n12',
                title: 'Some Toilet stuff',
                subtitle: 'you owe 11.75',
                amount: '\$50.00',
                amountSubtitle: 'Bob paid',
                hasReceipt: false,
              ),
              _buildBillItem(
                date: 'Aug\n12',
                title: 'Oranges, Oats, Clementines',
                subtitle: 'you owe 11.75',
                amount: '\$50.00',
                amountSubtitle: 'Bob paid',
                hasReceipt: true,
              ),
              _buildBillItem(
                date: 'Aug\n12',
                title: 'Water bill',
                subtitle: 'you owe 11.75',
                amount: '\$50.00',
                amountSubtitle: 'Bob paid',
                hasReceipt: false,
              ),
            ],
          ),
        ),
        
        // All Payments button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/money.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'All Payments',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContractsContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildContractItem(
          title: 'Water Bill',
          subtitle: 'Monthly recurring',
          amount: '\$50.00',
          icon: '💧',
          nextDue: 'Next due: Aug 30',
        ),
        _buildContractItem(
          title: 'Gas Bill',
          subtitle: 'Monthly recurring',
          amount: '\$35.00',
          icon: '🔥',
          nextDue: 'Next due: Sep 5',
        ),
        _buildContractItem(
          title: 'Rent',
          subtitle: 'Monthly recurring',
          amount: '\$1200.00',
          icon: '🏠',
          nextDue: 'Next due: Sep 1',
        ),
      ],
    );
  }

  Widget _buildBillItem({
    required String date,
    required String title,
    required String subtitle,
    required String amount,
    required String amountSubtitle,
    required bool hasReceipt,
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
                if (hasReceipt)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Receipt attached',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
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
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF666666),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildContractItem({
    required String title,
    required String subtitle,
    required String amount,
    required String icon,
    required String nextDue,
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
                Text(
                  nextDue,
                  style: const TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF666666),
            size: 16,
          ),
        ],
      ),
    );
  }
}