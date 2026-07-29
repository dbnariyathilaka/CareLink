import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/sri_lankan_cities.dart';
import '../services/caregiver_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Emergency Screen  (Figma node 346-1260)
//  Shows real registered caregivers within 10 km of the patient's saved
//  location, sorted by real (haversine) distance. No live availability or
//  drive-time system exists yet, so the Figma design's "Available now"
//  badges and ETA figures are intentionally left out rather than faked.
// ─────────────────────────────────────────────────────────────────────────────
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _RankedCaregiver {
  final Map<String, dynamic> data;
  final double distanceKm;
  const _RankedCaregiver(this.data, this.distanceKm);
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  static const Color pageBg = Color(0xFFF5EEDE);
  static const Color sheetBg = Color(0xFFF5EEE8);
  static const Color headerRed = Color(0xFF9E0606);
  static const Color dragHandle = Color(0xFFF69F9F);
  static const Color bannerBg = Color.fromRGBO(102, 65, 41, 0.47);
  static const Color bannerBorder = Color(0xFF532D0B);
  static const Color bannerDot = Color(0xFFFCA420);
  static const Color bannerText = Color(0xFF4B2F17);
  static const Color cardBg = Color(0xFFF0D7C8);
  static const Color cardBorder = Color(0xFFB84444);
  static const Color requestRed = Color(0xFFEF4444);
  static const Color specialtyText = Color.fromRGBO(0, 0, 0, 0.49);
  static const Color distanceText = Color.fromRGBO(49, 49, 49, 0.48);

  static const _avatarGradients = [
    [Color(0xFF22C55E), Color(0xFF16A34A)],
    [Color(0xFFA4B3CD), Color(0xFFA4B3CD)],
    [Color(0xFFEF960A), Color(0xFFDF8007)],
  ];

  static const double _radiusKm = 10;

  bool _loading = true;
  List<_RankedCaregiver> _nearby = const [];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    final patientCityName = AppState.careLocation.value.split(',').first.trim();
    final patientCity = cityCoords(patientCityName);

    final results = await CaregiverService.searchCaregivers();
    final ranked = <_RankedCaregiver>[];
    if (patientCity != null) {
      for (final c in results) {
        final city = c['city'] as String?;
        if (city == null || city.isEmpty) continue;
        final caregiverCity = cityCoords(city);
        if (caregiverCity == null) continue;
        final distanceKm = haversineKm(
          double.parse(patientCity['lat']!),
          double.parse(patientCity['lng']!),
          double.parse(caregiverCity['lat']!),
          double.parse(caregiverCity['lng']!),
        );
        if (distanceKm <= _radiusKm) {
          ranked.add(_RankedCaregiver(c, distanceKm));
        }
      }
      ranked.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    if (!mounted) return;
    setState(() {
      _nearby = ranked.take(3).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  color: sheetBg,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 17, 0),
                        child: _buildStatusBanner(),
                      ),
                      Expanded(child: _buildList(context)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Red header with drag handle + close ─────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
      color: headerRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: dragHandle,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find a caregiver now',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Status banner ────────────────────────────────────────────────────────
  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border.all(color: bannerBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: bannerDot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Showing nearest registered caregivers · top 3 within 10 km, closest first.',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: bannerText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── List / loading / empty ───────────────────────────────────────────────
  Widget _buildList(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: requestRed),
      );
    }
    if (_nearby.isEmpty) {
      return EmptyState(
        icon: Icons.person_search_rounded,
        message: 'No registered caregivers within 10 km right now. Try '
            'Search for a wider radius, or contact your existing caregiver '
            'directly.',
        iconColor: cardBorder,
        textColor: bannerText,
        actionLabel: 'Search caregivers',
        onAction: () => Navigator.pushNamed(context, '/search'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 16, 17, 20),
      itemCount: _nearby.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final gradient = _avatarGradients[index % _avatarGradients.length];
        return _buildCaregiverCard(context, _nearby[index], gradient);
      },
    );
  }

  // ── Caregiver card ────────────────────────────────────────────────────────
  Widget _buildCaregiverCard(
      BuildContext context, _RankedCaregiver m, List<Color> gradient) {
    final c = m.data;
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
    final careTypes = (c['careTypes'] as List?)?.cast<String>() ?? [];
    final yearsExperience = c['yearsExperience'] as int?;
    final specialty = [
      if (careTypes.isNotEmpty) careTypes.join(', '),
      if (yearsExperience != null) '$yearsExperience yrs',
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: cardBorder, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
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
              initials,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFF42413F),
                fontSize: 15,
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
                  name.isEmpty ? 'Unnamed caregiver' : name,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                if (specialty.isNotEmpty)
                  Text(
                    specialty,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: specialtyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 1),
                Text(
                  '${m.distanceKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: distanceText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/send-request',
              arguments: {'caregiverId': uid},
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: requestRed,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                'Request',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.white,
                  fontSize: 15,
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
