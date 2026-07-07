import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Earnings Screen
//  Figma node: 46-4396 (C-08 · Earnings)
// ─────────────────────────────────────────────────────────────
class CaregiverEarningsScreen extends StatefulWidget {
  const CaregiverEarningsScreen({super.key});

  @override
  State<CaregiverEarningsScreen> createState() => _CaregiverEarningsScreenState();
}

class _CaregiverEarningsScreenState extends State<CaregiverEarningsScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _amber = Color(0xFFF59E0B);

  int _selectedPeriod = 0;
  static const List<String> _periods = ['This month', 'Last 3 months', 'All time'];

  static const List<({String label, double heightFraction})> _chartBars = [
    (label: 'Jul', heightFraction: 0.45),
    (label: 'Aug', heightFraction: 0.65),
    (label: 'Sep', heightFraction: 0.40),
    (label: 'Oct', heightFraction: 0.55),
    (label: 'Nov', heightFraction: 0.80),
    (label: 'Dec', heightFraction: 1.0),
  ];

  static const List<_BookingRow> _bookings = [
    _BookingRow(
      name: 'Nipuni Ariyathilaka',
      detail: 'Elder · Full-time · Nov 20–Dec 20',
      amount: 'LKR 22,000',
      status: 'Pending',
      statusColor: _amber,
    ),
    _BookingRow(
      name: 'Kamal Perera',
      detail: 'Post-surgery · Part · Nov 1–15',
      amount: 'LKR 14,000',
      status: 'Paid',
      statusColor: AppTheme.primaryGreen,
    ),
    _BookingRow(
      name: 'Sunil Mendis',
      detail: 'Elder · Part · Oct 1–31',
      amount: 'LKR 12,000',
      status: 'Paid',
      statusColor: AppTheme.primaryGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Earnings',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 14),
                    _buildStatsGrid(),
                    const SizedBox(height: 12),
                    _buildChart(),
                    const SizedBox(height: 12),
                    _buildPendingPayoutBanner(),
                    const SizedBox(height: 18),
                    const Text(
                      'BOOKING BREAKDOWN',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBookingBreakdownCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Period selector ────────────────────────────────────────
  Widget _buildPeriodSelector() {
    return Row(
      children: List.generate(_periods.length, (i) {
        final selected = i == _selectedPeriod;
        return Padding(
          padding: EdgeInsets.only(right: i == _periods.length - 1 ? 0 : 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? _indigo : AppTheme.cardColor,
                border: selected ? null : Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _periods[i],
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Stats grid ────────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statCard(
                  'Total earned',
                  'LKR 48,000',
                  footer: '+12% vs last month',
                  footerColor: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  'Pending payout',
                  'LKR 22,000',
                  valueColor: _amber,
                  footer: 'From 1 active booking',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _statCard('Jobs completed', '3')),
              const SizedBox(width: 10),
              Expanded(child: _statCard('Avg per booking', 'LKR 16k')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value, {
    Color? valueColor,
    String? footer,
    Color? footerColor,
  }) {
    return Container(
      width: double.infinity,
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 2),
            Text(
              footer,
              style: TextStyle(
                color: footerColor ?? const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Monthly bar chart ─────────────────────────────────────
  Widget _buildChart() {
    const maxBarHeight = 80.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _chartBars.map((bar) {
          final isCurrent = bar.label == 'Dec';
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: maxBarHeight * bar.heightFraction,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isCurrent ? _indigo : AppTheme.borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bar.label,
                  style: TextStyle(
                    color: isCurrent ? _indigo : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Pending payout banner ─────────────────────────────────
  Widget _buildPendingPayoutBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.08),
        border: Border.all(color: _amber.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Pending payout',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'LKR 22,000',
                style: TextStyle(
                  color: _amber,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Paid when your booking with Nipuni Ariyathilaka completes on '
            '20 Dec 2025.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payout details coming soon!')),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'View payout details',
                  style: TextStyle(
                    color: _indigo,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: _indigo, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking breakdown ─────────────────────────────────────
  Widget _buildBookingBreakdownCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(_bookings.length, (i) {
          final booking = _bookings[i];
          final isLast = i == _bookings.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: isLast
                ? null
                : const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                  ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.detail,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      booking.amount,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.status,
                      style: TextStyle(
                        color: booking.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _BookingRow {
  final String name;
  final String detail;
  final String amount;
  final String status;
  final Color statusColor;

  const _BookingRow({
    required this.name,
    required this.detail,
    required this.amount,
    required this.status,
    required this.statusColor,
  });
}
