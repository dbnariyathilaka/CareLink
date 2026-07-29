import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Add Review Screen
//  Reviews only make sense after a completed, real booking — and booking
//  infrastructure doesn't exist yet (Phase 2). Rather than show a fake review
//  form for a hardcoded caregiver, this screen honestly says reviews aren't
//  available yet.
// ─────────────────────────────────────────────────────────────────────────────
class AddReviewScreen extends StatelessWidget {
  const AddReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(Brightness.light);
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTitleRow(context),
            const Expanded(
              child: EmptyState(
                icon: Icons.rate_review_outlined,
                message:
                    'Reviews will be available once booking and completed-care '
                    'tracking are set up. There\'s nothing to review yet.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Title row ─────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
          ),
          const SizedBox(width: 10),
          const Text(
            'Leave a review',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
