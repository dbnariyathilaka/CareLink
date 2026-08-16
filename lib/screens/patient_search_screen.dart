import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../data/sri_lankan_cities.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver search filters — real fields only. "Care type" (Elder/Child/
//  Disability/Post-surgery) and "Minimum rating" stay in the sheet's UI to
//  match Figma, but aren't applied here: caregiver profiles never store a
//  care-category field (that's only ever collected on the patient side),
//  and there's no cached average-rating field on the profile doc — same
//  "don't fake it" call already made for star ratings/availability badges
//  in advanced_match_results_screen.dart.
class CaregiverFilters {
  const CaregiverFilters({
    this.schedule,
    this.maxDistanceKm = 30,
    this.languages = const {},
    this.skills = const {},
    this.experience = 'Any',
    this.education = 'Any',
    this.trainedOnly = false,
    this.gender = 'Any',
  });

  final String? schedule; // 'Full-time' | 'Part-time' | 'Live-in'
  final double maxDistanceKm;
  final Set<String> languages;
  final Set<String> skills;
  final String experience; // 'Any' | '1+ yrs' | '3+ yrs' | '5+ yrs'
  final String education; // 'Any' | 'Certificate / diploma' | 'Degree or higher'
  final bool trainedOnly;
  final String gender; // 'Any' | 'Female' | 'Male'

  // The filter sheet's skill pills don't all correspond 1:1 to the option
  // strings caregivers actually pick from during onboarding — this maps
  // the ones that do have a real equivalent. 'Cooking' and 'First aid'
  // have none, so selecting them honestly matches no one.
  static const Map<String, String> _skillSynonyms = {
    'Dementia care': 'Dementia care',
    'Medication': 'Medication management',
    'Mobility support': 'Mobility assistance',
  };

  static const Map<String, int> _experienceYears = {
    '1+ yrs': 1,
    '3+ yrs': 3,
    '5+ yrs': 5,
  };

  bool matches(Map<String, dynamic> caregiver) {
    if (schedule != null) {
      final types = (caregiver['careTypes'] as List?)?.cast<String>() ?? const [];
      if (!types.contains(schedule)) return false;
    }

    if (maxDistanceKm < 30) {
      final patientCityName = AppState.careLocation.value.split(',').first.trim();
      final patientCity = cityCoords(patientCityName);
      final caregiverCity = cityCoords((caregiver['city'] as String?) ?? '');
      if (patientCity != null && caregiverCity != null) {
        final distanceKm = haversineKm(
          double.parse(patientCity['lat']!),
          double.parse(patientCity['lng']!),
          double.parse(caregiverCity['lat']!),
          double.parse(caregiverCity['lng']!),
        );
        if (distanceKm > maxDistanceKm) return false;
      }
    }

    if (languages.isNotEmpty) {
      final spoken = (caregiver['languagesSpoken'] as List?)?.cast<String>() ?? const [];
      if (!languages.any(spoken.contains)) return false;
    }

    if (skills.isNotEmpty) {
      final has = (caregiver['skills'] as List?)?.cast<String>() ?? const [];
      final wanted = skills.map((s) => _skillSynonyms[s]).whereType<String>();
      if (!wanted.any(has.contains)) return false;
    }

    final minYears = _experienceYears[experience];
    if (minYears != null) {
      final years = caregiver['yearsExperience'] as int? ?? 0;
      if (years < minYears) return false;
    }

    if (education == 'Certificate / diploma' &&
        caregiver['educationalQualification'] != 'Diploma') {
      return false;
    }
    if (education == 'Degree or higher' &&
        caregiver['educationalQualification'] != 'Degree or higher') {
      return false;
    }

    if (trainedOnly && caregiver['formalTraining'] != true) return false;

    if (gender != 'Any' && caregiver['gender'] != gender) return false;

    return true;
  }
}

class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  final TextEditingController _searchController = NoUnderlineTextEditingController();

  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color buttonNeutral = Color(0xFF554F42);
  static const Color navHomeLabel = Color(0xFFFEE269);
  static const Color navMatchLabel = Color(0xFFFFA722);

  String _userName = 'there';
  bool _loading = true;
  List<Map<String, dynamic>> _caregivers = [];
  // Null until the patient actually applies a filter — the sheet's own
  // pre-filled pills (matching Figma) are just a starting suggestion, not
  // silently active before "Apply filters" is tapped.
  CaregiverFilters? _activeFilters;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _loadUserName();
    _loadOwnPhoto();
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

  Future<void> _loadOwnPhoto() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final profile = await PatientService.getPatientProfile(user.uid);
    AppState.hydratePatientPhoto(profile?['photoUrl'] as String?);
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
    final filters = _activeFilters;
    var matches = filters == null
        ? _caregivers
        : _caregivers.where(filters.matches).toList();

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return matches;
    matches = matches.where((c) {
      final name = (c['name'] as String? ?? '').toLowerCase();
      final city = (c['city'] as String? ?? '').toLowerCase();
      return name.contains(query) || city.contains(query);
    }).toList();
    // Names that start with the typed letters rank above names that only
    // match mid-string (e.g. "se" → "senesh" before "Sandali Sewwandi"),
    // alphabetical within each group.
    matches.sort((a, b) {
      final nameA = (a['name'] as String? ?? '').trim().toLowerCase();
      final nameB = (b['name'] as String? ?? '').trim().toLowerCase();
      final startsA = nameA.startsWith(query);
      final startsB = nameB.startsWith(query);
      if (startsA != startsB) return startsA ? -1 : 1;
      return nameA.compareTo(nameB);
    });
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredCaregivers;
    return Scaffold(
      backgroundColor: bgCream,
      body: Column(
        children: [
          _buildHeader(context),
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
    );
  }

  void _showFiltersSheet(BuildContext context) async {
    final result = await showModalBottomSheet<CaregiverFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiltersSheet(initialFilters: _activeFilters),
    );
    if (result != null && mounted) {
      setState(() => _activeFilters = result);
    }
  }

  // ── Header (matches dashboard style, plus search bar) ─────
  // Paints full-bleed behind the transparent status bar (edge-to-edge mode);
  // the top padding below (not an outer SafeArea) keeps content clear of it.
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
      padding: EdgeInsets.fromLTRB(22, topInset + 12, 22, 20),
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
                        color: Color.fromRGBO(6, 64, 43, 0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
        ),
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

// ─────────────────────────────────────────────────────────────
//  Filters bottom sheet  (Figma node 346-1035)
// ─────────────────────────────────────────────────────────────
enum _Schedule { fullTime, partTime, liveIn }

class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key, this.initialFilters});

  // Null on first open (falls back to the Figma mock's pre-filled pills);
  // once the patient has applied filters, reopening seeds from those.
  final CaregiverFilters? initialFilters;

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  static const Color sheetBg = Color(0xFFF5EEE8);
  static const Color dragHandle = Color(0xFF475569);
  static const Color titleBrown = Color(0xFF5E462B);
  static const Color closeIcon = Color.fromRGBO(68, 51, 28, 0.47);
  static const Color sectionLabel = Color.fromRGBO(93, 65, 41, 0.7);
  static const Color radioLabelLight = Color.fromRGBO(68, 51, 28, 0.52);
  static const Color radioLabelDark = Color.fromRGBO(68, 51, 28, 0.79);
  static const Color radioIcon = Color(0xFF44331C);
  static const Color radioIconUnchecked = Color(0xFF475569);
  static const Color sliderTrack = Color(0xFF765B36);
  static const Color sliderFill = Color(0xFF44331C);
  static const Color sliderLabel = Color(0xFF494742);
  static const Color pillDark = Color(0xFF44331C);
  static const Color pillDarkText = Color(0xFFF1C58B);
  static const Color amberBg = Color(0xFFEEDECA);
  static const Color amberBorder = Color(0xFFC57E22);
  static const Color clearAllBorder = Color.fromRGBO(68, 51, 28, 0.3);
  static const Color applyBg = Color(0xFF5C4537);

  static const _careTypeOptions = ['Elder care', 'Child care', 'Disability care', 'Post-surgery'];
  static const _languageOptions = ['Sinhala', 'English', 'Tamil'];
  static const _skillOptions = ['Dementia care', 'Medication', 'Mobility support', 'Cooking', 'First aid'];
  static const _experienceOptions = ['Any', '1+ yrs', '3+ yrs', '5+ yrs'];
  static const _educationOptions = ['Any', 'Certificate / diploma', 'Degree or higher'];

  final Set<String> _careTypes = {'Elder care'};
  _Schedule? _schedule = _Schedule.fullTime;
  double _maxDistance = 15;
  double _minRating = 4.0;
  final Set<String> _languages = {'Sinhala', 'English'};
  final Set<String> _skills = {'Dementia care'};
  String _experience = '3+ yrs';
  String _education = 'Certificate / diploma';
  String _training = 'No preference';
  String _gender = 'Any';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    if (initial == null) return;
    _schedule = switch (initial.schedule) {
      'Full-time' => _Schedule.fullTime,
      'Part-time' => _Schedule.partTime,
      'Live-in' => _Schedule.liveIn,
      _ => null,
    };
    _maxDistance = initial.maxDistanceKm;
    _languages
      ..clear()
      ..addAll(initial.languages);
    _skills
      ..clear()
      ..addAll(initial.skills);
    _experience = initial.experience;
    _education = initial.education;
    _training = initial.trainedOnly ? 'Trained only' : 'No preference';
    _gender = initial.gender;
  }

  CaregiverFilters _buildFilters() {
    return CaregiverFilters(
      schedule: switch (_schedule) {
        _Schedule.fullTime => 'Full-time',
        _Schedule.partTime => 'Part-time',
        _Schedule.liveIn => 'Live-in',
        null => null,
      },
      maxDistanceKm: _maxDistance,
      languages: Set.of(_languages),
      skills: Set.of(_skills),
      experience: _experience,
      education: _education,
      trainedOnly: _training == 'Trained only',
      gender: _gender,
    );
  }

  void _clearAll() {
    setState(() {
      _careTypes.clear();
      _schedule = null;
      _maxDistance = 30;
      _minRating = 0;
      _languages.clear();
      _skills.clear();
      _experience = 'Any';
      _education = 'Any';
      _training = 'No preference';
      _gender = 'Any';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: const BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: dragHandle,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: titleBrown,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close_rounded, color: closeIcon, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('CARE TYPE'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _careTypeOptions
                          .map((o) => _pill(
                                o,
                                _careTypes.contains(o),
                                () => setState(() {
                                  if (_careTypes.contains(o)) {
                                    _careTypes.remove(o);
                                  } else {
                                    _careTypes.add(o);
                                  }
                                }),
                                amber: true,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('SCHEDULE'),
                    const SizedBox(height: 9),
                    _radioRow(
                      'Full-time only',
                      _schedule == _Schedule.fullTime,
                      () => setState(() => _schedule = _Schedule.fullTime),
                    ),
                    const SizedBox(height: 9),
                    _radioRow(
                      'Part-time only',
                      _schedule == _Schedule.partTime,
                      () => setState(() => _schedule = _Schedule.partTime),
                    ),
                    const SizedBox(height: 9),
                    _radioRow(
                      'Live-in only',
                      _schedule == _Schedule.liveIn,
                      () => setState(() => _schedule = _Schedule.liveIn),
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
                    _sectionLabel('LANGUAGE'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _languageOptions
                          .map((o) => _pill(
                                o,
                                _languages.contains(o),
                                () => setState(() {
                                  if (_languages.contains(o)) {
                                    _languages.remove(o);
                                  } else {
                                    _languages.add(o);
                                  }
                                }),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('SKILLS'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skillOptions
                          .map((o) => _pill(
                                o,
                                _skills.contains(o),
                                () => setState(() {
                                  if (_skills.contains(o)) {
                                    _skills.remove(o);
                                  } else {
                                    _skills.add(o);
                                  }
                                }),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('EXPERIENCE'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _experienceOptions
                          .map((o) => _pill(o, _experience == o, () => setState(() => _experience = o)))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('EDUCATION LEVEL'),
                    const SizedBox(height: 9),
                    ..._educationOptions.expand((o) => [
                          _radioRow(o, _education == o, () => setState(() => _education = o),
                              labelColor: radioLabelDark),
                          const SizedBox(height: 9),
                        ]),
                    const SizedBox(height: 9),
                    _sectionLabel('FORMAL TRAINING'),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _toggleButton('Trained only', _training == 'Trained only',
                            () => setState(() => _training = 'Trained only')),
                        const SizedBox(width: 10),
                        _toggleButton('No preference', _training == 'No preference',
                            () => setState(() => _training = 'No preference')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('GENDER'),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _toggleButton('Any', _gender == 'Any', () => setState(() => _gender = 'Any')),
                        const SizedBox(width: 10),
                        _toggleButton('Female', _gender == 'Female', () => setState(() => _gender = 'Female')),
                        const SizedBox(width: 10),
                        _toggleButton('Male', _gender == 'Male', () => setState(() => _gender = 'Male')),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                16,
                22,
                // The nav bar's safe-area inset was missing entirely here —
                // "Clear all"/"Apply filters" were getting clipped by it.
                20 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
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
                            border: Border.all(color: clearAllBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Clear all',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              color: pillDark,
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
                      color: applyBg,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.pop(context, _buildFilters()),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Apply filters',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.white,
                              fontSize: 14,
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
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Open Sans',
        color: sectionLabel,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _radioRow(String label, bool selected, VoidCallback onTap, {Color labelColor = radioLabelLight}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            color: selected ? radioIcon : radioIconUnchecked,
            size: 21,
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
              activeTrackColor: sliderFill,
              inactiveTrackColor: sliderTrack,
              thumbColor: sliderFill,
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
            fontFamily: 'Open Sans',
            color: sliderLabel,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, bool selected, VoidCallback onTap, {bool amber = false}) {
    final unselectedBg = amber ? amberBg : Colors.transparent;
    final unselectedBorder = amber ? amberBorder : pillDark;
    final unselectedText = amber ? amberBorder : pillDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? pillDark : unselectedBg,
          border: Border.all(color: selected ? pillDark : unselectedBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: selected ? pillDarkText : unselectedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? pillDark : Colors.transparent,
            border: Border.all(color: pillDark),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: selected ? pillDarkText : pillDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
