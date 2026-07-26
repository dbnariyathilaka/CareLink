import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

// ─────────────────────────────────────────────────────────────
//  Messages List Screen  (Patient)
//  Messaging unlocks once a real booking exists — no booking
//  infrastructure exists yet (Phase 2), so this is always empty today.
// ─────────────────────────────────────────────────────────────
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const Color _azure11 = AppTheme.surfaceColor;
  static const Color _azure17 = AppTheme.cardColor;
  static const Color _azure47 = Color(0xFF64748B);
  static const Color _grey98 = AppTheme.textPrimary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Expanded(
              child: EmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                message:
                    'No conversations yet — messaging unlocks once you have a '
                    'confirmed booking.',
              ),
            ),
            _buildInfoBar(),
          ],
        ),
      ),
    );
  }

  // ── Page header ───────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Messages',
            style: TextStyle(
              color: _grey98,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom info bar ───────────────────────────────────────
  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _azure17, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 14),
      child: Row(
        children: const [
          Icon(Icons.lock_outline_rounded, color: _azure47, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Messages are only available for confirmed bookings.',
              style: TextStyle(
                color: _azure47,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
