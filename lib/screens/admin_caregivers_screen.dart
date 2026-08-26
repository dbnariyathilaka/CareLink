import 'package:flutter/material.dart';
import '../services/caregiver_service.dart';
import '../widgets/status_bar.dart';
import 'admin_caregiver_profile_screen.dart';

enum CaregiverStatus { active, pending, suspended }

class AdminCaregiverData {
  final String id;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final String name;
  final String careType;
  final String location;
  final double rating;
  final String nic;
  final String phone;
  CaregiverStatus status;
  final int shifts;
  final int reviews;
  final String earned;

  AdminCaregiverData({
    required this.id,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.name,
    required this.careType,
    required this.location,
    required this.rating,
    required this.nic,
    required this.phone,
    required this.status,
    required this.shifts,
    required this.reviews,
    required this.earned,
  });

  String get subtitle => '$careType · $location · ${rating.toStringAsFixed(1)} ★';
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
  static const Color filterChipActiveBg = Color(0xFF585247);
  static const Color filterChipInactiveBorder = Color(0xFF585247);
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

  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: Pending, 3: Suspended
  String? _expandedCaregiverId = 'cg_1'; // First card open by default like Figma

  late List<AdminCaregiverData> _caregivers;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _initCaregivers();
    _loadFirestoreCaregivers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initCaregivers() {
    _caregivers = [
      AdminCaregiverData(
        id: 'cg_1',
        initials: 'AF',
        avatarBg: const Color(0xFF727953),
        avatarTextColor: const Color(0xFF313715),
        name: 'Alice Fernando',
        careType: 'Elder care',
        location: 'Negombo',
        rating: 4.8,
        nic: '198578901234',
        phone: '+94 77 123 4567',
        status: CaregiverStatus.active,
        shifts: 142,
        reviews: 24,
        earned: '412k',
      ),
      AdminCaregiverData(
        id: 'cg_2',
        initials: 'BK',
        avatarBg: const Color(0xFF357F83),
        avatarTextColor: Colors.white,
        name: 'Brian Kumara',
        careType: 'Post-surgery',
        location: 'Negombo',
        rating: 4.5,
        nic: '199045671234',
        phone: '+94 71 987 6543',
        status: CaregiverStatus.pending,
        shifts: 38,
        reviews: 9,
        earned: '105k',
      ),
      AdminCaregiverData(
        id: 'cg_3',
        initials: 'SP',
        avatarBg: const Color(0xFFA28C66),
        avatarTextColor: const Color(0xFF3B2404),
        name: 'Sanduni Perera',
        careType: 'Dementia care',
        location: 'Ja-Ela',
        rating: 4.9,
        nic: '199267894561',
        phone: '+94 76 345 6789',
        status: CaregiverStatus.active,
        shifts: 185,
        reviews: 32,
        earned: '540k',
      ),
      AdminCaregiverData(
        id: 'cg_4',
        initials: 'RJ',
        avatarBg: const Color(0xFF354152),
        avatarTextColor: const Color(0xFFCBD5E1),
        name: 'Ruwan Jayasuriya',
        careType: 'Mobility',
        location: 'Seeduwa',
        rating: 4.2,
        nic: '198812345678',
        phone: '+94 70 876 5432',
        status: CaregiverStatus.suspended,
        shifts: 64,
        reviews: 11,
        earned: '180k',
      ),
      AdminCaregiverData(
        id: 'cg_5',
        initials: 'NW',
        avatarBg: const Color(0xFF6ED5C9),
        avatarTextColor: const Color(0xFF04302C),
        name: 'Nadeesha Wickrama',
        careType: 'Elder care',
        location: 'Katunayake',
        rating: 4.9,
        nic: '199489012345',
        phone: '+94 78 567 8901',
        status: CaregiverStatus.active,
        shifts: 96,
        reviews: 18,
        earned: '290k',
      ),
    ];
  }

  Future<void> _loadFirestoreCaregivers() async {
    try {
      final dbCaregivers = await CaregiverService.searchCaregivers();
      if (dbCaregivers.isNotEmpty && mounted) {
        // Merge real caregivers if present
        setState(() {
          for (final cg in dbCaregivers) {
            final uid = cg['uid'] as String? ?? '';
            final name = cg['name'] as String? ?? 'Caregiver';
            if (!_caregivers.any((c) => c.id == uid || c.name == name)) {
              final initials = _getInitials(name);
              _caregivers.add(
                AdminCaregiverData(
                  id: uid,
                  initials: initials,
                  avatarBg: const Color(0xFF727953),
                  avatarTextColor: const Color(0xFF313715),
                  name: name,
                  careType: (cg['careTypes'] as List?)?.firstOrNull?.toString() ?? 'Elder care',
                  location: cg['city'] as String? ?? 'Western Province',
                  rating: (cg['rating'] as num?)?.toDouble() ?? 4.8,
                  nic: cg['nic'] as String? ?? 'Verified',
                  phone: cg['phone'] as String? ?? '+94 7X XXX XXXX',
                  status: (cg['isVerified'] == true)
                      ? CaregiverStatus.active
                      : CaregiverStatus.pending,
                  shifts: (cg['completedJobs'] as num?)?.toInt() ?? 12,
                  reviews: (cg['reviewCount'] as num?)?.toInt() ?? 5,
                  earned: '${((cg['totalEarnings'] as num?)?.toInt() ?? 45)}k',
                ),
              );
            }
          }
        });
      }
    } catch (_) {}
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CG';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  List<AdminCaregiverData> get _filteredCaregivers {
    final query = _searchController.text.trim().toLowerCase();
    return _caregivers.where((cg) {
      // Filter tab check
      if (_selectedFilterIndex == 1 && cg.status != CaregiverStatus.active) return false;
      if (_selectedFilterIndex == 2 && cg.status != CaregiverStatus.pending) return false;
      if (_selectedFilterIndex == 3 && cg.status != CaregiverStatus.suspended) return false;

      // Search query check
      if (query.isNotEmpty) {
        final matchesName = cg.name.toLowerCase().contains(query);
        final matchesNic = cg.nic.toLowerCase().contains(query);
        final matchesPhone = cg.phone.toLowerCase().contains(query);
        final matchesLocation = cg.location.toLowerCase().contains(query);
        final matchesCareType = cg.careType.toLowerCase().contains(query);
        if (!matchesName && !matchesNic && !matchesPhone && !matchesLocation && !matchesCareType) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedCaregiverId == id) {
        _expandedCaregiverId = null;
      } else {
        _expandedCaregiverId = id;
      }
    });
  }

