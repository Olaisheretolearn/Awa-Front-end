import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../state/currency_store.dart';
import '../state/currency_store.dart';

class CurrencyPickerBottomSheet extends StatelessWidget {
  const CurrencyPickerBottomSheet({super.key});

  // A compact list (add more if you want literally all)
  static final _currencies = <(String, String)>[
    ('Argentine peso', 'ARS'),
    ('Australian Dollar', 'AUD'),
    ('Bolivian boliviano', 'BOB'),
    ('Canadian Dollar', 'CAD'),
    ('Euro', '€'),
    ('GB-Pound', '£'),
    ('Japanese Yen', '¥'),
    ('Nigerian Naira', '₦'),
    ('South African Rand', 'R'),
    ('Swiss Franc', 'CHF'),
    ('US - Dollars', '\$'),
  ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SafeArea(
      top: false,
      child: Container(
        height: h * 0.70,
        decoration: const BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Stack(
          children: [
            // coin badge
            Positioned(
              top: 16,
              left: 24,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset('assets/images/coin.png', fit: BoxFit.contain),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Currencies',
                      style: TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView.separated(
                      itemCount: _currencies.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE6E6E6)),
                      itemBuilder: (context, i) {
                        final (name, symbol) = _currencies[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: AppFonts.darkerGrotesque,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                          trailing: Text(
                            symbol,
                            style: const TextStyle(
                              fontFamily: AppFonts.darkerGrotesque,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          onTap: () async {
                            await CurrencyStore.set(symbol);
                            if (context.mounted) Navigator.pop(context, symbol);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
