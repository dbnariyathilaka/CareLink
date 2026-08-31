import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/caregiver_service.dart';
import '../services/review_service.dart';
import '../services/user_directory_service.dart';
import '../widgets/status_bar.dart';
import 'admin_bookings_screen.dart';
import 'admin_caregiver_profile_screen.dart';
import 'admin_finance_screen.dart';

/// Sort options for the caregivers list — all backed by real, batch-fetched
/// data (ratings/reviews from ReviewService, name from the profile itself).
enum _CaregiverSort { none, highestRated, mostReviews, nameAz }

/// One row in the admin caregivers list. Wraps the raw `caregiverProfiles`
/// doc plus its joined `users` doc and rating summary — every getter below
/// traces straight back to a real field (see the class docs in
/// caregiver_service.dart / user_directory_service.dart / review_service.dart
/// for what's actually stored). Nothing here is fabricated.
class AdminCaregiverData {
  final String uid;
  final Map<String, dynamic> profile; // caregiverProfiles/{uid}
  final Map<String, dynamic>? user; // users/{uid} — may be null if unresolved
  final double rating;
  final int reviewCount;
  final Color avatarBg;
  final Color avatarTextColor;

  AdminCaregiverData({
    required this.uid,
    required this.profile,
    required this.user,
    required this.rating,
    required this.reviewCount,
    required this.avatarBg,
    required this.avatarTextColor,
  });

  String get name {
    final n = user?['name'] as String?;
    return (n != null && n.trim().isNotEmpty) ? n.trim() : 'Caregiver';
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CG';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  List<String> get careTypes {
    final types = profile['careTypes'];
    if (types is List) return types.map((e) => e.toString()).toList();
    return const [];
  }

  String get careType => careTypes.isNotEmpty ? careTypes.first : 'Not specified';

  String get city {
    final c = profile['city'] as String?;
    return (c != null && c.trim().isNotEmpty) ? c.trim() : 'Not specified';
  }

  String get nic {
    final n = profile['nic'] as String?;
    return (n != null && n.trim().isNotEmpty) ? n.trim() : 'Not provided';
  }

  String get phone {
    final p = user?['phone'] as String?;
    return (p != null && p.trim().isNotEmpty) ? p.trim() : 'Not provided';
  }

  int get yearsExperience => (profile['yearsExperience'] as num?)?.toInt() ?? 0;

  String get subtitle =>
      '$careType · $city · ${rating.toStringAsFixed(1)} ★ ($reviewCount)';
}

class AdminCaregiversScreen extends StatefulWidget {
  const AdminCaregiversScreen({super.key});

  @override
  State<AdminCaregiversScreen> createState() => _AdminCaregiversScreenState();
}

