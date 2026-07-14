import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Confirm Booking Screen
//  Normal flow  : Step 4/4  – green theme  (Figma 282-11092)
//  Advanced flow: Step 5/5  – teal theme   (Figma 282-13425)
// ─────────────────────────────────────────────────────────────────────────────
class ConfirmBookingScreen extends StatelessWidget {
  const ConfirmBookingScreen({super.key});

  // ── Shared tokens ──────────────────────────────────────────────────────────
  static const Color _azure11 = AppTheme.surfaceColor;   // #0F172A
  static const Color _azure17 = AppTheme.cardColor;      // #1E293B
  static const Color _azure27 = AppTheme.borderColor;    // #334155
  static const Color _azure65 = AppTheme.textSecondary;  // #94A3B8
  static const Color _grey98  = AppTheme.textPrimary;    // #F8FAFC

  // ── Normal flow tokens ─────────────────────────────────────────────────────
  static const Color _green45 = AppTheme.primaryGreen;   // #22C55E
  static const Color _green8  = AppTheme.bottleGreen;    // #06240F
  static const Color _amber   = Color(0xFFF59E0B);
  static const Color _amberBg = Color(0x1FF59E0B);
  static const Color _amberBorder = Color(0x66F59E0B);

  // ── Advanced (teal) flow tokens ────────────────────────────────────────────
  static const Color _keppel      = Color(0xFF3DB498);   // Keppel Cyan
  static const Color _bottleGreen = Color(0xFF06291F);
  static const Color _keppelBg    = Color(0x1A3DB498);   // ~10% keppel
  static const Color _keppelBdr   = Color(0x663DB498);   // ~40% keppel

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final startDate  = args?['startDate']  ?? '20 Dec 2025';
    final startTime  = args?['startTime']  ?? '8:00 AM';
    final duration   = args?['duration']   ?? '1 month';
    final endDate    = args?['endDate']    ?? '20 Jan 2026';
    final location   = args?['location']   ?? 'Negombo';
    final careType   = args?['careType']   ?? 'Elder · Full-time';
    final isAdvanced = args?['isAdvanced'] ?? false;

    // Advanced-only quiz answers
    final education  = args?['education']  as String?;
    final experience = args?['experience'] as String?;
    final training   = args?['training']   as String?;
    final languages  = args?['languages']  as List?;

    // Accent colours depend on flow
    final Color accent      = isAdvanced ? _keppel  : _green45;
    final Color accentText  = isAdvanced ? _bottleGreen : _green8;
    final Color bannerBg    = isAdvanced ? _keppelBg   : _amberBg;
    final Color bannerBdr   = isAdvanced ? _keppelBdr  : _amberBorder;
    final Color bannerIcon  = isAdvanced ? _keppel      : _amber;
    final Color bannerTxt   = isAdvanced ? _keppel      : _amber;
    final String bannerMsg  = isAdvanced
        ? 'Matching caregivers have 6 hours to accept this request.'
        : 'Your caregiver has 6 hours to accept this request.';
    final IconData bannerIconData = isAdvanced
        ? Icons.hourglass_bottom_rounded
        : Icons.hourglass_top_rounded;

