import 'dart:io';
import 'package:flutter/material.dart';
import '../app_state.dart';

class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color buttonNeutral = Color(0xFF554F42);
  static const Color matchBadgeBg = Color.fromRGBO(64, 64, 6, 0.3);
  static const Color matchBadgeText = Color(0xFF33440A);
  static const Color navHomeLabel = Color(0xFFFEE269);
  static const Color navMatchLabel = Color(0xFFFFA722);
  static const Color starGold = Color(0xFFF5B301);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const List<_CaregiverData> _caregivers = [
    _CaregiverData(
      initials: 'RF',
      avatarBg: Color(0xFFE9C368),
      initialsColor: darkGreen,
      name: 'Rayan Fernando',
      matchScore: '95%',
      careType: 'Elder care',
      experience: '7 yrs exp',
      distance: '2.5 km',
      rating: '4.8',
      available: true,
      cardBg: Color.fromRGBO(100, 86, 57, 0.25),
    ),
    _CaregiverData(
      initials: 'NS',
      avatarBg: Color(0xFFB9C2E8),
      initialsColor: Color(0xFF0A2447),
      name: 'Navodya Sankalpa',
      matchScore: '89%',
      careType: 'Elder care',
      experience: '5 yrs exp',
      distance: '3.6 km',
      rating: '4.8',
      available: true,
      cardBg: Color(0xFFD1C8B4),
    ),
  ];

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
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
                  const SizedBox(height: 14),
                  ..._caregivers.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildCaregiverCard(c),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FiltersSheet(),
    );
  }

  // ── Header (matches dashboard style, plus search bar) ─────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  const Text(
                    'Nipuni Ariyathilaka',
                    style: TextStyle(
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
          const SizedBox(height: 18),
          // Search/filter bar
          Container(
            width: double.infinity,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6E3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.search_rounded,
                    color: Color.fromRGBO(6, 64, 43, 0.6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: darkGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      filled: false,
                      isDense: true,
                      hintText: 'Search caregivers....',
                      hintStyle: TextStyle(
                        fontFamily: 'Quattrocento Sans',
                        color: Color.fromRGBO(6, 64, 43, 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () => _showFiltersSheet(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(
                      Icons.tune_rounded,
                      color: darkGreen,
                      size: 20,
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

  // ── Caregiver card ────────────────────────────────────────
  Widget _buildCaregiverCard(_CaregiverData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: data.cardBg,
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.avatarBg,
                    ),
                    child: Center(
                      child: Text(
                        data.initials,
                        style: TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: data.initialsColor,
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
                        data.distance,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
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
                            data.name,
                            style: const TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
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
                            data.matchScore,
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
                          data.careType,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.black,
                            fontSize: 12,
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
                          data.experience,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.black,
                            fontSize: 12,
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
                          data.rating,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
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
                            color: data.available ? const Color(0xFF22C55E) : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          data.available ? 'Available' : 'Unavailable',
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
                  color: buttonNeutral,
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
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 12,
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
                        border: Border.all(color: buttonNeutral),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: buttonNeutral,
                          fontSize: 12,
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

  // ── Bottom nav (matches dashboard, Search tab highlighted) ─
  Widget _buildBottomBar() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        _buildBottomNav(),
        const Positioned(
          top: -22,
          child: _MatchFab(),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (icon: Icons.home_rounded, label: 'Home', route: null),
      (icon: Icons.search_rounded, label: 'Search', route: null),
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

          final color = index == 1 ? navHomeLabel : Colors.white;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/patient-dashboard'));
              } else if (item.route != null) {
                Navigator.pushNamed(context, item.route!);
              }
            },
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
}

class _MatchFab extends StatelessWidget {
  const _MatchFab();

  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color navMatchLabel = Color(0xFFFFA722);

  @override
  Widget build(BuildContext context) {
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

// ── Data model ────────────────────────────────────────────
class _CaregiverData {
  final String initials;
  final Color avatarBg;
  final Color initialsColor;
  final String name;
  final String matchScore;
  final String careType;
  final String experience;
  final String distance;
  final String rating;
  final bool available;
  final Color cardBg;

  const _CaregiverData({
    required this.initials,
    required this.avatarBg,
    required this.initialsColor,
    required this.name,
    required this.matchScore,
    required this.careType,
    required this.experience,
    required this.distance,
    required this.rating,
    required this.available,
    required this.cardBg,
  });
}

// ── Filters bottom sheet ──────────────────────────────────
enum _CareType { fullTime, partTime, liveIn, flexible }

enum _SortBy { bestMatch, nearest, highestRated }

class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  static const Color darkGreen = Color(0xFF06402B);
  static const Color borderTan = Color.fromRGBO(6, 64, 43, 0.2);

  _CareType _careType = _CareType.fullTime;
  _SortBy _sortBy = _SortBy.bestMatch;
  double _maxDistance = 15;
  double _minRating = 4.0;

  void _clearAll() {
    setState(() {
      _careType = _CareType.fullTime;
      _sortBy = _SortBy.bestMatch;
      _maxDistance = 15;
      _minRating = 4.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 17, 22, 20),
        decoration: const BoxDecoration(
          color: Color(0xFFF5EEDE),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: darkGreen,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: darkGreen, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionLabel('CARE TYPE'),
            const SizedBox(height: 9),
            _radioRow(
              'Full-time only',
              _careType == _CareType.fullTime,
              () => setState(() => _careType = _CareType.fullTime),
            ),
            const SizedBox(height: 9),
            _radioRow(
              'Part-time only',
              _careType == _CareType.partTime,
              () => setState(() => _careType = _CareType.partTime),
            ),
            const SizedBox(height: 9),
            _radioRow(
              'Live-in only',
              _careType == _CareType.liveIn,
              () => setState(() => _careType = _CareType.liveIn),
            ),
            const SizedBox(height: 9),
            _radioRow(
              'Flexible',
              _careType == _CareType.flexible,
              () => setState(() => _careType = _CareType.flexible),
            ),
            const SizedBox(height: 18),
            _sectionLabel('MAXIMUM DISTANCE'),
            _sliderRow(
              value: _maxDistance,
              min: 1,
              max: 30,
              label: '${_maxDistance.round()} km',
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
            const SizedBox(height: 9),
            _sectionLabel('MINIMUM RATING'),
            _sliderRow(
              value: _minRating,
              min: 0,
              max: 5,
              divisions: 50,
              label: '${_minRating.toStringAsFixed(1)} ★',
              onChanged: (v) => setState(() => _minRating = v),
            ),
            const SizedBox(height: 18),
            _sectionLabel('SORT RESULTS BY'),
            const SizedBox(height: 9),
            _radioRow(
              'Best match',
              _sortBy == _SortBy.bestMatch,
              () => setState(() => _sortBy = _SortBy.bestMatch),
            ),
            const SizedBox(height: 9),
            _radioRow(
              'Nearest first',
              _sortBy == _SortBy.nearest,
              () => setState(() => _sortBy = _SortBy.nearest),
            ),
            const SizedBox(height: 9),
            _radioRow(
              'Highest rated first',
              _sortBy == _SortBy.highestRated,
              () => setState(() => _sortBy = _SortBy.highestRated),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _clearAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: darkGreen.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Clear all',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            color: darkGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Material(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Apply filters',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Quattrocento Sans',
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
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Quattrocento Sans',
        color: darkGreen.withValues(alpha: 0.6),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _radioRow(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Quattrocento Sans',
              color: darkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? darkGreen : borderTan,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: darkGreen,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
    int? divisions,
  }) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: darkGreen,
              inactiveTrackColor: darkGreen.withValues(alpha: 0.15),
              thumbColor: darkGreen,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Quattrocento Sans',
            color: darkGreen,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
