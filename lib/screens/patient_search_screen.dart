import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../widgets/empty_state.dart';

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
  static const Color navHomeLabel = Color(0xFFFEE269);
  static const Color navMatchLabel = Color(0xFFFFA722);

  String _userName = 'there';
  bool _loading = true;
  List<Map<String, dynamic>> _caregivers = [];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadCaregivers();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _loadCaregivers() async {
    final results = await CaregiverService.searchCaregivers();
    if (mounted) {
      setState(() {
        _caregivers = results;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredCaregivers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _caregivers;
    return _caregivers.where((c) {
      final name = (c['name'] as String? ?? '').toLowerCase();
      final city = (c['city'] as String? ?? '').toLowerCase();
      return name.contains(query) || city.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredCaregivers;
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: darkGreen))
                  : results.isEmpty
                      ? EmptyState(
                          icon: Icons.person_search_rounded,
                          message: _caregivers.isEmpty
                              ? 'No caregivers have registered yet — check back soon.'
                              : 'No caregivers match your search.',
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                          children: [
                            const Text(
                              'Caregivers',
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: darkGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...results.map(
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
  Widget _buildCaregiverCard(Map<String, dynamic> c) {
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
    final skills = (c['skills'] as List?)?.cast<String>() ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFD1C8B4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE9C368),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (city != null && city.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_rounded, color: Colors.black, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            city,
                            style: const TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_off_outlined,
                              color: Colors.black.withValues(alpha: 0.4), size: 13),
                          const SizedBox(width: 3),
                          Text(
                            'Location not set',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.black.withValues(alpha: 0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    if (careTypes.isNotEmpty || yearsExperience != null)
                      Text(
                        [
                          if (careTypes.isNotEmpty) careTypes.join(', '),
                          if (yearsExperience != null) '$yearsExperience yrs exp',
                        ].join(' · '),
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skills.take(3).map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                color: darkGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/send-request',
                      arguments: {'caregiverId': uid},
                    ),
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
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/caregiver-profile',
                      arguments: {'caregiverId': uid},
                    ),
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

class _MatchFab extends StatefulWidget {
  const _MatchFab();

  @override
  State<_MatchFab> createState() => _MatchFabState();
}

class _MatchFabState extends State<_MatchFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    // 2s stopped, then a full turn that gradually accelerates (3s) and
    // gradually decelerates (3s) — an 8s cycle that then repeats.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 2),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          turns: _rotation,
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

// ── Filters bottom sheet ──────────────────────────────────
enum _CareType { fullTime, partTime, liveIn, flexible }

enum _SortBy { nearest, highestRated }

class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  static const Color darkGreen = Color(0xFF06402B);
  static const Color borderTan = Color.fromRGBO(6, 64, 43, 0.2);

  _CareType _careType = _CareType.fullTime;
  _SortBy _sortBy = _SortBy.nearest;
  double _maxDistance = 15;
  double _minRating = 4.0;

  void _clearAll() {
    setState(() {
      _careType = _CareType.fullTime;
      _sortBy = _SortBy.nearest;
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
