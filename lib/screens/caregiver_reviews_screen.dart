import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Reviews Received Screen
//  Reviews only exist after real completed bookings, which
//  don't exist yet (Phase 2).
// ─────────────────────────────────────────────────────────────
class CaregiverReviewsScreen extends StatelessWidget {
  const CaregiverReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(Brightness.light);
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
                    'Reviews received',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.rate_review_outlined,
                message: 'No reviews yet.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
