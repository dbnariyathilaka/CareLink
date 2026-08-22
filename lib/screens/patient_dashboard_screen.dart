import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/matching_service.dart';
import '../services/patient_service.dart';
import '../services/profile_gate.dart';
import '../widgets/empty_state.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';
import 'emergency_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() =>
      _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _userName = 'there';
  int? _caregiverCount;

  bool _loadingTopMatches = true;
  List<MatchResult> _topMatches = const [];

  late final AnimationController _matchIconController;
  late final Animation<double> _matchIconRotation;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _loadUserName();
    _loadOwnPhoto();
    _loadCaregiverCount();
    _loadTopMatches();
    // 2s stopped, then a full turn that gradually accelerates (3s) and
    // gradually decelerates (3s) — an 8s cycle that then repeats.
    _matchIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _matchIconRotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 2),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
    ]).animate(_matchIconController);
  }

  @override
  void dispose() {
    _matchIconController.dispose();
    super.dispose();
  }

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  IconData get _greetingIcon {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_twilight_rounded; // sunrise
    if (hour < 17) return Icons.wb_sunny_rounded; // full sun
    if (hour < 21) return Icons.nights_stay_rounded; // dusk
    return Icons.bedtime_rounded; // night
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

  Future<void> _loadOwnPhoto() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final profile = await PatientService.getPatientProfile(user.uid);
    AppState.hydratePatientPhoto(profile?['photoUrl'] as String?);
  }

  Future<void> _loadCaregiverCount() async {
    final results = await CaregiverService.searchCaregivers();
    if (mounted) {
      setState(() => _caregiverCount = results.length);
    }
  }

  // The onboarding-preview occasion: scores every caregiver in the pool
  // against only what onboarding collected — care type/skill, preferred
  // gender, city, work nature (careLevel) — with no eligibility gate, since
  // this is a passive "how would you rank" view rather than a committed
  // request. Skipped entirely for an account with no patientProfiles doc
  // yet — there's nothing to score against.
  Future<void> _loadTopMatches() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingTopMatches = false);
      return;
    }
    final profile = await PatientService.getPatientProfile(uid);
    if (profile == null) {
      if (mounted) setState(() => _loadingTopMatches = false);
      return;
    }

    final matchContext = MatchContext(patientProfile: profile);
    final caregivers = await CaregiverService.searchCaregivers();
    final ranked = MatchingService.rankCaregivers(
      caregivers: caregivers,
      context: matchContext,
      profile: MatchProfile.onboardingPreview,
    );

    if (!mounted) return;
    setState(() {
      _topMatches = ranked.take(3).toList();
      _loadingTopMatches = false;
    });
  }

  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color emergencyRed = Color(0xFF9E0606);
  static const Color statCardBg = Color(0xFFE9D3B3);
  static const Color navHomeLabel = Color(0xFFFEE269);
  static const Color navMatchLabel = Color(0xFFFFA722);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: Column(
        children: [
          _buildHeader(context),
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
                  _buildTopMatchesSection(),
                  const SizedBox(height: 20),
                  _buildSectionHeader(),
                  const SizedBox(height: 14),
                  _buildFindCaregiverPrompt(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // Paints full-bleed behind the transparent status bar (edge-to-edge mode),
  // so the header's own top padding — not an outer SafeArea — keeps the
  // greeting clear of the status bar icons.
  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(22, topInset + 16, 22, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _greetingText,
                      style: const TextStyle(
                        fontFamily: 'Quattrocento Sans',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(_greetingIcon, color: const Color(0xFFFFC940), size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _userName,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                          child: RemoteOrLocalImage(
                            source: imagePath,
                            width: 50,
                            height: 50,
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

  void _showEmergencySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: EmergencyScreen(),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return GestureDetector(
      onTap: _showEmergencySheet,
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

  // Shared by the Match FAB and the "See all" link on the top-matches
  // section: resume an active match if one exists, otherwise gate on
  // profile completeness and start a fresh advanced-match request.
  Future<void> _startOrViewMatch() async {
    if (AppState.hasActiveMatch.value) {
      Navigator.pushNamed(context, '/advanced-match-results');
      return;
    }
    if (!await ensurePatientProfileComplete(context)) return;
    if (!mounted) return;
    Navigator.pushNamed(context, '/advanced-match-send-request');
  }

  String _initialsOf(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _buildTopMatchesSection() {
    if (_loadingTopMatches) return const SizedBox.shrink();
    if (_topMatches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              onTap: _startOrViewMatch,
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
        ),
        const SizedBox(height: 10),
        ..._topMatches.map(_buildTopMatchRow),
      ],
    );
  }

  Widget _buildTopMatchRow(MatchResult m) {
    final uid = m.caregiver['uid'] as String?;
    final name = (m.caregiver['name'] as String?) ?? 'Caregiver';
    final years = m.caregiver['yearsExperience'];
    final subtitle = years != null ? '$years yrs experience' : 'Caregiver';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/caregiver-profile',
        arguments: {'caregiverId': uid},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: darkGreen),
              alignment: Alignment.center,
              child: Text(
                _initialsOf(name),
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: darkGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color(0xFF5C5A5A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${m.matchPercent.round()}%',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final bestMatch = _topMatches.isNotEmpty ? _topMatches.first : null;
    return GestureDetector(
      onTap: _startOrViewMatch,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your best match',
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: darkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadingTopMatches || bestMatch == null
                      ? '—'
                      : '${bestMatch.matchPercent.round()}%',
                  style: const TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: darkGreen,
                    fontSize: 35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Icon(Icons.workspace_premium_rounded, color: darkGreen, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Find a caregiver',
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

  Widget _buildFindCaregiverPrompt() {
    if (_caregiverCount == 0) {
      return const EmptyState(
        icon: Icons.person_search_rounded,
        message: 'No caregivers have registered yet — check back soon.',
      );
    }
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/search'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: darkGreen, size: 26),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Search our registered caregivers to find the right fit for you.',
                style: TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: darkGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: darkGreen, size: 22),
          ],
        ),
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
      color: darkGreen,
      // top:false — the system nav/gesture bar inset only applies at the
      // bottom here; without this the OS nav buttons overlap these icons.
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 67,
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
        ),
      ),
    );
  }

  Widget _buildMatchFab() {
    return GestureDetector(
      onTap: _startOrViewMatch,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: RotationTransition(
          turns: _matchIconRotation,
          child: SvgPicture.asset(
            'assets/images/match_target_icon.svg',
            width: 65,
            height: 65,
          ),
        ),
      ),
    );
  }
}
