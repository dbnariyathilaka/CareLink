import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Advanced Match Results Screen
//  The smart-matching algorithm isn't built yet — this screen honestly says
//  so instead of showing a fabricated ranked list, and points the patient to
//  Search in the meantime. The wizard entry point (Match FAB) stays live.
// ─────────────────────────────────────────────────────────────────────────────
class AdvancedMatchResultsScreen extends StatelessWidget {
  const AdvancedMatchResultsScreen({super.key});

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _keppel      = Color(0xFF3DB498);
  static const Color _bottleGreen = Color(0xFF06291F);
  static const Color _azure11     = Color(0xFF0F172A);
  static const Color _azure27     = Color(0xFF334155);
  static const Color _azure47     = Color(0xFF64748B);
  static const Color _grey98      = Color(0xFFF8FAFC);

  static const Color _tealTop = Color(0xFF1A7A6E);
  static const Color _tealMid = Color(0xFF0D4F47);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: EmptyState(
              icon: Icons.auto_awesome_outlined,
              message:
                  'Smart matching is still being built — we\'ll let you know '
                  'once it\'s ready. In the meantime, search for caregivers directly.',
              iconColor: _azure47,
              textColor: const Color(0xFF94A3B8),
              actionLabel: 'Search caregivers',
              onAction: () => Navigator.pushNamed(context, '/search'),
            ),
          ),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  // ── Hero header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_tealTop, _tealMid],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'Smart matching',
                style: TextStyle(
                  color: _grey98,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Automatic caregiver ranking is on its way',
                style: TextStyle(
                  color: _grey98,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: _azure11,
        border: Border(top: BorderSide(color: _azure27)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home_rounded, 'Home', onTap: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/patient-dashboard', (r) => false);
          }),
          _navItem(Icons.search_rounded, 'Search', onTap: () {
            Navigator.pushNamed(context, '/search');
          }),

          // Centre Match FAB — back to the wizard to try again
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/advanced-match-send-request');
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _keppel,
                    shape: BoxShape.circle,
                    border: Border.all(color: _azure11, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _keppel.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.diversity_3_rounded,
                    color: _bottleGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Match',
                  style: TextStyle(
                    color: _keppel,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          _navItem(Icons.calendar_month_rounded, 'Bookings', onTap: () {
            Navigator.pushNamed(context, '/my-bookings');
          }),
          _navItem(Icons.notifications_none_rounded, 'Alerts', onTap: () {
            Navigator.pushNamed(context, '/notifications');
          }),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _azure47, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: _azure47,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
