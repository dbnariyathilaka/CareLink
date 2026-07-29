import 'package:flutter/material.dart';
import '../services/caregiver_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  // Colours from Figma
  static const Color _redStart = Color(0xFFDC2626); // red/51
  static const Color _redEnd = Color(0xFFB91C1C);   // red/42
  static const Color _requestRed = Color(0xFFEF4444);

  bool _loading = true;
  List<Map<String, dynamic>> _caregivers = [];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    final results = await CaregiverService.searchCaregivers();
    if (mounted) {
      setState(() {
        _caregivers = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _requestRed),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBanner(),
                        const SizedBox(height: 14),
                        if (_caregivers.isEmpty)
                          const EmptyState(
                            icon: Icons.person_search_rounded,
                            message:
                                'No caregivers have registered yet — check back soon.',
                            iconColor: AppTheme.textSecondary,
                            textColor: AppTheme.textSecondary,
                          )
                        else
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
    );
  }

  // ── Red header ────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, 12 + statusBarHeight, 22, 20),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 2),
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
              'Registered caregivers you can contact directly for urgent care.',
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
  Widget _buildCaregiverCard(BuildContext context, Map<String, dynamic> c) {
    final uid = c['uid'] as String;
    final name = (c['name'] as String?)?.trim() ?? '';
    final initials = name.isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();
    final city = c['city'] as String?;
    final careTypes = (c['careTypes'] as List?)?.cast<String>() ?? [];
    final yearsExperience = c['yearsExperience'] as int?;
    final specialty = [
      if (careTypes.isNotEmpty) careTypes.join(', '),
      if (yearsExperience != null) '$yearsExperience yrs',
    ].join(' · ');

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
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22C55E), AppTheme.primaryGreenDark],
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.bottleGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Unnamed caregiver' : name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                if (specialty.isNotEmpty)
                  Text(
                    specialty,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (city != null && city.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    city,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Red Request button
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/send-request',
              arguments: {'caregiverId': uid},
            ),
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
}
