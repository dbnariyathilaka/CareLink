import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ForgotPasswordStep3Screen extends StatelessWidget {
  const ForgotPasswordStep3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Spacer to center the content
            const Spacer(),

            // Large green checkmark with opacity background circle
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: AppTheme.primaryGreen,
                        size: 76,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Password reset!',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your password has been updated. Use your new password the next time you log in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom action button: Back to log in
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Back to log in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.bottleGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
