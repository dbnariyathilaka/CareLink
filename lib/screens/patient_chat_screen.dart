import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Chat Screen  (Chat Thread — Patient view)
//  No conversation data exists until real bookings + messaging
//  infrastructure ships (Phase 2).
// ─────────────────────────────────────────────────────────────
class PatientChatScreen extends StatelessWidget {
  const PatientChatScreen({super.key});

  static const Color _azure11 = AppTheme.surfaceColor;
  static const Color _grey98 = AppTheme.textPrimary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 13),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Chat',
                    style: TextStyle(
                      color: _grey98,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                message:
                    'No conversation yet — messaging unlocks once you have a '
                    'confirmed booking.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
