import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  int _selectedFilter = 0;

  static const List<String> _filters = [
    'All',
    'Available now',
    'Elder care',
    'Post-surgery',
  ];

  static const Color _blueAvatar = Color(0xFF058CD0);
  static const Color _amberAvatar = Color(0xFFF59E0B);

  static const List<_CaregiverData> _caregivers = [
    _CaregiverData(
      initials: 'AF',
      avatarType: _AvatarType.greenGradient,
      name: 'Alice Fernando',
      matchScore: '92%',
      detail: 'Elder care · 7 yrs · 2.3 km · ★4.8',
    ),
    _CaregiverData(
      initials: 'BK',
      avatarType: _AvatarType.blue,
      name: 'Brian Kumara',
      matchScore: '88%',
      detail: 'Post-surgery · 5 yrs · 3.1 km · ★4.6',
    ),
    _CaregiverData(
      initials: 'NS',
      avatarType: _AvatarType.amber,
      name: 'Nadeesha Silva',
      matchScore: '86%',
      detail: 'Elder care · 9 yrs · 4.6 km · ★4.9',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                  const SizedBox(height: 12),
                  _buildResultsHeader(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                itemCount: _caregivers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildCaregiverCard(_caregivers[i]),
              ),
            ),
            _buildBottomNav(context),
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
      builder: (_) => const _FiltersSheet(),
    );
  }

  // ── Status bar ────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
      child: SizedBox(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: const [
                Icon(Icons.signal_cellular_alt, color: AppTheme.textPrimary, size: 18),
                SizedBox(width: 5),
                Icon(Icons.wifi, color: AppTheme.textPrimary, size: 18),
                SizedBox(width: 5),
                Icon(Icons.battery_full, color: AppTheme.textPrimary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Search by name or skill…',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showFiltersSheet(context),
            child: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 29,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryGreen : AppTheme.cardColor,
                border: selected ? null : Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    color: selected ? AppTheme.bottleGreen : const Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Results count + sort ──────────────────────────────────
  Widget _buildResultsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_caregivers.length} caregivers found',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: const [
            Text(
              'Sort: Best match',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.swap_vert_rounded, color: Color(0xFFCBD5E1), size: 16),
          ],
        ),
      ],
    );
  }

  // ── Caregiver card ────────────────────────────────────────
  Widget _buildCaregiverCard(_CaregiverData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(data),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            data.matchScore,
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.detail,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {},
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Request',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.bottleGreen,
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
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.pushNamed(context, '/caregiver-profile'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
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
        ],
      ),
    );
  }

  Widget _buildAvatar(_CaregiverData data) {
    switch (data.avatarType) {
      case _AvatarType.greenGradient:
        return Container(
          width: 44,
          height: 44,
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
              data.initials,
              style: const TextStyle(
                color: AppTheme.bottleGreen,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      case _AvatarType.blue:
        return Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: _blueAvatar),
          child: Center(
            child: Text(
              data.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      case _AvatarType.amber:
        return Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: _amberAvatar),
          child: Center(
            child: Text(
              data.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
    }
  }

  // ── Bottom nav (matches dashboard) ────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.search_rounded, label: 'Search'),
      (icon: Icons.calendar_month_rounded, label: 'Bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];
    const selectedIndex = 1; // Search tab always active on this screen

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;
          final color = isSelected ? AppTheme.primaryGreen : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/patient-dashboard'));
              } else if (index == 2) {
                Navigator.pushNamed(context, '/my-bookings');
              } else if (index == 3) {
                Navigator.pushNamed(context, '/notifications');
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────
enum _AvatarType { greenGradient, blue, amber }

class _CaregiverData {
  final String initials;
  final _AvatarType avatarType;
  final String name;
  final String matchScore;
  final String detail;

  const _CaregiverData({
    required this.initials,
    required this.avatarType,
    required this.name,
    required this.matchScore,
    required this.detail,
  });
}

// ── Filters bottom sheet ──────────────────────────────────
enum _CareType { fullTime, partTime, liveIn }

enum _SortBy { bestMatch, nearest, highestRated }

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
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
          color: AppTheme.cardColor,
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
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
                  color: const Color(0xFF475569),
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
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: AppTheme.textPrimary, size: 24),
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
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Clear all',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
                    color: AppTheme.primaryGreen,
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
                            color: AppTheme.bottleGreen,
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
      style: const TextStyle(
        color: AppTheme.textSecondary,
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
              color: Color(0xFFCBD5E1),
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
                color: selected ? AppTheme.primaryGreen : AppTheme.borderColor,
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
                        color: AppTheme.primaryGreen,
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
              activeTrackColor: AppTheme.primaryGreen,
              inactiveTrackColor: AppTheme.surfaceColor,
              thumbColor: AppTheme.primaryGreen,
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
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
