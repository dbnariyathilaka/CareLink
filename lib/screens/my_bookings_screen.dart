import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTab = 0; // 0=All, 1=Ongoing, 2=Upcoming, 3=Past

  static const List<String> _tabs = ['All', 'Ongoing', 'Upcoming', 'Past'];

  // Colours
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _ongoingGreen = Color(0xFF22C55E);
  static const Color _upcomingBlue = Color(0xFF6366F1);
  static const Color _cancelledRed = Color(0xFFEF4444);
  static const Color _completedGrey = Color(0xFF64748B);

  // ── Booking data ──────────────────────────────────────────
  static const List<_BookingData> _allBookings = [
    _BookingData(
      initials: 'AF',
      avatarType: _AvatarType.greenGradient,
      name: 'Alice Fernando',
      detail: 'Elder care · Full-time · 20 Nov–20 Dec',
      statusLabel: 'Ongoing',
      statusType: _StatusType.ongoing,
      bottomLeft: _BottomLeft.activeDot,
      bottomLeftText: 'Active now',
      hasMessage: true,
    ),
    _BookingData(
      initials: 'BK',
      avatarType: _AvatarType.blue,
      name: 'Brian Kumara',
      detail: 'Post-surgery · Part-time · 21 Dec 2025',
      statusLabel: 'Upcoming',
      statusType: _StatusType.upcoming,
      bottomLeft: _BottomLeft.text,
      bottomLeftText: 'Starts in 31 days',
      hasMessage: true,
    ),
    _BookingData(
      initials: 'CS',
      avatarType: _AvatarType.amber,
      name: 'Carol Silva',
      detail: 'Disability support · Full-time',
      statusLabel: 'Completed',
      statusType: _StatusType.completed,
      bottomLeft: _BottomLeft.stars,
      bottomLeftText: '',
      hasMessage: false,
      hasRebook: true,
    ),
    _BookingData(
      initials: 'DR',
      avatarType: _AvatarType.grey,
      name: 'David Ranasinghe',
      detail: 'General home care',
      statusLabel: 'Cancelled',
      statusType: _StatusType.cancelled,
      bottomLeft: _BottomLeft.text,
      bottomLeftText: 'No review · Cancelled',
      hasMessage: false,
    ),
  ];

  List<_BookingData> get _filtered {
    if (_selectedTab == 0) return _allBookings;
    final map = {
      1: _StatusType.ongoing,
      2: _StatusType.upcoming,
      3: _StatusType.completed,
    };
    final type = map[_selectedTab];
    return _allBookings.where((b) => b.statusType == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBar(),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: Text(
                'My bookings',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildBookingCard(_filtered[i]),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
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

  // ── Tab bar ───────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = i == _selectedTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tabs[i],
                    style: TextStyle(
                      color: selected ? AppTheme.primaryGreen : const Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 2.5,
                    width: selected ? 28 : 0,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(2),
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

  // ── Booking card ──────────────────────────────────────────
  Widget _buildBookingCard(_BookingData data) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name/detail + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(data),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.detail,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(data.statusType, data.statusLabel),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          Container(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 10),
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBottomLeft(data),
              _buildBottomRight(data),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(_BookingData data) {
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
          child: const Center(
            child: Text('AF',
                style: TextStyle(
                    color: AppTheme.bottleGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        );
      case _AvatarType.blue:
        return Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF058CD0),
          ),
          child: const Center(
            child: Text('BK',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        );
      case _AvatarType.amber:
        return Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _amber,
          ),
          child: const Center(
            child: Text('CS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        );
      case _AvatarType.grey:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF64748B).withValues(alpha: 0.35),
          ),
          child: const Center(
            child: Text('DR',
                style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        );
    }
  }

  Widget _buildStatusBadge(_StatusType type, String label) {
    Color bg;
    Color text;
    switch (type) {
      case _StatusType.ongoing:
        bg = _ongoingGreen.withValues(alpha: 0.15);
        text = _ongoingGreen;
        break;
      case _StatusType.upcoming:
        bg = _upcomingBlue.withValues(alpha: 0.18);
        text = _upcomingBlue;
        break;
      case _StatusType.completed:
        bg = _completedGrey.withValues(alpha: 0.2);
        text = _completedGrey;
        break;
      case _StatusType.cancelled:
        bg = _cancelledRed.withValues(alpha: 0.15);
        text = _cancelledRed;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomLeft(_BookingData data) {
    switch (data.bottomLeft) {
      case _BottomLeft.activeDot:
        return Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _ongoingGreen,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              data.bottomLeftText,
              style: const TextStyle(
                color: _ongoingGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case _BottomLeft.stars:
        return Row(
          children: List.generate(
            5,
            (i) => Icon(Icons.star_rounded, color: _amber, size: 16),
          ),
        );
      case _BottomLeft.text:
        return Text(
          data.bottomLeftText,
          style: TextStyle(
            color: data.statusType == _StatusType.cancelled
                ? const Color(0xFF64748B)
                : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }

  Widget _buildBottomRight(_BookingData data) {
    if (data.hasRebook) {
      return GestureDetector(
        onTap: () {},
        child: const Text(
          'Re-book Carol',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (data.hasMessage) {
      return GestureDetector(
        onTap: () {},
        child: Row(
          children: const [
            Icon(Icons.chat_bubble_outline_rounded,
                color: AppTheme.textSecondary, size: 14),
            SizedBox(width: 5),
            Text(
              'Message',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
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
    const selectedIndex = 2; // Bookings tab always active on this screen

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
          final color = isSelected
              ? AppTheme.primaryGreen
              : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/patient-dashboard'));
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

// ── Data models ───────────────────────────────────────────
enum _AvatarType { greenGradient, blue, amber, grey }
enum _StatusType { ongoing, upcoming, completed, cancelled }
enum _BottomLeft { activeDot, stars, text }

class _BookingData {
  final String initials;
  final _AvatarType avatarType;
  final String name;
  final String detail;
  final String statusLabel;
  final _StatusType statusType;
  final _BottomLeft bottomLeft;
  final String bottomLeftText;
  final bool hasMessage;
  final bool hasRebook;

  const _BookingData({
    required this.initials,
    required this.avatarType,
    required this.name,
    required this.detail,
    required this.statusLabel,
    required this.statusType,
    required this.bottomLeft,
    required this.bottomLeftText,
    required this.hasMessage,
    this.hasRebook = false,
  });
}
