import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class ExitAppGuard extends StatelessWidget {
  final Widget child;

  final bool rootOnly;

  const ExitAppGuard({super.key, required this.child, this.rootOnly = true});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: child,
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final canPop = Navigator.of(context).canPop();

  
    if (rootOnly && canPop) return true;

    final shouldExit = await showExitSheet(context);
    if (shouldExit == true) {
      if (Platform.isAndroid) {
        await SystemNavigator.pop();
      } else {
        Navigator.of(context).maybePop(); 
      }
      return true;
    }
    return false;
  }
}


Future<bool?> showExitSheet(BuildContext context) {
  HapticFeedback.selectionClick();

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (_) {
      final media = MediaQuery.of(context);
      final maxHeight = media.size.height * 0.40;

      return SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.exit_to_app, size: 28, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 16),
              const Text(
                'Exit Awa?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to exit the app?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Stay',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Exit app',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
