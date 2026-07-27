import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Confirm Booking Screen
//  Normal flow  : Step 4/4
//  Advanced flow: Step 5/5 (teal accent)
//  Figma node: 208-58
// ─────────────────────────────────────────────────────────────────────────────
class ConfirmBookingScreen extends StatelessWidget {
  const ConfirmBookingScreen({super.key});

  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color titleGreen = Color(0xFF033724);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color stepInactiveBg = Color(0xFFDCD9CF);
  static const Color stepLineInactive = Color(0xFFD9D9D9);
  static const Color cardBg = Color(0xFFBDB296);
  static const Color cardRowBorder = Color(0xFF4C6B61);
  static const Color cardValueText = Color(0xFF384642);
  static const Color bannerBg = Color.fromRGBO(234, 67, 53, 0.39);
  static const Color bannerBorder = Color(0xFFEA4335);
  static const Color editLinkText = Color.fromRGBO(0, 0, 0, 0.78);

  // Advanced (teal) flow accent
  static const Color _keppel = Color(0xFF3DB498);
  static const Color _bottleGreen = Color(0xFF06291F);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final startDate  = args?['startDate']  ?? '20 Dec 2025';
    final startTime  = args?['startTime']  ?? '8:00 AM';
    final endTime    = args?['endTime']    ?? '5:00 PM';
    final duration   = args?['duration']   ?? '1 month';
    final endDate    = args?['endDate']    ?? '20 Jan 2026';
    final location   = args?['location']   ?? 'Negombo';
    final careType   = args?['careType']   ?? 'Elder · Full-time';
    final isAdvanced = args?['isAdvanced'] ?? false;
    final caregiverName = args?['caregiverName'] as String? ?? 'Your caregiver';

    // Advanced-only quiz answers
    final education  = args?['education']  as String?;
    final experience = args?['experience'] as String?;
    final training   = args?['training']   as String?;
    final languages  = args?['languages']  as List?;