    return Scaffold(
      backgroundColor: _azure11,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTitleRow(context),
                _buildStepIndicator(isAdvanced, accent),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Schedule summary card ──────────────────────────
                        _buildScheduleCard(
                          startDate: startDate,
                          startTime: startTime,
                          duration:  duration,
                          endDate:   endDate,
                          location:  location,
                          careType:  careType,
                        ),

                        // ── Qualifications card (advanced only) ────────────
                        if (isAdvanced) ...[
                          const SizedBox(height: 14),
                          _buildQualificationsCard(
                            education:  education,
                            experience: experience,
                            training:   training,
                            languages:  languages,
                          ),
                        ],

                        const SizedBox(height: 14),

                        // ── Info banner ────────────────────────────────────
                        _buildBanner(
                          bgColor:   bannerBg,
                          bdrColor:  bannerBdr,
                          iconColor: bannerIcon,
                          textColor: bannerTxt,
                          icon:      bannerIconData,
                          message:   bannerMsg,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky bottom actions
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildBottomActions(
              context,
              isAdvanced: isAdvanced,
              accent:     accent,
              accentText: accentText,
              args:       args,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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

  // ── Step indicator ─────────────────────────────────────────────────────────
  Widget _buildStepIndicator(bool isAdvanced, Color accent) {
    final steps = isAdvanced
        ? const [
            _StepInfo('1', 'Request',        _StepState.done),
            _StepInfo('2', 'Schedule',        _StepState.done),
            _StepInfo('3', 'Location',        _StepState.done),
            _StepInfo('4', 'Qualifications',  _StepState.done),
            _StepInfo('5', 'Confirm',         _StepState.active),
          ]
        : const [
            _StepInfo('1', 'Request',  _StepState.done),
            _StepInfo('2', 'Schedule', _StepState.done),
            _StepInfo('3', 'Location', _StepState.done),
            _StepInfo('4', 'Confirm',  _StepState.active),
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 12, left: 3, right: 3),
                height: 1.5,
                color: accent,
              ),
            );
          }
          final s = steps[i ~/ 2];
          final isActive = s.state == _StepState.active;
          final isDone   = s.state == _StepState.done;
          return Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? accent : _azure17,
                  border: Border.all(
                    color: isActive || isDone ? accent : _azure27,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    s.number,
                    style: TextStyle(
                      color: isActive
                          ? (isAdvanced ? _bottleGreen : _green8)
                          : (isDone ? accent : _azure65),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.label,
                style: TextStyle(
                  color: isActive || isDone ? accent : _azure65,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Schedule summary card ──────────────────────────────────────────────────
  Widget _buildScheduleCard({
    required String startDate,
    required String startTime,
    required String duration,
    required String endDate,
    required String location,
    required String careType,
  }) {
    final rows = [
      _BookingRow('Start date',     startDate),
      _BookingRow('Start time',     startTime),
      _BookingRow('Duration',       duration),
      _BookingRow('End date',       endDate),
      _BookingRow('Location',       location),
      _BookingRow('Work schedule',  careType),
    ];
    return _buildSummaryCardContainer(rows);
  }

  // ── Qualifications card ────────────────────────────────────────────────────
  Widget _buildQualificationsCard({
    String? education,
    String? experience,
    String? training,
    List? languages,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _azure27),
      ),
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caregiver qualifications required',
            style: TextStyle(
              color: _grey98,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildQualRow('Education',       education ?? '–'),
          _buildQualRow('Experience',      experience ?? '–'),
          _buildQualRow('Formal training', training ?? '–'),
          _buildQualRow(
            'Languages',
            languages != null && languages.isNotEmpty
                ? languages.join(', ')
                : '–',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQualRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
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
            label,
            style: const TextStyle(
              color: _azure65,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
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

  // ── Generic summary card ───────────────────────────────────────────────────
  Widget _buildSummaryCardContainer(List<_BookingRow> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _azure27),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row    = rows[index];
          final isLast = index == rows.length - 1;
          return Container(
            constraints: const BoxConstraints(minHeight: 43),
            padding: const EdgeInsets.symmetric(vertical: 10),
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
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: _grey98,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Info banner ────────────────────────────────────────────────────────────
  Widget _buildBanner({
    required Color bgColor,
    required Color bdrColor,
    required Color iconColor,
    required Color textColor,
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdrColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom actions ─────────────────────────────────────────────────────────
  Widget _buildBottomActions(
    BuildContext context, {
    required bool isAdvanced,
    required Color accent,
    required Color accentText,
    required Map<String, dynamic>? args,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_azure11.withValues(alpha: 0), _azure11],
          stops: const [0.0, 0.28],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary: Confirm and send request
            Material(
              color: accent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (isAdvanced) {
                    // Advanced flow → show matching analysis loading screen
                    Navigator.pushNamed(
                      context,
                      '/matching-analysis',
                      arguments: args,
                    );
                  } else {
                    _showConfirmedDialog(context, isAdvanced, accent, accentText);
                  }
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Confirm and send request',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentText,
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
              onTap: () {
                // Go back to step 1 of the respective flow
                if (isAdvanced) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/advanced-match-send-request',
                    (route) => route.settings.name == '/patient-dashboard',
                  );
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/send-request',
                    (route) => route.settings.name == '/patient-dashboard',
                  );
                }
              },
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

  // ── Success dialog ─────────────────────────────────────────────────────────
  void _showConfirmedDialog(
    BuildContext context,
    bool isAdvanced,
    Color accent,
    Color accentText,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: _azure17,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: accent, size: 36),
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
              Text(
                isAdvanced
                    ? 'Matching caregivers have been notified and have 6 hours to accept your request.'
                    : 'Your caregiver has been notified and has 6 hours to accept your care request.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _azure65,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: accent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.of(context)
                      ..pop()
                      ..pushNamedAndRemoveUntil(
                          '/patient-dashboard', (r) => false);
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Go to dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accentText,
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

// ── Data models ───────────────────────────────────────────────────────────────
class _BookingRow {
  final String label;
  final String value;
  const _BookingRow(this.label, this.value);
}

enum _StepState { done, active }

class _StepInfo {
  final String number;
  final String label;
  final _StepState state;
  const _StepInfo(this.number, this.label, this.state);
}
