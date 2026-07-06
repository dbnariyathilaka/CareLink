import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum _DutyStatus { available, busy, offDuty }

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoDark = Color(0xFF4F46E5);
  static const Color _amber = Color(0xFFF59E0B);

  int _selectedNavIndex = 0;
  _DutyStatus _dutyStatus = _DutyStatus.available;

  static const List<String> _stateTabs = [
    'Idle',
    'New request',
    'Emergency',
    'Confirmed',
    'Missed',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStateTabs(),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap a state to preview · prototype tabs',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAvailabilityCard(),
                    const SizedBox(height: 12),
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    const Text(
                      'Upcoming schedule',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildScheduleCard(
                      initials: 'NA',
                      avatarGradient: const [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreenDark,
                      ],
                      title: 'Nipuni Ariyathilaka',
                      subtitle: '20 Dec · Full-time',
                      badgeText: 'Confirmed',
                      badgeColor: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 10),
                    _buildScheduleCard(
                      icon: Icons.hourglass_empty_rounded,
                      title: 'New request pending',
                      subtitle: 'Awaiting your response',
                      badgeText: 'Pending',
                      badgeColor: _amber,
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ── Header: greeting + avatar ─────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.3, -1),
          end: Alignment(0.3, 1),
          colors: [_indigo, _indigoDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Caregiver',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Brian Kumara',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text(
                'BK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── State preview tabs (prototype only) ───────────────────
  Widget _buildStateTabs() {
    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _stateTabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isIdle = i == 0;
          return GestureDetector(
            onTap: () {
              if (!isIdle) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_stateTabs[i]} preview coming soon!')),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isIdle ? 9 : 10, vertical: isIdle ? 6 : 7),
              decoration: BoxDecoration(
                color: isIdle ? _indigo : AppTheme.cardColor,
                border: isIdle ? null : Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  _stateTabs[i],
                  style: TextStyle(
                    color: isIdle ? Colors.white : AppTheme.textSecondary,
                    fontSize: 10,
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

  // ── Availability card ──────────────────────────────────────
  Widget _buildAvailabilityCard() {
    final (Color dotColor, String label, String subtitle) = switch (_dutyStatus) {
      _DutyStatus.available => (AppTheme.primaryGreen, 'Available', 'You can receive new requests'),
      _DutyStatus.busy => (_amber, 'Busy', "You won't receive new requests right now"),
      _DutyStatus.offDuty => (const Color(0xFF64748B), 'Off duty', "You're not visible to families"),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 21, 15, 15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDutyButton('Available', _DutyStatus.available),
              const SizedBox(width: 8),
              _buildDutyButton('Busy', _DutyStatus.busy),
              const SizedBox(width: 8),
              _buildDutyButton('Off duty', _DutyStatus.offDuty),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDutyButton(String label, _DutyStatus status) {
    final selected = _dutyStatus == status;
    return Expanded(
      child: Material(
        color: selected ? AppTheme.primaryGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _dutyStatus = status),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: selected ? null : Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppTheme.bottleGreen : const Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────
  Widget _buildStatsRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _statCard('This month', '8', caption: 'bookings')),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard('Your rating', '4.5', caption: 'from 24 reviews', valueColor: _amber),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value, {
    String? caption,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Upcoming schedule card ────────────────────────────────
  Widget _buildScheduleCard({
    String? initials,
    List<Color>? avatarGradient,
    IconData? icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (initials != null)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: avatarGradient!,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppTheme.bottleGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.borderColor,
              ),
              child: Icon(icon, color: AppTheme.textSecondary, size: 18),
            ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.calendar_month_rounded, label: 'Schedule'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

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
          final isSelected = index == _selectedNavIndex;
          final color = isSelected ? _indigo : const Color(0xFF64748B);
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                setState(() => _selectedNavIndex = index);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.label} coming soon!')),
                );
              }
            },
            behavior: HitTestBehavior.opaque,
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