    final Color accent = isAdvanced ? _keppel : darkGreen;
    final Color accentOnColor = isAdvanced ? _bottleGreen : Colors.white;
    final String bannerMsg = isAdvanced
        ? 'Matching caregivers have 6 hours to accept this request.'
        : '$caregiverName has 6 hours to accept this request.';

    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTitleRow(context),
                _buildStepIndicator(isAdvanced, accent, accentOnColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Schedule summary card ──────────────────────────
                        _buildScheduleCard(
                          startDate: startDate,
                          startTime: startTime,
                          endTime:   endTime,
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

                        const SizedBox(height: 16),

                        // ── Info banner ────────────────────────────────────
                        _buildBanner(message: bannerMsg),
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
              accentOnColor: accentOnColor,
              args:       args,
              caregiverName: caregiverName,
              careType:   careType,
              startDate:  startDate,
              startTime:  startTime,
              endTime:    endTime,
              duration:   duration,
              endDate:    endDate,
              location:   location,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: titleGreen, size: 22),
          ),
          const SizedBox(width: 16),
          const Text(
            'Confirm booking',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ─────────────────────────────────────────────────────────
  Widget _buildStepIndicator(bool isAdvanced, Color accent, Color accentOnColor) {
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = steps[i ~/ 2].state != _StepState.inactive;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 3,
                  decoration: BoxDecoration(
                    color: leftDone ? accent : stepLineInactive,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }
          final s = steps[i ~/ 2];
          final isFilled = s.state != _StepState.inactive;
          return Column(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? accent : stepInactiveBg,
                ),
                child: Center(
                  child: Text(
                    s.number,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: isFilled ? accentOnColor : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.label,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleGreen,
                  fontSize: 9,
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
    required String endTime,
    required String duration,
    required String endDate,
    required String location,
    required String careType,
  }) {
    final rows = [
      _BookingRow('Start date',     startDate),
      _BookingRow('Start time',     startTime),
      if (careType.contains('Flexible'))
        _BookingRow('End time',     endTime)
      else ...[
        _BookingRow('Duration',       duration),
        _BookingRow('End date',       endDate),
      ],
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
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Caregiver qualifications required',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: Colors.black,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cardRowBorder, width: 1),
              ),
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: cardValueText,
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
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row    = rows[index];
          final isLast = index == rows.length - 1;
          return Container(
            constraints: const BoxConstraints(minHeight: 45),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: isLast
                ? null
                : const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: cardRowBorder, width: 1),
                    ),
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: Colors.black,
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
                      color: cardValueText,
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
  Widget _buildBanner({required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_top_rounded, color: bannerBorder, size: 24),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: bannerBorder,
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

  // ── Firestore write ──────────────────────────────────────────────────────
  Future<void> _createBookingRequest({
    required bool isAdvanced,
    required String? caregiverId,
    required String caregiverName,
    required String careType,
    required String startDate,
    required String startTime,
    required String endTime,
    required String duration,
    required String endDate,
    required String location,
  }) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final isFlexible = careType.contains('Flexible');
    await BookingService.createBookingRequest(
      patientUid: uid,
      caregiverId: caregiverId,
      caregiverName: isAdvanced ? 'Matching caregivers' : caregiverName,
      careType: careType,
      startDate: startDate,
      startTime: startTime,
      endTime: isFlexible ? endTime : null,
      duration: isFlexible ? null : duration,
      endDate: isFlexible ? null : endDate,
      location: location,
      isAdvanced: isAdvanced,
    );
  }

  // ── Bottom actions ─────────────────────────────────────────────────────────
  Widget _buildBottomActions(
    BuildContext context, {
    required bool isAdvanced,
    required Color accent,
    required Color accentOnColor,
    required Map<String, dynamic>? args,
    required String caregiverName,
    required String careType,
    required String startDate,
    required String startTime,
    required String endTime,
    required String duration,
    required String endDate,
    required String location,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgCream.withValues(alpha: 0), bgCream],
          stops: const [0.0, 0.28],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary: Confirm and send request
            Material(
              color: accent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await _createBookingRequest(
                    isAdvanced:    isAdvanced,
                    caregiverId:   args?['caregiverId'] as String?,
                    caregiverName: caregiverName,
                    careType:      careType,
                    startDate:     startDate,
                    startTime:     startTime,
                    endTime:       endTime,
                    duration:      duration,
                    endDate:       endDate,
                    location:      location,
                  );
                  if (!context.mounted) return;
                  if (isAdvanced) {
                    // Advanced flow → show matching analysis loading screen
                    Navigator.pushNamed(
                      context,
                      '/matching-analysis',
                      arguments: args,
                    );
                  } else {
                    final resolvedName =
                        args?['caregiverName'] as String? ?? 'your caregiver';
                    _showConfirmedDialog(
                      context,
                      isAdvanced,
                      accent,
                      accentOnColor,
                      resolvedName,
                    );
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
                        fontFamily: 'Open Sans',
                        color: accentOnColor,
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
                  fontFamily: 'Inter',
                  color: editLinkText,
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
    Color accentOnColor,
    String caregiverName,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: accent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 20, 25, 27),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                            color: accentOnColor.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: accentOnColor.withValues(alpha: 0.85),
                          size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Icon(Icons.verified, color: accentOnColor, size: 72),
              const SizedBox(height: 20),
              Text(
                'Request confirmed!',
                style: TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: accentOnColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isAdvanced
                    ? 'Your booking request has been sent to matching caregivers. '
                        "We'll notify you as soon as one accepts."
                    : "Your booking request has been sent to $caregiverName. "
                        "We'll notify you as soon as she accepts.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: accentOnColor.withValues(alpha: 0.75),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: accentOnColor, width: 1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/my-bookings',
                        (route) => route.settings.name == '/patient-dashboard',
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, color: accentOnColor, size: 19),
                          const SizedBox(width: 8),
                          Text(
                            'Go to My bookings',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Quattrocento Sans',
                              color: accentOnColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

enum _StepState { done, active, inactive }

class _StepInfo {
  final String number;
  final String label;
  final _StepState state;
  const _StepInfo(this.number, this.label, this.state);
}
