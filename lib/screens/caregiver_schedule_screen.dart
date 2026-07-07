import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum _JobStatus { ongoing, upcoming, completed }

class _JobData {
  final String initials;
  final List<Color> avatarGradient;
  final Color initialsColor;
  final String name;
  final String detail;
  final String statusLabel;
  final _JobStatus status;
  final Color statusBg;
  final Color statusColor;
  final String amount;
  final String? activeLabel;
  final IconData? activeIcon;
  final String? footNote;
  final String? stars;
  final String? paidLabel;

  const _JobData({
    required this.initials,
    required this.avatarGradient,
    required this.initialsColor,
    required this.name,
    required this.detail,
    required this.statusLabel,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.amount,
    this.activeLabel,
    this.activeIcon,
    this.footNote,
    this.stars,
    this.paidLabel,
  });
}

class CaregiverScheduleScreen extends StatefulWidget {
  const CaregiverScheduleScreen({super.key});

  @override
  State<CaregiverScheduleScreen> createState() =>
      _CaregiverScheduleScreenState();
}

class _CaregiverScheduleScreenState extends State<CaregiverScheduleScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);
  static const Color _amber = Color(0xFFF59E0B);

  int _selectedTab = 0; // 0=All, 1=Active, 2=Upcoming, 3=Past

  static const List<String> _tabs = ['All', 'Active', 'Upcoming', 'Past'];

  static final List<_JobData> _jobs = [
    _JobData(
      initials: 'NA',
      avatarGradient: const [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
      initialsColor: AppTheme.bottleGreen,
      name: 'Nipuni Ariyathilaka',
      detail: 'Elder care · Full-time · 20 Nov–20 Dec',
      statusLabel: 'Ongoing',
      status: _JobStatus.ongoing,
      statusBg: AppTheme.primaryGreen.withValues(alpha: 0.15),
      statusColor: AppTheme.primaryGreen,
      amount: 'LKR 22,000',
      activeLabel: 'Active now · Message',
      activeIcon: Icons.chat_bubble_outline_rounded,
    ),
    _JobData(
      initials: 'KP',
      avatarGradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      initialsColor: Colors.white,
      name: 'Kamal Perera',
      detail: 'Post-surgery · Part-time · 21 Dec 2025',
      statusLabel: 'Upcoming',
      status: _JobStatus.upcoming,
      statusBg: _indigo.withValues(alpha: 0.15),
      statusColor: _indigoLight,
      amount: 'LKR 14,000',
      footNote: 'Starts in 31 days',
    ),
    _JobData(
      initials: 'SM',
      avatarGradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
      initialsColor: const Color(0xFF3B2406),
      name: 'Sunil Mendis',
      detail: 'Elder care · Part-time · 1 Oct–1 Nov',
      statusLabel: 'Completed',
      status: _JobStatus.completed,
      statusBg: const Color(0xFF94A3B8).withValues(alpha: 0.18),
      statusColor: AppTheme.textSecondary,
      amount: 'LKR 12,000',
      stars: '★★★★★',
      paidLabel: 'Paid',
    ),
  ];

  List<_JobData> get _filtered {
    if (_selectedTab == 0) return _jobs;
    final map = {
      1: _JobStatus.ongoing,
      2: _JobStatus.upcoming,
      3: _JobStatus.completed,
    };
    final status = map[_selectedTab];
    return _jobs.where((j) => j.status == status).toList();
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
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My jobs',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildTabBar(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 12),
                    ..._filtered.map(
                      (job) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildJobCard(job),
                      ),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = i == _selectedTab;
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(
                  border: selected
                      ? const Border(bottom: BorderSide(color: _indigo, width: 2))
                      : null,
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    color: selected ? _indigo : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _statCard(
              'This month earned',
              'LKR 48,000',
              caption: '3 bookings',
              valueColor: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              'Overall rating',
              '4.5 ★',
              caption: 'from 24 reviews',
              valueColor: _amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, {String? caption, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(13),
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
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 1),
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

  // ── Job card ──────────────────────────────────────────────
  Widget _buildJobCard(_JobData job) {
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: job.avatarGradient,
                  ),
                ),
                child: Center(
                  child: Text(
                    job.initials,
                    style: TextStyle(
                      color: job.initialsColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.detail,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: job.statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  job.statusLabel,
                  style: TextStyle(
                    color: job.statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (job.stars != null)
                Row(
                  children: [
                    Text(
                      job.stars!,
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      job.amount,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  job.amount,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (job.activeLabel != null)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Messaging coming soon!')),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(job.activeIcon, color: _indigo, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        job.activeLabel!,
                        style: const TextStyle(
                          color: _indigo,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (job.footNote != null)
                Text(
                  job.footNote!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else if (job.paidLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    job.paidLabel!,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom nav (Schedule tab active) ──────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.calendar_month_rounded, label: 'Schedule'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];
    const selectedIndex = 1;

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
          final color = isSelected ? _indigo : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/caregiver-dashboard'));
              } else if (index == 2) {
                Navigator.pushNamed(context, '/caregiver-notifications');
              } else if (index == 3) {
                Navigator.pushNamed(context, '/caregiver-own-profile');
              } else if (index != 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.label} coming soon!')),
                );
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
