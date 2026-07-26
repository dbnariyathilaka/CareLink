import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Earnings Screen
//  No booking/payment infrastructure exists yet (Phase 2), so
//  there is nothing real to show here today.
// ─────────────────────────────────────────────────────────────
class CaregiverEarningsScreen extends StatelessWidget {
  const CaregiverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Earnings',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.payments_outlined,
                message: 'Nothing here yet — earnings will appear once you '
                    'complete paid bookings.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
