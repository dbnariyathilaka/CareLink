import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Confirm Booking Screen  (Send-request flow — Step 3)
//  Figma node: 160-2449
// ─────────────────────────────────────────────────────────────
class ConfirmBookingScreen extends StatelessWidget {
  const ConfirmBookingScreen({super.key});

  // ── Figma colour tokens ──────────────────────────────────
  static const Color _green45 = AppTheme.primaryGreen;   // #22C55E
  static const Color _green8  = AppTheme.bottleGreen;    // #06240F
  static const Color _azure11 = AppTheme.surfaceColor;   // #0F172A
  static const Color _azure17 = AppTheme.cardColor;      // #1E293B
  static const Color _azure27 = AppTheme.borderColor;    // #334155
  static const Color _azure65 = AppTheme.textSecondary;  // #94A3B8
  static const Color _grey98  = AppTheme.textPrimary;    // #F8FAFC
  static const Color _amber   = Color(0xFFF59E0B);       // Buttercup

  // Amber banner colours (from Figma: bg 12%, border 40%)
  static const Color _amberBg     = Color(0x1FF59E0B);   // 12%
  static const Color _amberBorder = Color(0x66F59E0B);   // 40%

  // ── Booking data (passed / hardcoded to match Figma mock) ─
  static const List<_BookingRow> _rows = [
    _BookingRow('Start date',  '20 Dec 2025'),
    _BookingRow('Start time',  '8:00 AM'),
    _BookingRow('Duration',    '1 month'),
    _BookingRow('End date',    '20 Jan 2026'),
    _BookingRow('Location',    'Negombo'),
    _BookingRow('Care type',   'Elder · Full-time'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTitleRow(context),
                _buildStepIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildAmberBanner(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sticky bottom actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActions(context),
          ),
        ],
      ),
    );
  }



  // ── Title row ─────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
          ),
          const SizedBox(width: 10),
          const Text(
            'Confirm booking',
            style: TextStyle(
              color: _grey98,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────
  // Step 1 & 2: outlined green (done). Step 3: filled green (active).
  Widget _buildStepIndicator() {
    const steps = [
      _StepInfo('1', 'Request',  _StepState.done),
      _StepInfo('2', 'Schedule', _StepState.done),
      _StepInfo('3', 'Confirm',  _StepState.active),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    height: 1.5,
                    color: _green45.withValues(alpha: 0.35),
                  ),
                ),
              );
            }
            return _buildStepBubble(steps[i ~/ 2]);
          }),
        ),
      ),
    );
  }

  Widget _buildStepBubble(_StepInfo s) {
    final isActive = s.state == _StepState.active;
    final isDone   = s.state == _StepState.done;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive ? _green45 : _azure17,
            border: Border.all(
              color: isActive ? Colors.transparent : _green45,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              s.number,
              style: TextStyle(
                color: isActive ? _green8 : _green45,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.label,
          style: const TextStyle(
            color: _green45,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Booking summary card ──────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _azure27),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
      child: Column(
        children: List.generate(_rows.length, (index) {
          final row = _rows[index];
          final isLast = index == _rows.length - 1;
          return _buildSummaryRow(row, isLast: isLast);
        }),
      ),
    );
  }

  Widget _buildSummaryRow(_BookingRow row, {bool isLast = false}) {
    return Container(
      height: isLast ? 42 : 43,
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _azure27, width: 1),
              ),
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.label,
            style: const TextStyle(
              color: _azure65,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            row.value,
            style: const TextStyle(
              color: _grey98,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Amber timer banner ────────────────────────────────────
  Widget _buildAmberBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amberBorder),
      ),
      child: Row(
        children: [
          // Hourglass icon
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: _amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Alice has 6 hours to accept this request.',
              style: TextStyle(
                color: _amber,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom actions ────────────────────────────────────────
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _azure11.withValues(alpha: 0),
            _azure11,
          ],
          stops: const [0.0, 0.25],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary: Confirm and send
            Material(
              color: _green45,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  // TODO: dispatch booking to backend; navigate to success
                  _showBookingConfirmedDialog(context);
                },
                child: const SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Confirm and send request',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _green8,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Secondary: Edit schedule
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Edit schedule',
                style: TextStyle(
                  color: _azure65,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success feedback dialog ───────────────────────────────
  void _showBookingConfirmedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: _azure17,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green check circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _green45.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _green45,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Request sent!',
                style: TextStyle(
                  color: _grey98,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Alice has been notified and has 6 hours to accept your care request.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _azure65,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: _green45,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.of(context)
                      ..pop()   // dialog
                      ..pushNamedAndRemoveUntil(
                          '/patient-dashboard', (r) => false);
                  },
                  child: const SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Go to dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _green8,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────
class _BookingRow {
  final String label;
  final String value;
  const _BookingRow(this.label, this.value);
}

enum _StepState { done, active, inactive }

class _StepInfo {
  final String number;
  final String label;
  final _StepState state;
  const _StepInfo(this.number, this.label, this.state);
}