  void _toggleSuspendStatus(AdminCaregiverData cg) {
    final isCurrentlySuspended = cg.status == CaregiverStatus.suspended;
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
                cg.status = isCurrentlySuspended ? CaregiverStatus.active : CaregiverStatus.suspended;
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

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredCaregivers;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
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
                  // Filter / sort action
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: titleColor, size: 24),
                    onPressed: () {
                      _showFilterSortMenu();
                    },
                    tooltip: 'Filter',
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

            // ── Filter Chips Row ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  _buildFilterChip(0, 'All ${_caregivers.length}'),
                  const SizedBox(width: 7),
                  _buildFilterChip(1, 'Active'),
                  const SizedBox(width: 7),
                  _buildFilterChip(2, 'Pending'),
                  const SizedBox(width: 7),
                  _buildFilterChip(3, 'Suspended'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Caregivers List ─────────────────────────────────────────────
            Expanded(
              child: displayList.isEmpty
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
                        final isExpanded = _expandedCaregiverId == cg.id;
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

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? filterChipActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? filterChipActiveBg : filterChipInactiveBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : filterChipInactiveBorder,
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverCard(AdminCaregiverData cg, bool isExpanded) {
    return GestureDetector(
      onTap: () => _toggleExpand(cg.id),
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
            // Top Row: Avatar + Info + Badge
            Row(
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
                // Name & Subtitle
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
                    ],
                  ),
                ),
                // Status Badge
                _buildStatusBadge(cg.status),
              ],
            ),

            // Expanded section: Stats row + Action buttons
            if (isExpanded) ...[
              const SizedBox(height: 10),
              // 3 Dark Stat Tiles
              Row(
                children: [
                  Expanded(child: _buildStatTile('${cg.shifts}', 'Shifts')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatTile('${cg.reviews}', 'Reviews')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatTile(cg.earned, 'Earned')),
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
                        final profileData = AdminCaregiverProfileData(
                          initials: cg.initials,
                          avatarBg: cg.avatarBg,
                          avatarTextColor: cg.avatarTextColor,
                          name: cg.name,
                          demographics: '46 · Female · ${cg.location}',
                          caregiverId: 'ID PT-10428 · joined Nov 2025',
                          phone: cg.phone,
                          location: '${cg.location}, Western Province',
                          nic: cg.nic,
                          email: '${cg.name.toLowerCase().replaceAll(' ', '')}@gmail.com',
                          experience: '5 years',
                          careType: cg.careType,
                          skills: const ['Mobility assistance', 'Medication management', 'Dementia care'],
                          education: 'Diploma',
                          training: 'Not set',
                          languages: const ['Sinhala', 'English'],
                          bio: 'Compassionate ${cg.careType.toLowerCase()} nurse with 5 years supporting families across ${cg.location} and Western Province. I specialise in dementia and post-surgery recovery.',
                          certificates: const ['Caregiving Diploma.pdf', 'First Aid Certificate.pdf'],
                        );

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
                  // Suspend / Reactivate Button
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
                          cg.status == CaregiverStatus.suspended ? 'Reactivate' : 'Suspend',
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

  Widget _buildStatusBadge(CaregiverStatus status) {
    Color bg;
    Color textColor;
    String text;

    switch (status) {
      case CaregiverStatus.active:
        bg = const Color.fromRGBO(78, 172, 0, 0.16);
        textColor = const Color(0xFF255010);
        text = 'ACTIVE';
        break;
      case CaregiverStatus.pending:
        bg = const Color.fromRGBO(245, 158, 11, 0.16);
        textColor = const Color(0xFF6D490E);
        text = 'PENDING';
        break;
      case CaregiverStatus.suspended:
        bg = const Color.fromRGBO(239, 68, 68, 0.16);
        textColor = const Color(0xFF822222);
        text = 'SUSPENDED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
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

  void _showFilterSortMenu() {
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
                setState(() {
                  _caregivers.sort((a, b) => b.rating.compareTo(a.rating));
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_history_rounded, color: Colors.lightBlueAccent),
              title: const Text('Most Shifts Completed', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _caregivers.sort((a, b) => b.shifts.compareTo(a.shifts));
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha_rounded, color: Colors.greenAccent),
              title: const Text('Name (A - Z)', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _caregivers.sort((a, b) => a.name.compareTo(b.name));
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
