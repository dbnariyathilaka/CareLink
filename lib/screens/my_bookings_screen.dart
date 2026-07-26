import 'package:flutter/material.dart';
import '../app_state.dart';

// ─────────────────────────────────────────────────────────────
//  My Bookings Screen  (Patient)
//  No booking-creation flow writes to Firestore yet (Phase 2),
//  so this always shows the honest empty state today.
// ─────────────────────────────────────────────────────────────
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 12, 22, 0),
              child: Text(
                'My bookings',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            Expanded(child: _buildEmptyState(context)),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ── Empty state: no bookings at all ───────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF22C55E),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No bookings yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              "You haven't sent any care requests yet. Search for a caregiver "
              "and send your first request.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                height: 1.6,
              ),
            ),
            const SizedBox(height: 26),
            Material(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pushNamed(context, '/search'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                  child: Text(
                    'Find a caregiver',
                    style: TextStyle(
                      color: Color(0xFF06240F),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
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

  // ── Bottom nav (matches dashboard) ────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.search_rounded, label: 'Search'),
      (icon: null, label: 'Match'),
      (icon: Icons.calendar_month_rounded, label: 'Bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
    ];
    const selectedIndex = 3; // Bookings tab always active on this screen

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          if (index == 2) {
            return GestureDetector(
              onTap: () {
                if (AppState.hasActiveMatch.value) {
                  Navigator.pushNamed(context, '/advanced-match-results');
                } else {
                  Navigator.pushNamed(context, '/advanced-match-send-request');
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF01D3A8), // Caribbean Green
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F172A), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF01D3A8).withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.diversity_3_rounded,
                      color: Color(0xFF06240F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Match',
                    style: TextStyle(
                      color: Color(0xFF01D3A8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            );
          }

          final color = isSelected
              ? const Color(0xFF22C55E)
              : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/patient-dashboard'));
              } else if (index == 1) {
                Navigator.pushNamed(context, '/search');
              } else if (index == 4) {
                Navigator.pushNamed(context, '/notifications');
              }
            },
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
