import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import 'admin_bookings_screen.dart';
import 'admin_finance_screen.dart';
import 'admin_patient_profile_screen.dart';

enum PatientAccountStatus { active, pending, suspended }

class AdminPatientData {
  final String id;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final String name;
  final int age;
  final String gender;
  final String location;
  final String patientCode; // e.g. 'PT-10428'
  final String joinedLabel; // e.g. 'Nov 2025'
  final Color spotlightAvatarBg;
  final Color spotlightAvatarTextColor;
  final String careType;
  final double rating;
  PatientAccountStatus status;
  final int bookings;
  final int cancellations;
  final int disputes;
  final String nic;
  final String phone;
  final String assignedCaregiver;
  final String conditions;

  AdminPatientData({
    required this.id,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.name,
    required this.age,
    required this.gender,
    required this.location,
    required this.patientCode,
    required this.joinedLabel,
    required this.spotlightAvatarBg,
    required this.spotlightAvatarTextColor,
    required this.careType,
    required this.rating,
    required this.status,
    required this.bookings,
    required this.cancellations,
    required this.disputes,
    required this.nic,
    required this.phone,
    required this.assignedCaregiver,
    required this.conditions,
  });

  String get demographics => '$age · $gender · $location';
  String get idLine => 'ID $patientCode · joined $joinedLabel';
  String get spotlightSubtitle => '$careType · $location · ${rating.toStringAsFixed(1)} ★';
}

