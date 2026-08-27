import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import 'admin_finance_screen.dart';

enum BookingFilter { unfulfilled, active, upcoming, cancelled }

class AdminBookingData {
  final String id;
  final BookingFilter status;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final String title;
  final String subtitle;
  final String? waitingLabel; // e.g. "18 min" (unfulfilled)
  final int? progressPercent; // e.g. 64 (active / on-duty)
  final String? penaltyNote; // (cancelled)

  const AdminBookingData({
    required this.id,
    required this.status,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.title,
    required this.subtitle,
    this.waitingLabel,
    this.progressPercent,
    this.penaltyNote,
  });
}

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  // ── Color Tokens matching Figma node 641:514 ────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);

  static const Color filterActiveBg = Color(0xFF585247);
  static const Color filterActiveFg = Colors.white;
  static const Color filterInactiveBorder = Color(0xFF585247);

  static const Color emergencyBg = Color(0x17EF4444); // ~9%
  static const Color emergencyBorder = Color(0x59EF4444); // ~35%
  static const Color emergencyTitle = Color(0xFFEF4444);
  static const Color emergencyWaiting = Color(0xFF6D6B3B);
  static const Color emergencyName = Color(0xFF73513F);
  static const Color emergencySubtitle = Color(0xFF816A52);
  static const Color reviewBtnBg = Color(0xFFEF4444);

  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF412800);
  static const Color cardTitle = Color(0xFF544730);
  static const Color cardSubtitle = Color(0xFFFCE8C3);

  static const Color onDutyBadgeBg = Color(0x2922C55E);
  static const Color onDutyBadgeFg = Color(0xFF2B4A11);
  static const Color upcomingBadgeBg = Color(0x290EA5E9);
  static const Color upcomingBadgeFg = Color(0xFF1C5F7C);

  static const Color progressTrack = Color(0xFF44331C);
  static const Color progressFill = Color(0xFF82571E);
  static const Color progressLabel = Color(0xFF785618);

  static const Color penaltyBannerBg = Color(0xFF412800);
  static const Color applyPenaltyBtnBg = Color(0xFFAC703F);
  static const Color applyPenaltyBtnFg = Color(0xFF37200D);
  static const Color waiveBtnBorder = Color(0xFFAC703F);

  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color navGold = Color(0xFFFBBC05);

  BookingFilter _activeFilter = BookingFilter.unfulfilled;

  final List<AdminBookingData> _bookings = const [
    AdminBookingData(
      id: 'bk_1',
      status: BookingFilter.unfulfilled,
      initials: '',
      avatarBg: Colors.transparent,
      avatarTextColor: Colors.transparent,
      title: 'Kamal Perera · Post-surgery',
      subtitle: 'Today 7:00 PM – 9:00 PM · Nugegoda · 3 caregivers declined',
      waitingLabel: '18 min',
    ),
    AdminBookingData(
      id: 'bk_2',
      status: BookingFilter.unfulfilled,
      initials: '',
      avatarBg: Colors.transparent,
      avatarTextColor: Colors.transparent,
      title: 'Mala Herath · Dementia care',
      subtitle: 'Tomorrow 8:00 AM – 12:00 PM · Ja-Ela · 1 caregiver declined',
      waitingLabel: '42 min',
    ),
    AdminBookingData(
      id: 'bk_3',
      status: BookingFilter.active,
      initials: 'AF',
      avatarBg: Color(0xFF784B26),
      avatarTextColor: Color(0xFFFBBC05),
      title: 'Alice Fernando → Nipuni A.',
      subtitle: 'Elder care · 8:00 AM – 6:00 PM',
      progressPercent: 64,
    ),
    AdminBookingData(
      id: 'bk_4',
      status: BookingFilter.active,
      initials: 'BK',
      avatarBg: Color(0xFF357F83),
      avatarTextColor: Colors.white,
      title: 'Brian Kumara → Kamal P.',
      subtitle: 'Post-surgery · 9:00 AM – 5:00 PM',
      progressPercent: 30,
    ),
    AdminBookingData(
      id: 'bk_5',
      status: BookingFilter.upcoming,
      initials: 'SP',
      avatarBg: Color(0xFF784B26),
      avatarTextColor: Color(0xFFFBBC05),
      title: 'Sanduni P. → Ishara P.',
      subtitle: 'Dementia · Wed 17 Dec · Live-in',
    ),
    AdminBookingData(
      id: 'bk_6',
      status: BookingFilter.upcoming,
      initials: 'NW',
      avatarBg: Color(0xFF6ED5C9),
      avatarTextColor: Color(0xFF04302C),
      title: 'Nadeesha W. → Kamal P.',
      subtitle: 'Elder care · Fri 19 Dec · 8:00 AM – 4:00 PM',
    ),
    AdminBookingData(
      id: 'bk_7',
      status: BookingFilter.cancelled,
      initials: 'DR',
      avatarBg: Color(0xFF784B26),
      avatarTextColor: Color(0xFFFBBC05),
      title: 'David R. → Mala Perera',
      subtitle: 'Cancelled 4h before start · caregiver no-show',
      penaltyNote: 'Late-cancellation rule: LKR 1,500 penalty, patient refunded in full',
    ),
    AdminBookingData(
      id: 'bk_8',
      status: BookingFilter.cancelled,
      initials: 'RJ',
      avatarBg: Color(0xFF354152),
      avatarTextColor: Color(0xFFCBD5E1),
      title: 'Ruwan J. → Nadeesha W.',
      subtitle: 'Cancelled 1d before start · patient request',
      penaltyNote: 'Cancelled within policy window — no penalty applies',
    ),
  ];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  int _countFor(BookingFilter f) => _bookings.where((b) => b.status == f).length;

  List<AdminBookingData> get _filteredBookings =>
      _bookings.where((b) => b.status == _activeFilter).toList();

  void _reviewEmergency(AdminBookingData b) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening emergency review for ${b.title}...'), duration: const Duration(seconds: 2)),
    );
  }

  void _applyPenalty(AdminBookingData b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apply Penalty & Refund?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          b.penaltyNote ?? 'Apply the cancellation penalty and issue a full refund to the patient.',
          style: const TextStyle(color: Color(0xFFC4BBAC), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: applyPenaltyBtnBg),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Penalty applied and refund issued for ${b.title}.'), duration: const Duration(seconds: 2)),
              );
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _waivePenalty(AdminBookingData b) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Penalty waived for ${b.title}.'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredBookings.isEmpty
                  ? Center(
                      child: Text(
                        'No bookings in this category',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                      itemCount: _filteredBookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 11),
                      itemBuilder: (context, index) => _buildBookingCard(_filteredBookings[index]),
                    ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
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
              'Bookings',
              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: titleColor),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: titleColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text(
            'Live',
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: titleColor),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ──────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    final filters = [
      (BookingFilter.unfulfilled, 'Unfulfilled ${_countFor(BookingFilter.unfulfilled)}'),
      (BookingFilter.active, 'Active ${_countFor(BookingFilter.active)}'),
      (BookingFilter.upcoming, 'Upcoming'),
      (BookingFilter.cancelled, 'Cancelled'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Wrap(
        spacing: 7,
        runSpacing: 8,
        children: filters.map((f) {
          final isActive = _activeFilter == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? filterActiveBg : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: filterInactiveBorder, width: isActive ? 0 : 1),
              ),
              child: Text(
                f.$2,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? filterActiveFg : filterInactiveBorder,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Booking cards ───────────────────────────────────────────────────────
  Widget _buildBookingCard(AdminBookingData b) {
    switch (b.status) {
      case BookingFilter.unfulfilled:
        return _buildEmergencyCard(b);
      case BookingFilter.active:
        return _buildActiveCard(b);
      case BookingFilter.upcoming:
        return _buildUpcomingCard(b);
      case BookingFilter.cancelled:
        return _buildCancelledCard(b);
    }
  }

  Widget _buildEmergencyCard(AdminBookingData b) {
    return Container(
      decoration: BoxDecoration(
        color: emergencyBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: emergencyBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: emergencyTitle),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Unassigned · emergency',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: emergencyTitle),
                ),
              ),
              if (b.waitingLabel != null)
                Text(
                  b.waitingLabel!,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: emergencyWaiting),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            b.title,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: emergencyName),
          ),
          const SizedBox(height: 2),
          Text(
            b.subtitle,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w500, color: emergencySubtitle),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: reviewBtnBg,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _reviewEmergency(b),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Center(
                    child: Text(
                      'Review',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(AdminBookingData b) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeaderRow(b, badgeBg: onDutyBadgeBg, badgeFg: onDutyBadgeFg, badgeText: 'ON DUTY'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        Container(color: progressTrack),
                        FractionallySizedBox(
                          widthFactor: (b.progressPercent ?? 0) / 100,
                          child: Container(color: progressFill),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${b.progressPercent}%',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: progressLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(AdminBookingData b) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(13),
      child: _buildCardHeaderRow(b, badgeBg: upcomingBadgeBg, badgeFg: upcomingBadgeFg, badgeText: 'UPCOMING'),
    );
  }

  Widget _buildCancelledCard(AdminBookingData b) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeaderRow(b),
          if (b.penaltyNote != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(color: penaltyBannerBg, borderRadius: BorderRadius.circular(9)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      b.penaltyNote!,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: applyPenaltyBtnBg,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => _applyPenalty(b),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            'Apply penalty & refund',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: applyPenaltyBtnFg),
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
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => _waivePenalty(b),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: waiveBtnBorder, width: 1),
                        ),
                        child: const Center(
                          child: Text(
                            'Waive',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: waiveBtnBorder),
                          ),
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
    );
  }

  Widget _buildCardHeaderRow(AdminBookingData b, {Color? badgeBg, Color? badgeFg, String? badgeText}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: b.avatarBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            b.initials,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: b.avatarTextColor),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.title,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, fontWeight: FontWeight.w700, color: cardTitle),
              ),
              Text(
                b.subtitle,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: cardSubtitle),
              ),
            ],
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
            child: Text(
              badgeText,
              style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: badgeFg),
            ),
          ),
      ],
    );
  }

  // ── Bottom Navigation Bar (matching Admin Dashboard) ────────────────────
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
          final isSelected = index == 2; // Bookings tab is active
          final color = isSelected ? navGold : Colors.white;

          return GestureDetector(
            onTap: () {
              if (index == 0 || index == 1 || index == 4) {
                Navigator.pop(context);
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
}
