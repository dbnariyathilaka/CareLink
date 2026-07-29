import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../data/sri_lankan_cities.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/request_sent_dialog.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Advanced Match Results Screen  (Figma node 324-471)
//  There is no trained matching model behind this app, so the ranking here is
//  a plain, disclosed formula — care-type match + real distance between the
//  patient's saved city and each caregiver's city (haversine, both looked up
//  in sriLankanCities). Fields with no real backing data yet (star ratings,
//  "available now" badges) are intentionally left out rather than faked.
// ─────────────────────────────────────────────────────────────────────────────
class AdvancedMatchResultsScreen extends StatefulWidget {
  const AdvancedMatchResultsScreen({super.key});

  @override
  State<AdvancedMatchResultsScreen> createState() =>
      _AdvancedMatchResultsScreenState();
}

class _RankedCaregiver {
  final Map<String, dynamic> data;
  final double score;
  final double? distanceKm;
  const _RankedCaregiver(this.data, this.score, this.distanceKm);
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
  List<_RankedCaregiver> _matches = const [];
  Map<String, dynamic> _bookingArgs = {};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _loadMatches();
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
  }

  // Creates a booking request tied to this specific caregiver, reusing the
  // schedule/location details already collected earlier in the advanced
  // matching wizard — no need to ask the patient to re-enter them.
  Future<void> _sendRequest(_RankedCaregiver m) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final name = (m.data['name'] as String?) ?? 'Caregiver';
    final careType = _bookingArgs['careType'] as String? ?? AppState.careType.value;
    final startDate = _bookingArgs['startDate'] as String? ?? '';
    final startTime = _bookingArgs['startTime'] as String? ?? '';
    final location = _bookingArgs['location'] as String? ?? AppState.careLocation.value;

    await BookingService.createBookingRequest(
      patientUid: uid,
      caregiverId: m.data['uid'] as String?,
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

  Map<String, String>? _findCity(String name) {
    final target = name.trim().toLowerCase();
    for (final c in sriLankanCities) {
      if (c['city']!.toLowerCase() == target) return c;
    }
    return null;
  }

  double? _distanceKmTo(String? caregiverCity) {
    if (caregiverCity == null || caregiverCity.isEmpty) return null;
    final patientCityName = AppState.careLocation.value.split(',').first.trim();
    final patientCity = _findCity(patientCityName);
    final otherCity = _findCity(caregiverCity);
    if (patientCity == null || otherCity == null) return null;
    return haversineKm(
      double.parse(patientCity['lat']!),
      double.parse(patientCity['lng']!),
      double.parse(otherCity['lat']!),
      double.parse(otherCity['lng']!),
    );
  }

  double _scoreFor(Map<String, dynamic> caregiver, String requestedCareType,
      double? distanceKm) {
    final careTypes = (caregiver['careTypes'] as List?)?.cast<String>() ?? [];
    final matchesCareType = careTypes
        .any((c) => c.toLowerCase() == requestedCareType.toLowerCase());
    double score = matchesCareType ? 65 : 30;
    if (distanceKm != null) {
      score += (25 - distanceKm).clamp(0, 25);
    } else {
      score += 12;
    }
    return score.clamp(0, 99);
  }

  Future<void> _loadMatches() async {
    final requestedCareType = AppState.careType.value;
    final caregivers = await CaregiverService.searchCaregivers();
    final ranked = caregivers.map((c) {
      final distanceKm = _distanceKmTo(c['city'] as String?);
      final score = _scoreFor(c, requestedCareType, distanceKm);
      return _RankedCaregiver(c, score, distanceKm);
    }).toList();
    ranked.sort((a, b) => b.score.compareTo(a.score));
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
            'Ranked by care type match and distance from you',
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
            'No caregiver profiles are in the system yet. Try searching '
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

  String _subtitleFor(_RankedCaregiver m) {
    final careTypes = (m.data['careTypes'] as List?)?.cast<String>() ?? [];
    final years = m.data['yearsExperience'];
    final parts = [
      if (careTypes.isNotEmpty) careTypes.first,
      if (years != null) '$years yrs exp',
      if (m.distanceKm != null) '${m.distanceKm!.toStringAsFixed(1)} km',
    ];
    return parts.isEmpty ? 'Caregiver' : parts.join(' · ');
  }

  // ── Best match card (rank 1, red accent) ───────────────────────────────
  Widget _buildBestMatchCard(
      BuildContext context, _RankedCaregiver m, List<Color> gradient) {
    final uid = m.data['uid'] as String?;
    final name = (m.data['name'] as String?) ?? 'Caregiver';
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
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(206, 128, 80, 0.4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${m.score.round()}%',
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: Color(0xFF7E3411),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
  Widget _buildRankedCard(BuildContext context, int rank, _RankedCaregiver m,
      List<Color> gradient) {
    final uid = m.data['uid'] as String?;
    final name = (m.data['name'] as String?) ?? 'Caregiver';
    final fillFraction = (m.score / 100).clamp(0.08, 1.0);
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${m.score.round()}%',
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