class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  // ── Color Tokens matching Figma node 697:1059 ──────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);
  static const Color searchBoxBg = Color(0xFFFFF3DF);
  static const Color searchBoxBorder = Color(0xFFD6BA8B);
  static const Color searchHintColor = Color.fromRGBO(96, 78, 47, 0.45);
  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF766B58);
  static const Color identityNameColor = Color(0xFF403522);
  static const Color demoColor = Color(0xFF88795F);
  static const Color idColor = Color(0xFF625846);
  static const Color spotlightNameColor = Color(0xFF5C5445);
  static const Color spotlightSubtitleColor = Color(0xFF7C6F5D);
  static const Color statsTileBg = Color(0xFF44331C);
  static const Color statsValueGold = Color(0xFFFBBC05);
  static const Color btnViewProfileBg = Color(0xFF59341E);
  static const Color btnSuspendBorder = Color(0xFF59341E);
  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color navGold = Color(0xFFFBBC05);

  final TextEditingController _searchController = TextEditingController();
  String? _expandedPatientId = 'pt_1'; // First card spotlighted by default like Figma

  late List<AdminPatientData> _patients;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _initPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initPatients() {
    _patients = [
      AdminPatientData(
        id: 'pt_1',
        initials: 'AF',
        avatarBg: const Color(0xFFFAE48B),
        avatarTextColor: const Color(0xFF2E1065),
        name: 'Alice Fernando',
        age: 46,
        gender: 'Female',
        location: 'Negombo',
        patientCode: 'PT-10428',
        joinedLabel: 'Nov 2025',
        spotlightAvatarBg: const Color(0xFF727953),
        spotlightAvatarTextColor: const Color(0xFF313715),
        careType: 'Elder care',
        rating: 4.8,
        status: PatientAccountStatus.active,
        bookings: 8,
        cancellations: 2,
        disputes: 1,
        nic: '198578901234',
        phone: '+94 77 123 4567',
        assignedCaregiver: 'Sanduni Perera',
        conditions: 'Hypertension, mild arthritis',
      ),
      AdminPatientData(
        id: 'pt_2',
        initials: 'NA',
        avatarBg: const Color(0xFFFAE48B),
        avatarTextColor: const Color(0xFF2E1065),
        name: 'Nipuni Ariyathilaka',
        age: 72,
        gender: 'Female',
        location: 'Negombo',
        patientCode: 'PT-10429',
        joinedLabel: 'Nov 2025',
        spotlightAvatarBg: const Color(0xFF357F83),
        spotlightAvatarTextColor: Colors.white,
        careType: 'Post-surgery',
        rating: 4.6,
        status: PatientAccountStatus.active,
        bookings: 5,
        cancellations: 0,
        disputes: 0,
        nic: '195345671234',
        phone: '+94 71 987 6543',
        assignedCaregiver: 'Brian Kumara',
        conditions: 'Recovering from hip replacement',
      ),
      AdminPatientData(
        id: 'pt_3',
        initials: 'KP',
        avatarBg: const Color(0xFFD9BDB5),
        avatarTextColor: const Color(0xFF41302B),
        name: 'Kamal Perera',
        age: 68,
        gender: 'Male',
        location: 'Colombo 03',
        patientCode: 'PT-10430',
        joinedLabel: 'Oct 2025',
        spotlightAvatarBg: const Color(0xFFA28C66),
        spotlightAvatarTextColor: const Color(0xFF3B2404),
        careType: 'Dementia care',
        rating: 4.9,
        status: PatientAccountStatus.pending,
        bookings: 3,
        cancellations: 1,
        disputes: 0,
        nic: '195667894561',
        phone: '+94 76 345 6789',
        assignedCaregiver: 'Not yet assigned',
        conditions: 'Early-stage dementia',
      ),
      AdminPatientData(
        id: 'pt_4',
        initials: 'RJ',
        avatarBg: const Color(0xFFCBD5E1),
        avatarTextColor: const Color(0xFF354152),
        name: 'Ruwan Jayasuriya',
        age: 81,
        gender: 'Male',
        location: 'Seeduwa',
        patientCode: 'PT-10431',
        joinedLabel: 'Sep 2025',
        spotlightAvatarBg: const Color(0xFF354152),
        spotlightAvatarTextColor: const Color(0xFFCBD5E1),
        careType: 'Mobility support',
        rating: 4.2,
        status: PatientAccountStatus.suspended,
        bookings: 12,
        cancellations: 4,
        disputes: 2,
        nic: '194412345678',
        phone: '+94 70 876 5432',
        assignedCaregiver: 'Ruwan Jayasuriya (paused)',
        conditions: 'Limited mobility, uses walker',
      ),
      AdminPatientData(
        id: 'pt_5',
        initials: 'NW',
        avatarBg: const Color(0xFF6ED5C9),
        avatarTextColor: const Color(0xFF04302C),
        name: 'Nadeesha Wickrama',
        age: 59,
        gender: 'Female',
        location: 'Katunayake',
        patientCode: 'PT-10432',
        joinedLabel: 'Nov 2025',
        spotlightAvatarBg: const Color(0xFF6ED5C9),
        spotlightAvatarTextColor: const Color(0xFF04302C),
        careType: 'Elder care',
        rating: 4.9,
        status: PatientAccountStatus.active,
        bookings: 6,
        cancellations: 0,
        disputes: 0,
        nic: '196789012345',
        phone: '+94 78 567 8901',
        assignedCaregiver: 'Nadeesha Wickrama',
        conditions: 'Type 2 diabetes',
      ),
    ];
  }

  List<AdminPatientData> get _filteredPatients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _patients;
    return _patients.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.nic.toLowerCase().contains(query) ||
          p.phone.toLowerCase().contains(query) ||
          p.patientCode.toLowerCase().contains(query) ||
          p.location.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleExpand(String id) {
    setState(() {
      _expandedPatientId = _expandedPatientId == id ? null : id;
    });
  }

  void _toggleSuspendStatus(AdminPatientData p) {
    final isCurrentlySuspended = p.status == PatientAccountStatus.suspended;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isCurrentlySuspended ? 'Reactivate Patient?' : 'Suspend Patient?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          isCurrentlySuspended
              ? 'Are you sure you want to reactivate ${p.name}? They will be able to book caregivers again.'
              : 'Are you sure you want to suspend ${p.name}? They will not be able to make new booking requests.',
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
                p.status = isCurrentlySuspended ? PatientAccountStatus.active : PatientAccountStatus.suspended;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${p.name} has been ${isCurrentlySuspended ? 'reactivated' : 'suspended'}.'),
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

  void _openProfile(AdminPatientData p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPatientProfileScreen(
          data: AdminPatientProfileData(
            initials: p.initials,
            avatarColor: p.avatarBg,
            avatarTextColor: p.avatarTextColor,
            name: p.name,
            demographics: p.demographics,
            patientId: p.idLine,
            careType: p.careType,
            assignedCaregiver: p.assignedCaregiver,
            conditions: p.conditions,
            careCircle: const [],
            bookings: p.bookings,
            cancellations: p.cancellations,
            disputes: p.disputes,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredPatients;

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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Patient',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined, color: titleColor, size: 24),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exporting patients report (CSV)...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Export',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: titleColor, size: 24),
                    onPressed: _showSortMenu,
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
            const SizedBox(height: 14),

            // ── Patients List ───────────────────────────────────────────────
            Expanded(
              child: displayList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: titleColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          const Text(
                            'No patients found',
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
                        final p = displayList[index];
                        final isExpanded = _expandedPatientId == p.id;
                        return _buildPatientCard(p, isExpanded);
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

  Widget _buildPatientCard(AdminPatientData p, bool isExpanded) {
    if (!isExpanded) {
      // ── Collapsed "identity" card ─────────────────────────────────────
      return GestureDetector(
        onTap: () => _toggleExpand(p.id),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 1.5),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: p.avatarBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  p.initials,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: p.avatarTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: identityNameColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.demographics,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: demoColor,
                      ),
                    ),
                    Text(
                      p.idLine,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: idColor,
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

    // ── Expanded "spotlight" card with stats + actions ─────────────────────
    return GestureDetector(
      onTap: () => _toggleExpand(p.id),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: cardBorder, width: 2),
        ),
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: p.spotlightAvatarBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    p.initials,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.spotlightAvatarTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: spotlightNameColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        p.spotlightSubtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: spotlightSubtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(p.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildStatTile('${p.bookings}', 'Bookings')),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('${p.cancellations}', 'Cancellations')),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('${p.disputes}', 'Disputes')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openProfile(p),
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
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleSuspendStatus(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: btnSuspendBorder, width: 1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.status == PatientAccountStatus.suspended ? 'Reactivate' : 'Suspend',
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
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PatientAccountStatus status) {
    Color bg;
    Color textColor;
    String text;

    switch (status) {
      case PatientAccountStatus.active:
        bg = const Color.fromRGBO(78, 172, 0, 0.16);
        textColor = const Color(0xFF255010);
        text = 'ACTIVE';
        break;
      case PatientAccountStatus.pending:
        bg = const Color.fromRGBO(245, 158, 11, 0.16);
        textColor = const Color(0xFF6D490E);
        text = 'PENDING';
        break;
      case PatientAccountStatus.suspended:
        bg = const Color.fromRGBO(239, 68, 68, 0.16);
        textColor = const Color(0xFF822222);
        text = 'SUSPENDED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Widget _buildStatTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: statsTileBg, borderRadius: BorderRadius.circular(9)),
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
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
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
              if (index == 0 || index == 4) {
                Navigator.pop(context);
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminFinanceScreen()),
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, size: 22, color: color),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Patients',
              style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.event_busy_rounded, color: Color(0xFFEF4444)),
              title: const Text('Most Disputes', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _patients.sort((a, b) => b.disputes.compareTo(a.disputes)));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available_rounded, color: Colors.lightBlueAccent),
              title: const Text('Most Bookings', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _patients.sort((a, b) => b.bookings.compareTo(a.bookings)));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha_rounded, color: Colors.greenAccent),
              title: const Text('Name (A - Z)', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _patients.sort((a, b) => a.name.compareTo(b.name)));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
