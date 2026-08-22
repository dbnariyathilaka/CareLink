import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../services/matching_service.dart';
import '../services/patient_service.dart';
import '../services/review_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/request_sent_dialog.dart';
import '../widgets/restart_match_dialog.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Advanced Match Results Screen  (Figma node 324-471)
//  Ranking is produced by MatchingService — a disclosed 7-criterion
//  weighted-sum score (skill match, availability, proximity, feedback,
//  references, experience, certification) with hard eligibility filtering
//  applied first (language, gender preference, certification-mandatory,
//  travel distance) and weight redistribution for caregivers whose
//  credential data is structurally absent, rather than scoring it as zero.
//  See lib/services/matching_service.dart for the full algorithm.
// ─────────────────────────────────────────────────────────────────────────────
class AdvancedMatchResultsScreen extends StatefulWidget {
  const AdvancedMatchResultsScreen({super.key});

  @override
  State<AdvancedMatchResultsScreen> createState() =>
      _AdvancedMatchResultsScreenState();
}

class _AdvancedMatchResultsScreenState
    extends State<AdvancedMatchResultsScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color headerGreenLight = Color(0xFF0E7A50);
  static const Color cardTan = Color(0xFFF1DDC2);
  static const Color cardBorderBrown = Color(0xFF885A1F);
  static const Color rankBadgeBg = Color(0xFFF2C2A4);
  static const Color rankBadgeBorder = Color(0xFF873C0A);
  static const Color rankBadgeText = Color(0xFF8F421F);
  static const Color requestBrown = Color(0xFF89755B);
  static const Color scoreBarTrack = Color(0xFF334155);
  static const Color scoreBarFill = Color(0xFFD87737);
  static const Color bestBorderRed = Color(0xFFFF3737);
  static const Color navMatchLabel = Color(0xFFFFA722);

  static const _avatarGradients = [
    [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    [Color(0xFFEF960A), Color(0xFFDF8007)],
    [Color(0xFF8451F0), Color(0xFF7434E0)],
    [Color(0xFF34A853), Color(0xFF1E7E3A)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
  ];

  bool _loading = true;
  List<MatchResult> _matches = const [];
  Map<String, dynamic> _bookingArgs = {};
  bool _startedLoading = false;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    // _loadMatches() is deliberately NOT called here: it needs
    // _bookingArgs, which didChangeDependencies below hasn't populated yet
    // at initState time (initState always runs first in the Flutter
    // lifecycle) — see the _startedLoading guard there.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _bookingArgs = Map<String, dynamic>.from(args);
    } else if (AppState.lastMatchArgs != null) {
      _bookingArgs = Map<String, dynamic>.from(AppState.lastMatchArgs!);
    }
    // didChangeDependencies can fire more than once; only kick off the
    // (expensive, Firestore-backed) match load the first time.
    if (!_startedLoading) {
      _startedLoading = true;
      _loadMatches();
    }
  }

  // Creates a booking request tied to this specific caregiver, reusing the
  // schedule/location details already collected earlier in the advanced
  // matching wizard — no need to ask the patient to re-enter them.
  Future<void> _sendRequest(MatchResult m) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final name = (m.caregiver['name'] as String?) ?? 'Caregiver';
    final careType = _bookingArgs['careType'] as String? ?? AppState.careType.value;
    final startDate = _bookingArgs['startDate'] as String? ?? '';
    final startTime = _bookingArgs['startTime'] as String? ?? '';
    final location = _bookingArgs['location'] as String? ?? AppState.careLocation.value;

    await BookingService.createBookingRequest(
      patientUid: uid,
      caregiverId: m.caregiver['uid'] as String?,
      caregiverName: name,
      careType: careType,
      startDate: startDate,
      startTime: startTime,
      endTime: _bookingArgs['endTime'] as String?,
      duration: _bookingArgs['duration'] as String?,
      endDate: _bookingArgs['endDate'] as String?,
      location: location,
      locationLat: _bookingArgs['lat'] as double?,
      locationLng: _bookingArgs['lng'] as double?,
      isAdvanced: true,
    );
    if (!mounted) return;
    showRequestSentDialog(context);
  }

  Future<void> _loadMatches() async {
    final uid = AuthService.currentUser?.uid;
    final patientProfile =
        uid != null ? await PatientService.getPatientProfile(uid) : null;

    // AppState holds the patient's standing care-requirement defaults;
    // patientProfile (when present) and _bookingArgs (this specific
    // request) each take precedence over it in MatchContext's getters, in
    // that order, so this only fills the gaps rather than overriding them.
    final effectiveProfile = <String, dynamic>{
      'careType': AppState.careType.value,
      'careLevel': AppState.careSchedule.value,
      'city': AppState.careLocation.value,
      'preferredCaregiverGender': AppState.preferredGender.value,
      ...?patientProfile,
    };

    final matchContext = MatchContext(
      patientProfile: effectiveProfile,
      requestArgs: _bookingArgs,
    );

    final caregivers = await CaregiverService.searchCaregivers();
    final eligible = caregivers
        .where((c) => MatchingService.isEligible(c, matchContext))
        .toList();
    final ratings = await ReviewService.fetchRatingsFor(
      eligible
          .map((c) => c['uid'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList(),
    );

    final ranked = MatchingService.rankCaregivers(
      caregivers: eligible,
      context: matchContext,
      ratings: ratings,
    );

    if (!mounted) return;
    setState(() {
      _matches = ranked.take(5).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(context)),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  // Paints full-bleed behind the transparent status bar (edge-to-edge mode);
  // the top padding below (not an outer SafeArea) keeps content clear of it.
  Widget _buildHeader(BuildContext context) {
    final count = _matches.length;
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, topInset + 12, 22, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [headerGreenLight, darkGreen],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            count > 0 ? 'Your top $count matches' : 'Your matches',
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ranked by skills, availability, proximity and your requirements',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: Color.fromRGBO(226, 217, 227, 0.87),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: darkGreen),
      );
    }
    if (_matches.isEmpty) {
      return EmptyState(
        icon: Icons.person_search_rounded,
        message:
            'No caregivers meet your requirements yet — this can happen if '
            'very few caregivers match your language, gender preference, '
            'certification, or travel-distance needs. Try searching '
            'directly, or check back once more caregivers have joined.',
        iconColor: cardBorderBrown,
        textColor: const Color(0xFF5C5A5A),
        actionLabel: 'Search caregivers',
        onAction: () => Navigator.pushNamed(context, '/search'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
      itemCount: _matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final m = _matches[index];
        final gradient = _avatarGradients[index % _avatarGradients.length];
        return index == 0
            ? _buildBestMatchCard(context, m, gradient)
            : _buildRankedCard(context, index + 1, m, gradient);
      },
    );
  }

  String _initialsOf(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  String _subtitleFor(MatchResult m) {
    final careTypes = (m.caregiver['careTypes'] as List?)?.cast<String>() ?? [];
    final years = m.caregiver['yearsExperience'];
    final parts = [
      if (careTypes.isNotEmpty) careTypes.first,
      if (years != null) '$years yrs exp',
      if (m.distanceKm != null) '${m.distanceKm!.toStringAsFixed(1)} km',
    ];
    return parts.isEmpty ? 'Caregiver' : parts.join(' · ');
  }

  // Opens a bottom sheet showing the per-criterion breakdown behind a
  // caregiver's match percentage — how MatchingService actually reached
  // that number, including which criteria (if any) were left out of a
  // caregiver's score because the data was structurally absent rather than
  // scored against them as zero.
  void _showBreakdown(BuildContext context, MatchResult m) {
    final name = (m.caregiver['name'] as String?) ?? 'Caregiver';
    showModalBottomSheet(
      context: context,
      backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why $name matched at ${m.matchPercent.round()}%',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: darkGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Each factor is weighted from what patients told us matters '
                'most. A greyed-out factor means this caregiver has no '
                'recorded data for it — it was left out of their score, not '
                'counted against them.',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color(0xFF5C5A5A),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ...m.breakdown.map(_buildBreakdownRow),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(CriterionScore row) {
    final label = MatchingService.labels[row.criterion]!;
    final absent = row.structurallyAbsent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: absent ? const Color(0xFF9C9C9C) : const Color(0xFF1E1E1E),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: absent
                ? const Text(
                    'Not available — excluded, not penalized',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF9C9C9C),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: row.rawValue,
                      minHeight: 6,
                      backgroundColor: scoreBarTrack.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(scoreBarFill),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              absent ? '—' : '+${row.contributionPoints.round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Best match card (rank 1, red accent) ───────────────────────────────
  Widget _buildBestMatchCard(
      BuildContext context, MatchResult m, List<Color> gradient) {
    final uid = m.caregiver['uid'] as String?;
    final name = (m.caregiver['name'] as String?) ?? 'Caregiver';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardTan,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bestBorderRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bestBorderRed,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 13),
                SizedBox(width: 4),
                Text(
                  'BEST MATCH',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(241, 149, 149, 0.4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initialsOf(name),
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: bestBorderRed,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color(0xFF1E1E1E),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitleFor(m),
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
              GestureDetector(
                onTap: () => _showBreakdown(context, m),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(206, 128, 80, 0.4),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${m.matchPercent.round()}%',
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color(0xFF7E3411),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showBreakdown(context, m),
            child: const Text(
              'Why this match? ›',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: bestBorderRed,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: bestBorderRed,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => _sendRequest(m),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Request',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 13,
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
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/caregiver-profile',
                      arguments: {'caregiverId': uid},
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: bestBorderRed),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: bestBorderRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

  // ── Ranked cards (2-5, tan/brown accent) ───────────────────────────────
  Widget _buildRankedCard(BuildContext context, int rank, MatchResult m,
      List<Color> gradient) {
    final uid = m.caregiver['uid'] as String?;
    final name = (m.caregiver['name'] as String?) ?? 'Caregiver';
    final fillFraction = (m.matchPercent / 100).clamp(0.08, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 12, 12, 12),
      decoration: BoxDecoration(
        color: cardTan,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: cardBorderBrown, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankBadgeBg,
                  border: Border.all(color: rankBadgeBorder, width: 1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: rankBadgeText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
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
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitleFor(m),
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color.fromRGBO(0, 0, 0, 0.56),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showBreakdown(context, m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${m.matchPercent.round()}%',
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: scoreBarFill,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scoreBarTrack,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: fillFraction,
                          child: Container(
                            decoration: BoxDecoration(
                              color: scoreBarFill,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: requestBrown,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _sendRequest(m),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Text(
                          'Request',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/caregiver-profile',
                        arguments: {'caregiverId': uid},
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          border: Border.all(color: requestBrown),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: requestBrown,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  // ── Bottom nav (matches dashboard/search/bookings) ─────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        _buildBottomNav(context),
        Positioned(top: -22, child: _buildMatchFab(context)),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home', route: '/patient-dashboard'),
      (icon: Icons.search_rounded, label: 'Search', route: '/search'),
      (icon: null, label: 'Match', route: null),
      (icon: Icons.calendar_month_outlined, label: 'Booking', route: '/my-bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Notification', route: '/notifications'),
    ];
    return Container(
      width: double.infinity,
      color: darkGreen,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 67,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];

              if (index == 2) {
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

              return GestureDetector(
                onTap: item.route != null
                    ? () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          item.route!,
                          (route) => route.settings.name == '/patient-dashboard',
                        )
                    : null,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: Colors.white, size: 25),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: Colors.white,
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

  Widget _buildMatchFab(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (AppState.hasActiveMatch.value) {
          // Already viewing the current top 5 — tapping Match again here can
          // only mean "redo it", so confirm before discarding them.
          final confirmed = await showRestartMatchDialog(context);
          if (confirmed && context.mounted) {
            Navigator.pushNamed(context, '/advanced-match-send-request');
          }
        } else {
          Navigator.pushNamed(context, '/advanced-match-send-request');
        }
      },
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
        child: SvgPicture.asset(
          'assets/images/match_target_icon.svg',
          width: 65,
          height: 65,
        ),
      ),
    );
  }
}
