import 'package:flutter/material.dart';
import '../app_state.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTab = 0; // 0=All, 1=Requested, 2=Past

  static const List<String> _tabs = ['All', 'Requested', 'Past'];

  // Colours
  static const Color _amber = Color(0xFFF59E0B);

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
    if (_selectedTab == 1) {
      // Requested includes Ongoing and Upcoming
      return _allBookings
          .where((b) =>
              b.statusType == _StatusType.ongoing ||
              b.statusType == _StatusType.upcoming)
          .toList();
    }
    if (_selectedTab == 2) {
      // Past includes Completed and Cancelled
      return _allBookings
          .where((b) =>
              b.statusType == _StatusType.completed ||
              b.statusType == _StatusType.cancelled)
          .toList();
    }
    return _allBookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 12, 22, 0),
              child: Text(
                'My bookings',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            if (_allBookings.isEmpty)
              Expanded(child: _buildEmptyState(context))
            else ...[
              const SizedBox(height: 14),
              _buildTabBar(),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildBookingCard(_filtered[i]),
                ),
              ),
            ],
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ── Empty state: no bookings at all ───────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF22C55E),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No bookings yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              "You haven't sent any care requests yet. Find a caregiver from your top 5 matches and send your first request.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                height: 1.6,
              ),
            ),
            const SizedBox(height: 26),
            Material(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pushNamed(context, '/search'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                  child: Text(
                    'Find a caregiver',
                    style: TextStyle(
                      color: Color(0xFF06240F),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your matches refresh automatically if no one responds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0),
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = i == _selectedTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              padding: const EdgeInsets.only(bottom: 9),
              margin: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                border: selected
                    ? const Border(
                        bottom: BorderSide(color: Color(0xFF22C55E), width: 2.0),
                      )
                    : null,
              ),
              child: Text(
                _tabs[i],
                style: TextStyle(
                  color: selected ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'Inter',
                ),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name/detail + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(data),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.detail,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
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
          const SizedBox(height: 11),
          // Divider
          Container(height: 1, color: const Color(0xFF334155)),
          const SizedBox(height: 12),
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
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
            ),
          ),
          child: const Center(
            child: Text(
              'AF',
              style: TextStyle(
                color: Color(0xFF06240F),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        );
      case _AvatarType.blue:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
            ),
          ),
          child: const Center(
            child: Text(
              'BK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        );
      case _AvatarType.amber:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF59E0B), Color(0xFFD97606)],
            ),
          ),
          child: const Center(
            child: Text(
              'CS',
              style: TextStyle(
                color: Color(0xFF3B2406),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        );
      case _AvatarType.grey:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF334155),
          ),
          child: const Center(
            child: Text(
              'DR',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        );
    }
  }

  Widget _buildStatusBadge(_StatusType type, String label) {
    Color bg;
    Color text;
    switch (type) {
      case _StatusType.ongoing:
        bg = const Color(0xFF22C55E).withValues(alpha: 0.15);
        text = const Color(0xFF22C55E);
        break;
      case _StatusType.upcoming:
        bg = const Color(0xFF6366F1).withValues(alpha: 0.15);
        text = const Color(0xFF01D3A8);
        break;
      case _StatusType.completed:
        bg = const Color(0xFF94A3B8).withValues(alpha: 0.18);
        text = const Color(0xFF94A3B8);
        break;
      case _StatusType.cancelled:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        text = const Color(0xFFEF4444);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
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
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              data.bottomLeftText,
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
        );
      case _BottomLeft.stars:
        return Row(
          children: List.generate(
            5,
            (i) => const Icon(Icons.star_rounded, color: _amber, size: 16),
          ),
        );
      case _BottomLeft.text:
        return Text(
          data.bottomLeftText,
          style: TextStyle(
            color: data.statusType == _StatusType.cancelled
                ? const Color(0xFF64748B)
                : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
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
            color: Color(0xFF22C55E),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      );
    }
    if (data.hasMessage) {
      return GestureDetector(
        onTap: () {},
        child: const Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFFF8FAFC), size: 16),
            SizedBox(width: 5),
            Text(
              'Message',
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
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
      (icon: null, label: 'Match'),
      (icon: Icons.calendar_month_rounded, label: 'Bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
    ];
    const selectedIndex = 3; // Bookings tab always active on this screen

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          if (index == 2) {
            return GestureDetector(
              onTap: () {
                if (AppState.hasActiveMatch.value) {
                  Navigator.pushNamed(context, '/advanced-match-results');
                } else {
                  Navigator.pushNamed(context, '/advanced-match-send-request');
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF01D3A8), // Caribbean Green
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F172A), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF01D3A8).withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.diversity_3_rounded,
                      color: Color(0xFF06240F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Match',
                    style: TextStyle(
                      color: Color(0xFF01D3A8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            );
          }

          final color = isSelected
              ? const Color(0xFF22C55E)
              : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/patient-dashboard'));
              } else if (index == 1) {
                Navigator.pushNamed(context, '/search');
              } else if (index == 4) {
                Navigator.pushNamed(context, '/notifications');
              }
            },
            child: SizedBox(
              width: 60,
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
                      fontFamily: 'Inter',
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
