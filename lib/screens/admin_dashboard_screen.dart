import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';
import '../services/review_service.dart';
import '../widgets/status_bar.dart';
import 'admin_bookings_screen.dart';
import 'admin_caregivers_screen.dart';
import 'admin_content_taxonomy_screen.dart';
import 'admin_finance_screen.dart';
import 'admin_patients_screen.dart';
import 'admin_pricing_screen.dart';
import 'admin_review_moderation_screen.dart';
import 'admin_support_hub_screen.dart';
import 'admin_verification_queue_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentNavIndex = 0;
  bool _showMoreMenu = false;

  // Real dashboard stats — null while still loading.
  String _adminName = 'Admin';
  int? _activeCaregivers;
  int? _activePatients;
  double? _avgRating;
  int? _ratingCount;
  int? _unfulfilledCount;
  int? _docsSubmittedCount;
  int? _bookingsThisMonth;
  Map<int, int>? _weekdayBookingCounts;

  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color headerBg = Color(0xFF766B58);
  static const Color statPillBg = Color.fromRGBO(207, 192, 165, 0.16);
  static const Color gmvGold = Color(0xFFF5DBB2);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color avatarBg = Color(0xFFD2D3D2);

  // Needs Attention Colors
  static const Color incidentBg = Color(0xFFE2C6C6);
  static const Color incidentBorder = Color(0xFFE65555);
  static const Color incidentTitle = Color(0xFFD83131);
  static const Color incidentSubtitle = Color(0xFFA27070);

  static const Color docBg = Color(0xFFA5A7AC);
  static const Color docBorder = Color(0xFF001C58);
  static const Color docTitle = Color(0xFF001C58);
  static const Color docSubtitle = Color(0xFF434958);

  static const Color requestBg = Color(0xFF979F8E);
  static const Color requestBorder = Color(0xFF2E4F09);
  static const Color requestTitle = Color(0xFF3B5A18);
  static const Color requestSubtitle = Color(0xFFCBE0AF);

  // Operations Colors
  static const Color opCardBg = Color(0xFFA89F90);
  static const Color opValueColor = Color(0xFF47381E);
  static const Color opLabelColor = Color.fromRGBO(83, 64, 39, 0.77);
  static const Color starGold = Color(0xFFB28502);

  // Bookings Chart Colors
  static const Color chartBg = Color(0xFFFFEFD5);
  static const Color chartBorder = Color(0xFF44331C);
  static const Color weekdayBarColor = Color(0xFF937441);
  static const Color weekendBarColor = Color(0xFFFFC76C);

  // Bottom Nav
  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color activeGold = Color(0xFFFBBC05);
  static const double bottomNavHeight = 64;

  // "More" popup
  static const Color moreMenuBg = Color(0xFF2C251D);
  static const Color moreMenuItemBg = Color(0xFF4A4032);

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      final profile = await AuthService.getUserProfile(uid);
      final name = (profile?['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty && mounted) {
        setState(() => _adminName = name);
      }
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final activeCaregivers = await CaregiverService.countAll();
    final activePatients = await PatientService.countAll();
    final rating = await ReviewService.fetchPlatformAverage();
    final unfulfilled = await BookingService.countUnfulfilled();
    final docsSubmitted = await CaregiverService.countWithSubmittedDocuments();
    final bookingsThisMonth = await BookingService.countCreatedSince(startOfMonth);
    final weekdayCounts = await BookingService.countBookingsByWeekdayLast7Days();

    if (!mounted) return;
    setState(() {
      _activeCaregivers = activeCaregivers;
      _activePatients = activePatients;
      _avgRating = rating.avg;
      _ratingCount = rating.count;
      _unfulfilledCount = unfulfilled;
      _docsSubmittedCount = docsSubmitted;
      _bookingsThisMonth = bookingsThisMonth;
      _weekdayBookingCounts = weekdayCounts;
    });
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Admin Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to sign out from the Admin Dashboard?',
          style: TextStyle(color: Color(0xFFD4CDC3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: incidentBorder,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // There is no incident-tracking collection anywhere in the app yet — this
  // is an honest empty state rather than a fabricated incident list.
  void _showIncidentDetails() {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: incidentBorder.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: incidentBorder),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Incident tracking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Incident tracking isn\'t implemented yet — there\'s no data source to show here.',
              style: TextStyle(color: Color(0xFFD4CDC3), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDocumentVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminVerificationQueueScreen(),
      ),
    );
  }

  // Opens Bookings pre-filtered to "Unfulfilled" and, once the admin comes
  // back, makes sure the footer highlights Dashboard again (not Bookings).
  void _openUnfulfilledBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminBookingsScreen(initialFilter: BookingFilter.unfulfilled),
      ),
    ).then((_) => setState(() => _currentNavIndex = 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Top Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        _buildHeader(),

                        const SizedBox(height: 20),

                        // Needs Attention Section
                        _buildSectionHeader('NEEDS ATTENTION'),
                        const SizedBox(height: 8),
                        _buildNeedsAttention(),

                        const SizedBox(height: 22),

                        // Operations Section
                        _buildSectionHeader('OPERATIONS'),
                        const SizedBox(height: 8),
                        _buildOperationsGrid(),

                        const SizedBox(height: 22),

                        // Bookings · Last 7 Days Section
                        _buildSectionHeader('BOOKINGS · LAST 7 DAYS'),
                        const SizedBox(height: 8),
                        _buildBookingsChart(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation Bar
                _buildBottomNav(),
              ],
            ),

            // Scrim behind the "More" popup, dismisses on tap
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_showMoreMenu,
                child: AnimatedOpacity(
                  opacity: _showMoreMenu ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: GestureDetector(
                    onTap: () => setState(() => _showMoreMenu = false),
                    child: Container(color: Colors.black.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            ),

            // "More" popup — replaces the footer while open, so the footer's
            // own tabs never show through underneath it.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: !_showMoreMenu,
                child: AnimatedSlide(
                  offset: _showMoreMenu ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _showMoreMenu ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: _buildMoreMenuPanel(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: CARELINK ADMIN + Name & BK Avatar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CARELINK ADMIN',
                          style: TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _adminName,
                          style: const TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar with popup menu for logout
                  GestureDetector(
                    onTap: _handleLogout,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: avatarBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initialsFor(_adminName),
                          style: const TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: darkGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Two Stat Pill Cards — GMV has no backing anywhere (billing
              // was fully removed from this app), so it's shown as an
              // honest "not tracked" state rather than a fabricated figure.
              // The second pill shows a real, live count instead.
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderPill(
                      label: 'GMV this month',
                      value: 'Not tracked',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeaderPill(
                      label: 'Bookings this month',
                      value: _bookingsThisMonth?.toString() ?? '—',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statPillBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Quattrocento Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Quattrocento Sans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: gmvGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildNeedsAttention() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 1. Incidents — no incident-tracking data source exists anywhere
          // in the app, so this honestly says so rather than showing a
          // fabricated count.
          _buildAlertCard(
            bgColor: incidentBg,
            borderColor: incidentBorder,
            title: 'Incident tracking not available',
            titleColor: incidentTitle,
            subtitle: 'Not implemented yet',
            subtitleColor: incidentSubtitle,
            icon: Icons.gpp_maybe_rounded,
            iconColor: const Color(0xFFB71C1C),
            onTap: _showIncidentDetails,
          ),
          const SizedBox(height: 8),

          // 2. Documents — real count of caregivers who've submitted at
          // least one document. There's no per-document review-status field
          // anywhere, so the subtitle doesn't claim a turnaround time.
          _buildAlertCard(
            bgColor: docBg,
            borderColor: docBorder,
            title: _docsSubmittedCount != null
                ? '${_docsSubmittedCount!} caregivers with documents submitted'
                : 'Loading document submissions…',
            titleColor: docTitle,
            subtitle: 'Awaiting manual review',
            subtitleColor: docSubtitle,
            icon: Icons.folder_open_rounded,
            iconColor: docBorder,
            onTap: _showDocumentVerification,
          ),
          const SizedBox(height: 8),

          // 3. Unfulfilled Requests — real count of requests with no
          // caregiver matched yet.
          _buildAlertCard(
            bgColor: requestBg,
            borderColor: requestBorder,
            title: _unfulfilledCount != null
                ? '${_unfulfilledCount!} unfulfilled requests'
                : 'Loading requests…',
            titleColor: requestTitle,
            subtitle: 'No caregiver matched yet',
            subtitleColor: requestSubtitle,
            icon: Icons.groups_rounded,
            iconColor: requestBorder,
            onTap: _openUnfulfilledBookings,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required Color bgColor,
    required Color borderColor,
    required String title,
    required Color titleColor,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: titleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildOperationCard(
                  value: _activeCaregivers?.toString() ?? '—',
                  label: 'Active caregivers',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _buildOperationCard(
                  value: _activePatients?.toString() ?? '—',
                  label: 'Active patients',
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              // No "matched at" timestamp is ever recorded anywhere in the
              // schema, so match time can't be derived — honest "not
              // tracked" state instead of a fabricated figure.
              Expanded(
                child: _buildOperationCard(
                  value: 'Not tracked',
                  label: 'Avg match time',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _buildOperationCard(
                  value: _avgRating != null
                      ? (_ratingCount == 0
                          ? 'No reviews'
                          : '${_avgRating!.toStringAsFixed(1)} ★')
                      : '—',
                  label: 'Avg rating',
                  valueColor: starGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard({
    required String value,
    required String label,
    Color valueColor = opValueColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: opCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: opLabelColor,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsChart() {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // Mon..Sun
    final counts = _weekdayBookingCounts;
    final maxCount = counts == null
        ? 0
        : counts.values.fold<int>(0, (a, b) => a > b ? a : b);

    final barsData = List.generate(7, (i) {
      final weekday = i + 1; // 1=Mon..7=Sun
      final count = counts?[weekday] ?? 0;
      final height = counts == null
          ? 4.0
          : (maxCount == 0 ? 4.0 : (count / maxCount) * 70.0).clamp(4.0, 70.0);
      return {
        'day': dayLabels[i],
        'height': height,
        'isWeekend': weekday == 6 || weekday == 7,
      };
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: chartBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: chartBorder, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: barsData.map((item) {
            final day = item['day'] as String;
            final height = item['height'] as double;
            final isWeekend = item['isWeekend'] as bool;
            final barColor = isWeekend ? weekendBarColor : weekdayBarColor;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 37,
                  height: height,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  day,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: chartBorder,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'label': 'Dashboard', 'icon': Icons.home_rounded},
      {'label': 'Users', 'icon': Icons.people_alt_outlined},
      {'label': 'Bookings', 'icon': Icons.event_available_outlined},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet_outlined},
      {'label': 'More', 'icon': Icons.more_horiz_rounded},
    ];

    return Container(
      height: bottomNavHeight,
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
          final isSelected = !_showMoreMenu && _currentNavIndex == index;
          final color = isSelected ? activeGold : Colors.white;

          return GestureDetector(
            onTap: () {
              if (index == 4) {
                // More tab — pop out the extra options panel above the footer
                setState(() => _showMoreMenu = true);
              } else {
                setState(() => _currentNavIndex = index);
                if (index == 1) {
                  // Users tab — show the Select User picker first
                  _showSelectUserSheet();
                } else if (index == 2) {
                  // Bookings tab — defaults to the Active section
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminBookingsScreen(initialFilter: BookingFilter.active),
                    ),
                  ).then((_) => setState(() => _currentNavIndex = 0));
                } else if (index == 3) {
                  // Finance tab
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminFinanceScreen()),
                  ).then((_) => setState(() => _currentNavIndex = 0));
                }
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

  // ── "More" popup (Figma node 698:1456) ──────────────────────────────────
  // Pops out from directly above the footer, showing extra nav destinations
  // in a 2x4 grid. Dashboard/Users/Bookings/Finance mirror the footer tabs;
  // Review/Pricing/Support/Content are additional admin sections.
  void _closeMoreMenu() => setState(() => _showMoreMenu = false);

  void _handleMoreMenuTap(int? navIndex, {String? comingSoonLabel}) {
    _closeMoreMenu();
    if (navIndex != null) {
      setState(() => _currentNavIndex = navIndex);
      if (navIndex == 1) {
        _showSelectUserSheet();
      } else if (navIndex == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminBookingsScreen(initialFilter: BookingFilter.active),
          ),
        ).then((_) => setState(() => _currentNavIndex = 0));
      } else if (navIndex == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminFinanceScreen()),
        ).then((_) => setState(() => _currentNavIndex = 0));
      }
    } else if (comingSoonLabel == 'Review') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminReviewModerationScreen()),
      );
    } else if (comingSoonLabel == 'Pricing') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminPricingScreen()),
      );
    } else if (comingSoonLabel == 'Support') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminSupportHubScreen()),
      );
    } else if (comingSoonLabel == 'Content') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminContentTaxonomyScreen()),
      );
    } else if (comingSoonLabel != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$comingSoonLabel coming soon'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildMoreMenuPanel() {
    final items = <Map<String, dynamic>>[
      {'label': 'Dashboard', 'icon': Icons.home_rounded, 'navIndex': 0},
      {'label': 'Users', 'icon': Icons.people_alt_outlined, 'navIndex': 1},
      {'label': 'Bookings', 'icon': Icons.event_available_outlined, 'navIndex': 2},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet_outlined, 'navIndex': 3},
      {'label': 'Review', 'icon': Icons.rate_review_outlined, 'navIndex': null},
      {'label': 'Pricing', 'icon': Icons.sell_outlined, 'navIndex': null},
      {'label': 'Support', 'icon': Icons.support_agent_outlined, 'navIndex': null},
      {'label': 'Content', 'icon': Icons.auto_awesome_outlined, 'navIndex': null},
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: moreMenuBg.withValues(alpha: 0.96),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _closeMoreMenu,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFB5ADA2), size: 22),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: items.sublist(0, 4).map((item) => _buildMoreMenuItem(item)).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: items.sublist(4, 8).map((item) => _buildMoreMenuItem(item)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenuItem(Map<String, dynamic> item) {
    final int? navIndex = item['navIndex'] as int?;
    final bool isSelected = navIndex != null && navIndex == _currentNavIndex;
    final color = isSelected ? activeGold : Colors.white;

    return GestureDetector(
      onTap: () => _handleMoreMenuTap(navIndex, comingSoonLabel: item['label'] as String),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected ? activeGold.withValues(alpha: 0.18) : moreMenuItemBg,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: activeGold, width: 1.5) : null,
              ),
              child: Icon(item['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(height: 6),
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
  }

  // ── Select User popup (Figma node 683:706) ─────────────────────────────
  // Shown first when admin taps "Users" — lets them pick Patient or Caregiver
  // before drilling into the relevant user list.
  void _showSelectUserSheet() {
    String selected = 'patient'; // default selection

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5EEE8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                  bottomLeft: Radius.circular(42),
                  bottomRight: Radius.circular(42),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.5),
                    blurRadius: 25,
                    offset: Offset(0, -20),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Woman avatar illustration — same asset used on the
                  // "who needs care" sheet, matching Figma node 683:706.
                  Image.asset(
                    'assets/images/who_needs_care_avatar.png',
                    width: 68,
                    height: 68,
                  ),
                  const SizedBox(height: 14),
                  // Title
                  const Text(
                    'Select User',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color(0xFF564732),
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  const Text(
                    'Select the user type who you want to find out',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color.fromRGBO(85, 73, 57, 0.63),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Patient option
                  _buildUserTypeOption(
                    label: 'patient',
                    description: 'Person who use app for find a caregiver',
                    icon: Icons.self_improvement_rounded,
                    iconBg: const Color(0xFFD9BDB5),
                    iconColor: const Color(0xFF41302B),
                    cardBg: const Color(0xFFAB9089),
                    borderColor: const Color(0xFF5A413A),
                    labelColor: const Color(0xFF352D2A),
                    descColor: const Color.fromRGBO(57, 42, 27, 0.43),
                    radioColor: const Color(0xFF352D2A),
                    isSelected: selected == 'patient',
                    onTap: () => setSheetState(() => selected = 'patient'),
                  ),
                  const SizedBox(height: 12),
                  // Caregiver option
                  _buildUserTypeOption(
                    label: 'Caregiver',
                    description: 'Person who give service for patients',
                    icon: Icons.family_restroom_rounded,
                    iconBg: const Color.fromRGBO(133, 107, 74, 0.54),
                    iconColor: const Color(0xFF4B381F),
                    cardBg: const Color(0xFFB1A28F),
                    borderColor: const Color(0xFF44392B),
                    labelColor: const Color(0xFF4B381F),
                    descColor: const Color.fromRGBO(58, 39, 14, 0.52),
                    radioColor: const Color(0xFF4B381F),
                    isSelected: selected == 'caregiver',
                    onTap: () => setSheetState(() => selected = 'caregiver'),
                  ),
                  const SizedBox(height: 28),
                  // Continue button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (selected == 'caregiver') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminCaregiversScreen(),
                          ),
                        ).then((_) => setState(() => _currentNavIndex = 0));
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminPatientsScreen(),
                          ),
                        ).then((_) => setState(() => _currentNavIndex = 0));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF746553),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => setState(() => _currentNavIndex = 0));
  }

  Widget _buildUserTypeOption({
    required String label,
    required String description,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
    required Color labelColor,
    required Color descColor,
    required Color radioColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            // Icon tile
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            // Label + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: labelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: descColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: radioColor, width: 1.5),
                color: isSelected ? radioColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, color: Colors.white, size: 10)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