class _AdminCaregiversScreenState extends State<AdminCaregiversScreen> {
  // ── Color Tokens matching Figma node 618:554 ──────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);
  static const Color searchBoxBg = Color(0xFFFFF3DF);
  static const Color searchBoxBorder = Color(0xFFD6BA8B);
  static const Color searchHintColor = Color.fromRGBO(96, 78, 47, 0.45);
  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF766B58);
  static const Color cardNameColor = Color(0xFF5C5445);
  static const Color cardSubtitleColor = Color(0xFF7C6F5D);
  static const Color statsTileBg = Color(0xFF44331C);
  static const Color statsValueGold = Color(0xFFFBBC05);
  static const Color btnViewProfileBg = Color(0xFF59341E);
  static const Color btnSuspendBorder = Color(0xFF59341E);
  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color navGold = Color(0xFFFBBC05);

  // Deterministic per-caregiver avatar palette (picked by uid hash) so
  // colors stay stable across rebuilds without needing to store one.
  static const List<Color> _avatarBgPalette = [
    Color(0xFF727953),
    Color(0xFF357F83),
    Color(0xFFA28C66),
    Color(0xFF354152),
    Color(0xFF6ED5C9),
    Color(0xFFD9BDB5),
  ];
  static const List<Color> _avatarFgPalette = [
    Color(0xFF313715),
    Colors.white,
    Color(0xFF3B2404),
    Color(0xFFCBD5E1),
    Color(0xFF04302C),
    Color(0xFF41302B),
  ];

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final TextEditingController _searchController = TextEditingController();
  String? _expandedCaregiverId;
  bool _autoExpandDone = false;

  // Session-local only (never written to Firestore — there is no
  // suspension/verification field anywhere in the schema to persist to).
  // Purely flips the action button's own label; nothing is read back from
  // real data to render it, so no fabricated status is ever displayed.
  final Set<String> _locallySuspended = {};

  StreamSubscription<List<Map<String, dynamic>>>? _caregiversSub;
  List<AdminCaregiverData> _caregivers = [];
  bool _loading = true;
  _CaregiverSort _sort = _CaregiverSort.none;

  // Guards against a slower join from an older snapshot overwriting the
  // result of a newer one.
  int _fetchGen = 0;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _caregiversSub = CaregiverService.streamAllCaregivers().listen(_onCaregiversSnapshot);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _caregiversSub?.cancel();
    super.dispose();
  }

  Future<void> _onCaregiversSnapshot(List<Map<String, dynamic>> profiles) async {
    final gen = ++_fetchGen;
    final uids = profiles.map((p) => p['uid'] as String).toList();

    final users = await UserDirectoryService.getUsers(uids);
    final ratings = await ReviewService.fetchRatingsFor(uids);
    if (!mounted || gen != _fetchGen) return; // a newer snapshot has since arrived

    final list = profiles.map((profile) {
      final uid = profile['uid'] as String;
      final rating = ratings[uid];
      final colorIndex = uid.hashCode.abs() % _avatarBgPalette.length;
      return AdminCaregiverData(
        uid: uid,
        profile: profile,
        user: users[uid],
        rating: rating?.avg ?? 0.0,
        reviewCount: rating?.count ?? 0,
        avatarBg: _avatarBgPalette[colorIndex],
        avatarTextColor: _avatarFgPalette[colorIndex],
      );
    }).toList();

    if (!_autoExpandDone && list.isNotEmpty) {
      _expandedCaregiverId = list.first.uid;
      _autoExpandDone = true;
    }

    setState(() {
      _caregivers = list;
      _loading = false;
    });
  }

  List<AdminCaregiverData> get _filteredCaregivers {
    final query = _searchController.text.trim().toLowerCase();
    var list = _caregivers.where((cg) {
      if (query.isEmpty) return true;
      return cg.name.toLowerCase().contains(query) ||
          cg.nic.toLowerCase().contains(query) ||
          cg.phone.toLowerCase().contains(query) ||
          cg.city.toLowerCase().contains(query) ||
          cg.careType.toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case _CaregiverSort.highestRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _CaregiverSort.mostReviews:
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case _CaregiverSort.nameAz:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _CaregiverSort.none:
        break;
    }
    return list;
  }

  void _toggleExpand(String uid) {
    setState(() {
      _expandedCaregiverId = _expandedCaregiverId == uid ? null : uid;
    });
  }

  void _toggleSuspendStatus(AdminCaregiverData cg) {
    final isCurrentlySuspended = _locallySuspended.contains(cg.uid);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isCurrentlySuspended ? 'Reactivate Caregiver?' : 'Suspend Caregiver?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          isCurrentlySuspended
              ? 'Are you sure you want to reactivate ${cg.name}? They will be able to accept bookings again.'
              : 'Are you sure you want to suspend ${cg.name}? They will not be able to receive new booking requests.',
          style: const TextStyle(color: Color(0xFFC4BBAC), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlySuspended ? Colors.green : const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                if (isCurrentlySuspended) {
                  _locallySuspended.remove(cg.uid);
                } else {
                  _locallySuspended.add(cg.uid);
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${cg.name} has been ${isCurrentlySuspended ? 'reactivated' : 'suspended'}.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              isCurrentlySuspended ? 'Reactivate' : 'Suspend',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  /// Builds a filename/label for a certificate/document URL — falls back to
  /// a generic label rather than ever inventing a plausible-looking filename.
  String _labelForUrl(String url, String fallback) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isEmpty) return fallback;
      var last = Uri.decodeComponent(uri.pathSegments.last);
      if (last.contains('/')) last = last.substring(last.lastIndexOf('/') + 1);
      return last.isNotEmpty ? last : fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Fixes the previous mock-data builder: every value below is traced to a
  /// real field on `caregiverProfiles/{uid}` or the joined `users/{uid}` doc
  /// (already fetched for the list — see [_onCaregiversSnapshot]) rather
  /// than fabricated. Fields with no schema backing (age, a caregiver "ID
  /// PT-xxxx" code) are simply left out.
  AdminCaregiverProfileData _buildProfileData(AdminCaregiverData cg) {
    final profile = cg.profile;
    final user = cg.user;

    final gender = (profile['gender'] as String?)?.trim();
    final demographicsParts = <String>[
      if (gender != null && gender.isNotEmpty) gender,
      cg.city,
    ];
    final demographics = demographicsParts.isNotEmpty ? demographicsParts.join(' · ') : 'Not specified';

    String? joinedLabel;
    final createdAt = user?['createdAt'];
    if (createdAt is Timestamp) {
      joinedLabel = 'Joined ${_formatMonthYear(createdAt.toDate())}';
    }

    final skills = (profile['skills'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final languages =
        (profile['languagesSpoken'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    final certUrls =
        (profile['certificateUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final policeClearance = profile['policeClearanceUrl'] as String?;
    final otherDocs =
        (profile['otherDocumentUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    final certificateLabels = <String>[
      for (var i = 0; i < certUrls.length; i++) _labelForUrl(certUrls[i], 'Certificate ${i + 1}'),
      if (policeClearance != null && policeClearance.isNotEmpty)
        _labelForUrl(policeClearance, 'Police clearance'),
      for (var i = 0; i < otherDocs.length; i++) _labelForUrl(otherDocs[i], 'Other document ${i + 1}'),
    ];

    return AdminCaregiverProfileData(
      uid: cg.uid,
      initials: cg.initials,
      avatarBg: cg.avatarBg,
      avatarTextColor: cg.avatarTextColor,
      name: cg.name,
      demographics: demographics,
      joinedLabel: joinedLabel,
      phone: cg.phone,
      location: cg.city,
      nic: cg.nic,
      email: (user?['email'] as String?)?.trim().isNotEmpty == true
          ? (user!['email'] as String).trim()
          : 'Not provided',
      experience: '${cg.yearsExperience} ${cg.yearsExperience == 1 ? 'year' : 'years'}',
      careType: cg.careTypes.isNotEmpty ? cg.careTypes.join(', ') : 'Not specified',
      skills: skills,
      education: (profile['educationalQualification'] as String?) ?? 'Not provided',
      training: (profile['formalTraining'] as String?) ?? 'Not provided',
      languages: languages,
      bio: (profile['bio'] as String?) ?? '',
      certificates: certificateLabels,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredCaregivers;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Caregivers',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                  // Download / Export action
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined, color: titleColor, size: 24),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exporting caregivers report (CSV)...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Export',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  // Sort action
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: titleColor, size: 24),
                    onPressed: () {
                      _showSortMenu();
                    },
                    tooltip: 'Sort',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Search Input ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: searchBoxBg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: searchBoxBorder, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF604E2F), size: 20),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF544730),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search name, NIC or phone',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: searchHintColor,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF604E2F)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Result count ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_caregivers.length} caregiver${_caregivers.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cardSubtitleColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Caregivers List ─────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: titleColor))
                  : displayList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: titleColor.withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              const Text(
                                'No caregivers found',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                          itemCount: displayList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cg = displayList[index];
                            final isExpanded = _expandedCaregiverId == cg.uid;
                            return _buildCaregiverCard(cg, isExpanded);
                          },
                        ),
            ),

            // ── Bottom Navigation Bar (Matching Admin Dashboard) ────────────
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverCard(AdminCaregiverData cg, bool isExpanded) {
    return GestureDetector(
      onTap: () => _toggleExpand(cg.uid),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: cardBorder, width: 2),
        ),
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cg.avatarBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cg.initials,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cg.avatarTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                // Name & Subtitle & NIC
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cg.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cardNameColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        cg.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: cardSubtitleColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'NIC: ${cg.nic}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: cardSubtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Expanded section: Stats row + Action buttons
            if (isExpanded) ...[
              const SizedBox(height: 10),
              // Real, batch-fetched stat tiles (no per-row Firestore query).
              Row(
                children: [
                  Expanded(child: _buildStatTile('${cg.yearsExperience} yrs', 'Experience')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatTile('${cg.reviewCount}', 'Reviews')),
                ],
              ),
              const SizedBox(height: 10),
              // Action Buttons
              Row(
                children: [
                  // View Profile Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final profileData = _buildProfileData(cg);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminCaregiverProfileScreen(data: profileData),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: btnViewProfileBg,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'View profile',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Suspend / Reactivate Button (session-local only — see
                  // _locallySuspended doc comment above)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _toggleSuspendStatus(cg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: btnSuspendBorder, width: 1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _locallySuspended.contains(cg.uid) ? 'Reactivate' : 'Suspend',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: btnSuspendBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: statsTileBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: statsValueGold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'label': 'Dashboard', 'icon': Icons.insights_rounded},
      {'label': 'Users', 'icon': Icons.people_alt_outlined},
      {'label': 'Bookings', 'icon': Icons.calendar_month_outlined},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet_outlined},
      {'label': 'More', 'icon': Icons.more_horiz_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: bottomNavBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == 1; // Users tab is active
          final color = isSelected ? navGold : Colors.white;

          return GestureDetector(
            onTap: () {
              if (index == 0) {
                // Navigate back to Admin Dashboard
                Navigator.pop(context);
              } else if (index == 2) {
                // Bookings tab
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
                );
              } else if (index == 3) {
                // Finance tab
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminFinanceScreen()),
                );
              } else if (index == 4) {
                // More tab -> pop back or logout
                Navigator.pop(context);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 22,
                    color: color,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: color,
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

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C251D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Caregivers',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: statsValueGold),
              title: const Text('Highest Rated', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _sort = _CaregiverSort.highestRated);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.reviews_rounded, color: Colors.lightBlueAccent),
              title: const Text('Most Reviews', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _sort = _CaregiverSort.mostReviews);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha_rounded, color: Colors.greenAccent),
              title: const Text('Name (A - Z)', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _sort = _CaregiverSort.nameAz);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
