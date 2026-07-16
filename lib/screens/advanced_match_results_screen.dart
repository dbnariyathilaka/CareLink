import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Advanced Match Results Screen  — "Your top 5 matches"
//  Figma: P-17v2 · Top 5 Matches (v2, teal) — final result  node 282-13630
//
//  Navigation rules (Match button in bottom nav):
//  • If hasActiveMatch == false  → go to /advanced-match-send-request (wizard)
//  • If hasActiveMatch == true   → come back here
//  • If already on this screen  → show rematch confirmation dialog
//    - Yes → clear state, go to /advanced-match-send-request
//    - No  → stay here
// ─────────────────────────────────────────────────────────────────────────────
class AdvancedMatchResultsScreen extends StatefulWidget {
  const AdvancedMatchResultsScreen({super.key});

  @override
  State<AdvancedMatchResultsScreen> createState() =>
      _AdvancedMatchResultsScreenState();
}

class _AdvancedMatchResultsScreenState
    extends State<AdvancedMatchResultsScreen> {
  // Popup state
  bool _showRequestPopup = false;
  String _requestedCaregiver = '';
  Timer? _popupTimer;

  @override
  void dispose() {
    _popupTimer?.cancel();
    super.dispose();
  }

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _keppel      = Color(0xFF3DB498);
  static const Color _bottleGreen = Color(0xFF06291F);
  static const Color _azure11     = Color(0xFF0F172A);
  static const Color _azure17     = Color(0xFF1E293B);
  static const Color _azure27     = Color(0xFF334155);
  static const Color _azure47     = Color(0xFF64748B);
  static const Color _azure65     = Color(0xFF94A3B8);
  static const Color _grey98      = Color(0xFFF8FAFC);
  static const Color _orange      = Color(0xFFF97316); // "Best Match" badge
  static const Color _amber       = Color(0xFFF59E0B); // star

  static const Color _tealTop     = Color(0xFF1A7A6E);
  static const Color _tealMid     = Color(0xFF0D4F47);

  // ── Caregiver data (simulated top 5) ──────────────────────────────────────
  static const _caregivers = [
    _CaregiverData(
      rank: 1,
      initials: 'AF',
      name: 'Alice Fernando',
      detail: 'Elder care · 7 yrs exp · 2.3 km',
      rating: '4.8',
      statusLabel: 'Available now',
      statusAvailable: true,
      matchPct: 96,
      avatarColor: Color(0xFF22C55E),
      initialsColor: Color(0xFF06291F),
      isBestMatch: true,
    ),
    _CaregiverData(
      rank: 2,
      initials: 'BK',
      name: 'Brian Kumara',
      detail: 'Elder care · 5 yrs exp · 3.1 km',
      rating: '4.7',
      statusLabel: 'Available',
      statusAvailable: true,
      matchPct: 91,
      avatarColor: Color(0xFF058CD0),
      initialsColor: Colors.white,
      isBestMatch: false,
    ),
    _CaregiverData(
      rank: 3,
      initials: 'SP',
      name: 'Sanduni Perera',
      detail: 'Post-surgery · 6 yrs exp · 4.0 km',
      rating: '4.9',
      statusLabel: 'Available',
      statusAvailable: true,
      matchPct: 88,
      avatarColor: Color(0xFFF59E0B),
      initialsColor: Color(0xFF1A0F00),
      isBestMatch: false,
    ),
    _CaregiverData(
      rank: 4,
      initials: 'RJ',
      name: 'Ruwan Jayasuriya',
      detail: 'Elder care · 4 yrs exp · 5.6 km',
      rating: '4.6',
      statusLabel: 'Busy',
      statusAvailable: false,
      matchPct: 84,
      avatarColor: Color(0xFF8B5CF6),
      initialsColor: Colors.white,
      isBestMatch: false,
    ),
    _CaregiverData(
      rank: 5,
      initials: 'NK',
      name: 'Nimal Karunaratne',
      detail: 'Dementia care · 9 yrs exp · 6.2 km',
      rating: '4.5',
      statusLabel: 'Available',
      statusAvailable: true,
      matchPct: 79,
      avatarColor: Color(0xFFEF4444),
      initialsColor: Colors.white,
      isBestMatch: false,
    ),
  ];

  // ── Rematch confirmation dialog ────────────────────────────────────────────
  void _showRematchDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: _azure17,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _orange.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.sync_rounded, color: _orange, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Start a Rematch?',
                style: TextStyle(
                  color: _grey98,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'If you proceed, your current top 5 matches will be lost and cannot be recovered. You\'ll be taken back to the matching wizard to start fresh.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _azure65,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _grey98,
                        side: const BorderSide(color: _azure27),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Yes, rematch
                  Expanded(
                    child: Material(
                      color: _orange,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.pop(ctx);
                          // Clear active match state
                          AppState.hasActiveMatch.value = false;
                          AppState.lastMatchArgs = null;
                          // Navigate to advanced match wizard step 1
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/advanced-match-send-request',
                            (route) =>
                                route.settings.name == '/patient-dashboard',
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Yes, rematch',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Stack(
        children: [
          Column(
            children: [
              // Teal hero header
              _buildHeroHeader(),

              // Scrollable list
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: _caregivers
                        .map((c) => _buildCaregiverCard(c))
                        .toList(),
                  ),
                ),
              ),

              // Bottom nav
              _buildBottomNav(),
            ],
          ),
          if (_showRequestPopup)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() {
                    _showRequestPopup = false;
                  });
                  _popupTimer?.cancel();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          if (_showRequestPopup)
            _buildRequestSuccessPopup(),
        ],
      ),
    );
  }

  // ── Hero header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
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
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'Your top 5 matches',
                style: TextStyle(
                  color: _grey98,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ranked by care type, schedule, location & qualifications',
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

  // ── Caregiver card ─────────────────────────────────────────────────────────
  Widget _buildCaregiverCard(_CaregiverData c) {
    final isBest = c.isBestMatch;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBest ? _orange : _azure27,
          width: isBest ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── "Best Match" badge row (rank 1 only) ──────────────────────────
          if (isBest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'BEST MATCH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Main card content ──────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14, isBest ? 10 : 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank number (non-best)
                if (!isBest)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 4),
                    child: Text(
                      '${c.rank}',
                      style: const TextStyle(
                        color: _azure47,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: c.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      c.initials,
                      style: TextStyle(
                        color: c.initialsColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + detail + rating/status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          color: _grey98,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        c.detail,
                        style: const TextStyle(
                          color: _azure65,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: _amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            c.rating,
                            style: const TextStyle(
                              color: _grey98,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.statusAvailable
                                  ? _keppel
                                  : _azure47,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            c.statusLabel,
                            style: TextStyle(
                              color: c.statusAvailable ? _keppel : _azure47,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Match percentage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${c.matchPct}%',
                      style: TextStyle(
                        color: isBest ? _orange : _keppel,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Mini progress bar
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _azure27,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: c.matchPct / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBest ? _orange : _keppel,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Action buttons ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                // Request button
                Expanded(
                  child: Material(
                    color: isBest ? _orange : _keppel,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _showRequestPopup = true;
                          _requestedCaregiver = c.name;
                        });
                        _popupTimer?.cancel();
                        _popupTimer = Timer(const Duration(seconds: 5), () {
                          if (mounted) {
                            setState(() {
                              _showRequestPopup = false;
                            });
                          }
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 11),
                        child: Text(
                          'Request',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Profile button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _grey98,
                      side: const BorderSide(color: _azure27),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/caregiver-profile',
                        arguments: {'caregiverName': c.name},
                      );
                    },
                    child: const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
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

          // Centre Match FAB — already on results → show rematch dialog
          GestureDetector(
            onTap: _showRematchDialog,
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

  Widget _buildRequestSuccessPopup() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 90,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF3DB498), // Keppel cyan
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Request Sent!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_requestedCaregiver has been requested.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _CaregiverData {
  final int rank;
  final String initials;
  final String name;
  final String detail;
  final String rating;
  final String statusLabel;
  final bool statusAvailable;
  final int matchPct;
  final Color avatarColor;
  final Color initialsColor;
  final bool isBestMatch;

  const _CaregiverData({
    required this.rank,
    required this.initials,
    required this.name,
    required this.detail,
    required this.rating,
    required this.statusLabel,
    required this.statusAvailable,
    required this.matchPct,
    required this.avatarColor,
    required this.initialsColor,
    required this.isBestMatch,
  });
}
