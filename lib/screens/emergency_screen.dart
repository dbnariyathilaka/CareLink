import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  // Colours from Figma
  static const Color _redStart = Color(0xFFDC2626); // red/51
  static const Color _redEnd = Color(0xFFB91C1C);   // red/42
  static const Color _requestRed = Color(0xFFEF4444);

  static const Color _rjAvatarStart = Color(0xFF0EA5E9); // azure/48
  static const Color _rjAvatarEnd = Color(0xFF0284C7);   // azure/39
  static const Color _nsAvatarColor = Color(0xFFF59E0B); // amber

  static const List<_CaregiverData> _caregivers = [
    _CaregiverData(
      initials: 'AF',
      avatarType: _AvatarType.greenGradient,
      name: 'Alice\nFernando',
      specialty: 'Elder care · 7 yrs',
      eta: '2.3 km · ETA 12 min',
    ),
    _CaregiverData(
      initials: 'RJ',
      avatarType: _AvatarType.blueGradient,
      name: 'Ravi\nJayasuriya',
      specialty: 'Post-surgery · 4 yrs',
      eta: '3.1 km · ETA 15 min',
    ),
    _CaregiverData(
      initials: 'NS',
      avatarType: _AvatarType.amber,
      name: 'Nadeesha\nSilva',
      specialty: 'Elder care · 9 yrs',
      eta: '4.6 km · ETA 18 min',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBanner(),
                    const SizedBox(height: 14),
                    ..._caregivers.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCaregiverCard(context, c),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Red header ────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_redStart, _redEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          // Close + title row
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✕ close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Find a caregiver now',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Active dot (wider)
              Container(
                width: 18,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── Status info banner ────────────────────────────────────
  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Red pill indicator
          Container(
            width: 7,
            height: 12,
            decoration: BoxDecoration(
              color: _requestRed,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Finding nearest available caregivers · top 3\nwithin 10 km · available right now',
              style: TextStyle(
                color: Color(0xFFCBD5E1), // azure/84
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Caregiver card ────────────────────────────────────────
  Widget _buildCaregiverCard(BuildContext context, _CaregiverData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          _buildAvatar(data),
          const SizedBox(width: 12),
          // Name + badge + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name (two lines)
                    Text(
                      data.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // "Available now" green pill
                    Container(
                      padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'Available\nnow',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  data.specialty,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  data.eta,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1), // azure/84 — slightly brighter than secondary
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Red Request button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/send-request'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: _requestRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Request',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(_CaregiverData data) {
    BoxDecoration decoration;
    Color textColor;

    switch (data.avatarType) {
      case _AvatarType.greenGradient:
        decoration = const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22C55E), AppTheme.primaryGreenDark],
          ),
        );
        textColor = AppTheme.bottleGreen;
        break;
      case _AvatarType.blueGradient:
        decoration = const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_rjAvatarStart, _rjAvatarEnd],
          ),
        );
        textColor = Colors.white;
        break;
      case _AvatarType.amber:
        decoration = const BoxDecoration(
          shape: BoxShape.circle,
          color: _nsAvatarColor,
        );
        textColor = Colors.white;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: decoration,
      child: Center(
        child: Text(
          data.initials,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Data helpers ──────────────────────────────────────────
enum _AvatarType { greenGradient, blueGradient, amber }

class _CaregiverData {
  final String initials;
  final _AvatarType avatarType;
  final String name;
  final String specialty;
  final String eta;

  const _CaregiverData({
    required this.initials,
    required this.avatarType,
    required this.name,
    required this.specialty,
    required this.eta,
  });
}
