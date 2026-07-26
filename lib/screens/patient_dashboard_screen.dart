import 'dart:io';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() =>
      _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  String _userName = 'there';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final profile = await AuthService.getUserProfile(user.uid);
    final name = profile?['name'] as String?;
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _userName = name);
    }
  }

  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color borderDark = Color(0xFF033724);
  static const Color emergencyRed = Color(0xFF9E0606);
  static const Color statCardBg = Color(0xFFE9D3B3);
  static const Color matchScorePurple = Color(0xFF3D1678);
  static const Color deltaRedBg = Color.fromRGBO(158, 6, 6, 0.3);
  static const Color deltaRedText = Color(0xFF9E0606);
  static const Color deltaTealBg = Color.fromRGBO(6, 155, 158, 0.3);
  static const Color deltaTealText = Color(0xFF225753);
  static const Color matchCardBg = Color(0xFFD1C8B4);
  static const Color matchBadgeBg = Color.fromRGBO(64, 64, 6, 0.3);
  static const Color matchBadgeText = Color(0xFF33440A);
  static const Color navHomeLabel = Color(0xFFFEE269);
  static const Color navMatchLabel = Color(0xFFFFA722);
  static const Color starGold = Color(0xFFF5B301);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEmergencyBanner(),
                    const SizedBox(height: 14),
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildSectionHeader(),
                    const SizedBox(height: 14),
                    _buildMatchCard(
                      initials: 'RF',
                      name: 'Rayan Fernando',
                      matchScore: '95%',
                      careType: 'Elder care',
                      experience: '7 yrs exp',
                      distance: '2.5 km',
                      rating: '4.8',
                      available: true,
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: const BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Good morning',
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFC940), size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _userName,
                style: const TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pushNamed(context, '/patient-profile'),
            child: ValueListenableBuilder<String?>(
              valueListenable: AppState.profileImagePath,
              builder: (_, imagePath, _) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: imagePath != null
                      ? ClipOval(
                          child: Image.file(
                            File(imagePath),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Text(
                            'NA',
                            style: TextStyle(
                              fontFamily: 'Quattrocento Sans',
                              color: darkGreen,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/emergency'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: emergencyRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency - Find a caregiver now',
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Top 3 nearest available caregivers',
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _statCard(
              label: 'Your match score',
              value: '85%',
              valueColor: matchScorePurple,
              valueFontSize: 35,
              deltaText: '↓2.1%',
              deltaBg: deltaRedBg,
              deltaTextColor: deltaRedText,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: _statCard(
              label: 'Available now',
              value: '12',
              valueColor: darkGreen,
              valueFontSize: 30,
              caption: 'Near you',
              deltaText: '↑2.1%',
              deltaBg: deltaTealBg,
              deltaTextColor: deltaTealText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color valueColor,
    required double valueFontSize,
    required String deltaText,
    required Color deltaBg,
    required Color deltaTextColor,
    String? caption,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      decoration: BoxDecoration(
        color: statCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Quattrocento Sans',
              color: darkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Quattrocento Sans',
              color: valueColor,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption != null)
            Text(
              caption,
              style: const TextStyle(
                fontFamily: 'Quattrocento Sans',
                color: darkGreen,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: deltaBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                deltaText,
                style: TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: deltaTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Top matches for you',
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: darkGreen,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/search'),
          child: const Text(
            'See all',
            style: TextStyle(
              fontFamily: 'Quattrocento Sans',
              color: darkGreen,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard({
    required String initials,
    required String name,
    required String matchScore,
    required String careType,
    required String experience,
    required String distance,
    required String rating,
    required bool available,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: matchCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF3E9D2),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: darkGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_rounded, color: Colors.black, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Quattrocento Sans',
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: matchBadgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            matchScore,
                            style: const TextStyle(
                              fontFamily: 'Quattrocento Sans',
                              color: matchBadgeText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          careType,
                          style: const TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          experience,
                          style: const TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: starGold, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: available ? const Color(0xFF22C55E) : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          available ? 'Available' : 'Unavailable',
                          style: const TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: darkGreen,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pushNamed(context, '/send-request'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      child: Text(
                        'Request',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pushNamed(context, '/caregiver-profile'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderDark),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: borderDark,
                          fontSize: 15,
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
    );
  }

  Widget _buildBottomBar() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        _buildBottomNav(),
        Positioned(
          top: -22,
          child: _buildMatchFab(),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (icon: Icons.home_rounded, label: 'Home', route: null),
      (icon: Icons.search_rounded, label: 'Search', route: '/search'),
      (icon: null, label: 'Match', route: null),
      (icon: Icons.calendar_month_outlined, label: 'Booking', route: '/my-bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Notification', route: '/notifications'),
    ];
    return Container(
      width: double.infinity,
      height: 67,
      color: darkGreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];

          if (index == 2) {
            // Empty slot reserved for the floating Match button; only the
            // label is drawn here so it sits centered beneath the FAB.
            return const SizedBox(
              width: 60,
              child: Padding(
                padding: EdgeInsets.only(top: 41),
                child: Text(
                  'Match',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: navMatchLabel,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }

          final color = index == 0 ? navHomeLabel : Colors.white;
          return GestureDetector(
            onTap: item.route != null
                ? () => Navigator.pushNamed(context, item.route!)
                : null,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: color, size: 25),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _buildMatchFab() {
    return GestureDetector(
      onTap: () {
        if (AppState.hasActiveMatch.value) {
          Navigator.pushNamed(context, '/advanced-match-results');
        } else {
          Navigator.pushNamed(context, '/advanced-match-send-request');
        }
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: darkGreen,
          shape: BoxShape.circle,
          border: Border.all(color: bgCream, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.crop_free_rounded,
          color: navMatchLabel,
          size: 26,
        ),
      ),
    );
  }
}
