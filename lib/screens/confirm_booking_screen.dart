import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../services/profile_gate.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Confirm Booking Screen
//  Normal flow  : Step 4/4 (dark green accent, light tan summary cards)
//  Advanced flow: Step 5/5 (plum accent, dark summary cards)
//  Figma nodes: 208-58 (normal), 324-360 (advanced)
// ─────────────────────────────────────────────────────────────────────────────
class ConfirmBookingScreen extends StatelessWidget {
  const ConfirmBookingScreen({super.key});

  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color titleGreen = Color(0xFF033724);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color stepInactiveBg = Color(0xFFDCD9CF);
  static const Color stepLineInactive = Color(0xFFD9D9D9);
  static const Color editLinkText = Color.fromRGBO(0, 0, 0, 0.78);

  // Summary/qualifications cards — light tan for normal flow, dark panel
  // for advanced flow (Figma node 324-360).
  static const Color cardBgLight = Color(0xFFBDB296);
  static const Color cardBgDark = Color(0xFF313131);
  static const Color cardBorderDark = Color(0xFF334155);
  static const Color cardRowBorderLight = Color(0xFF4C6B61);
  static const Color cardRowBorderDark = Color(0xFF484848);
  static const Color cardLabelDark = Color(0xFF827B65);
  static const Color cardValueLight = Color(0xFF384642);
  static const Color cardValueDark = Color(0xFFF8FAFC);

  // Info banner — red for normal flow, amber/olive for advanced flow.
  static const Color bannerBgLight = Color.fromRGBO(234, 67, 53, 0.39);
  static const Color bannerBorderLight = Color(0xFFEA4335);
  static const Color bannerBgDark = Color(0xFFEDE6C7);
  static const Color bannerBorderDark = Color(0xFF9C8629);
  static const Color bannerIconDark = Color(0xFF706743);
  static const Color bannerTextDark = Color(0xFF6B6343);

  static const Color titleDark = Color(0xFF313131);

  // Advanced flow accent (plum/purple)
  static const Color _accentAdvanced = Color(0xFF6D4275);

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(Brightness.dark);
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
    final training   = args?['training']   as String?;
    final languages  = args?['languages']  as List?;
    final caregiverId = args?['caregiverId'] as String?;

    // Set when a family member is booking on the patient's behalf (see
    // family_access_home_screen.dart's "Book care" action) — carried
    // through send_request/schedule_care/location_selection unchanged.
    final onBehalfOfPatientUid = args?['onBehalfOfPatientUid'] as String?;
    final onBehalfOfPatientName = args?['onBehalfOfPatientName'] as String?;

    final Color accent = isAdvanced ? _accentAdvanced : darkGreen;
    const Color accentOnColor = Colors.white;
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
                _buildTitleRow(context, isAdvanced),
                _buildStepIndicator(isAdvanced, accent, accentOnColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (onBehalfOfPatientUid != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: accent.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Booking for ${onBehalfOfPatientName ?? 'the patient'}',
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: accent,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        // ── Schedule summary card ──────────────────────────
                        _buildScheduleCard(
                          isAdvanced: isAdvanced,
                          startDate: startDate,
                          startTime: startTime,
                          endTime:   endTime,
                          duration:  duration,
                          endDate:   endDate,
                          location:  location,
                          careType:  careType,
                        ),

                        // ── Pricing card — only when a specific caregiver
                        // is already known (the direct-request flow); the
                        // advanced flow doesn't pick one until the results
                        // screen after this. Shows the real admin-assigned
                        // rate, not a guess — "Not yet assigned" if the
                        // admin hasn't set one for this caregiver yet.
                        if (caregiverId != null) ...[
                          const SizedBox(height: 14),
                          FutureBuilder<Map<String, dynamic>?>(
                            future: CaregiverService.getCaregiverProfile(caregiverId),
                            builder: (context, snap) {
                              final rate = (snap.data?['hourlyRate'] as num?)?.toDouble();
                              return _buildPricingCard(
                                isAdvanced: isAdvanced,
                                hourlyRate: rate,
                                careType: careType,
                                startDate: startDate,
                                startTime: startTime,
                                endDate: endDate,
                                endTime: endTime,
                              );
                            },
                          ),
                        ],

                        // ── Qualifications card (advanced only) ────────────
                        if (isAdvanced) ...[
                          const SizedBox(height: 14),
                          _buildQualificationsCard(
                            isAdvanced: isAdvanced,
                            training:   training,
                            languages:  languages,
                          ),
                        ],

                        const SizedBox(height: 16),

                        // ── Info banner ────────────────────────────────────
                        _buildBanner(message: bannerMsg, isAdvanced: isAdvanced),
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
  Widget _buildTitleRow(BuildContext context, bool isAdvanced) {
    final Color titleColor = isAdvanced ? titleDark : titleGreen;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: titleColor, size: 22),
          ),
          const SizedBox(width: 16),
          Text(
            'Confirm Booking',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: titleColor,
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
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: isAdvanced ? accent : titleGreen,
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
    required bool isAdvanced,
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
    return _buildSummaryCardContainer(rows, isAdvanced: isAdvanced);
  }

  // ── Pricing card ─────────────────────────────────────────────────────────
  // Figma node 208-58: shows the actual total cost of the booking, not just
  // the bare rate — for every schedule type, not only Flexible:
  //   - Flexible: a single day, hours = the picked start/end time gap.
  //   - Part-time / Full-time: hours/day from the real resolved shift
  //     (schedule_care_screen._resolvedEndTime — Full-time's chosen shift,
  //     Part-time's +4-hour rule), times the number of days in the date
  //     range (e.g. a 1-month booking spans ~30 days, so "30 days ×
  //     9 hrs/day" is the total, not just one day's rate).
  //   - Live-in: a flat 24 hours/day — it's round-the-clock care, not a
  //     timed shift, so there's no start/end time to measure.
  Widget _buildPricingCard({
    required bool isAdvanced,
    required String careType,
    required String startDate,
    required String startTime,
    required String endDate,
    required String endTime,
    double? hourlyRate,
  }) {
    final isFlexible = careType.contains('Flexible');
    final isLiveIn = careType.contains('Live-in');

    final dailyHours = isLiveIn ? 24.0 : _hoursBetween(startTime, endTime);
    final days = isFlexible ? 1 : _daysBetween(startDate, endDate);
    final totalHours = (dailyHours != null && days != null) ? dailyHours * days : null;

    final rows = [
      _BookingRow(
        'Hourly rate',
        hourlyRate == null ? 'Not yet assigned' : 'Rs.${hourlyRate.toStringAsFixed(0)} / hour',
      ),
      if (totalHours != null)
        _BookingRow('Hours', '${_formatHours(totalHours)} hrs'),
      if (hourlyRate != null && totalHours != null)
        _BookingRow('Total', 'Rs.${_formatAmount(hourlyRate * totalHours)}'),
    ];
    return _buildSummaryCardContainer(rows, isAdvanced: isAdvanced, highlightLastRow: totalHours != null);
  }

  /// Parses "9:00 AM" / "17:00" style strings into hours-since-midnight, and
  /// returns the shift length — wrapping past midnight for an overnight
  /// shift (end time earlier than start time means it runs into the next
  /// day, not a negative duration).
  double? _hoursBetween(String startTime, String endTime) {
    final start = _parseMinutesSinceMidnight(startTime);
    final end = _parseMinutesSinceMidnight(endTime);
    if (start == null || end == null) return null;
    var minutes = end - start;
    if (minutes <= 0) minutes += 24 * 60;
    return minutes / 60.0;
  }

  int? _parseMinutesSinceMidnight(String value) {
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(value);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)?.toLowerCase();
    if (meridiem == 'pm' && hour != 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  static const Map<String, int> _monthAbbrev = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  /// Parses this screen's own "D Mon YYYY" date format (e.g. "26 Sep 2026",
  /// see schedule_care_screen._formatDate, which produces every startDate/
  /// endDate this screen receives).
  DateTime? _parseDate(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = _monthAbbrev[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  /// Real calendar length of the booking — e.g. a "1 month" duration
  /// starting 26 Sep resolves to an end date of 26 Oct, which is exactly
  /// 30 days later; a "2 weeks" duration is exactly 14. Using the actual
  /// resolved dates rather than parsing the free-text duration label
  /// ("1 month") handles every duration option correctly, including
  /// custom date-range picks.
  int? _daysBetween(String startDate, String endDate) {
    final start = _parseDate(startDate);
    final end = _parseDate(endDate);
    if (start == null || end == null) return null;
    final diff = end.difference(start).inDays;
    return diff > 0 ? diff : null;
  }

  String _formatHours(double hours) =>
      hours == hours.roundToDouble() ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1);

  String _formatAmount(double amount) {
    final rounded = amount.round();
    final digits = rounded.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  // ── Qualifications card ────────────────────────────────────────────────────
  Widget _buildQualificationsCard({
    required bool isAdvanced,
    String? training,
    List? languages,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isAdvanced ? cardBgDark : cardBgLight,
        borderRadius: BorderRadius.circular(14),
        border: isAdvanced ? Border.all(color: cardBorderDark) : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Caregiver qualifications required',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: isAdvanced ? cardValueDark : Colors.black,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildQualRow('Formal training', training ?? '–', isAdvanced: isAdvanced),
          _buildQualRow(
            'Languages',
            languages != null && languages.isNotEmpty
                ? languages.join(', ')
                : '–',
            isAdvanced: isAdvanced,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQualRow(String label, String value,
      {required bool isAdvanced, bool isLast = false}) {
    final Color rowBorder = isAdvanced ? cardRowBorderDark : cardRowBorderLight;
    final Color labelColor = isAdvanced ? cardLabelDark : Colors.black;
    final Color valueColor = isAdvanced ? cardValueDark : cardValueLight;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: rowBorder, width: 1),
              ),
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Generic summary card ───────────────────────────────────────────────────
  // [highlightLastRow] bolds/enlarges the final row's label+value — used for
  // the pricing card's "Total" row so it reads as the headline figure rather
  // than another plain line item.
  Widget _buildSummaryCardContainer(
    List<_BookingRow> rows, {
    required bool isAdvanced,
    bool highlightLastRow = false,
  }) {
    final Color rowBorder = isAdvanced ? cardRowBorderDark : cardRowBorderLight;
    final Color labelColor = isAdvanced ? cardLabelDark : Colors.black;
    final Color valueColor = isAdvanced ? cardValueDark : cardValueLight;
    final Color highlightColor = isAdvanced ? _accentAdvanced : darkGreen;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isAdvanced ? cardBgDark : cardBgLight,
        borderRadius: BorderRadius.circular(14),
        border: isAdvanced ? Border.all(color: cardBorderDark) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row    = rows[index];
          final isLast = index == rows.length - 1;
          final isHighlighted = highlightLastRow && isLast;
          return Container(
            constraints: const BoxConstraints(minHeight: 45),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: isLast
                ? null
                : BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: rowBorder, width: 1),
                    ),
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row.label,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: isHighlighted ? highlightColor : labelColor,
                    fontSize: isHighlighted ? 14.5 : 13,
                    fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: isHighlighted ? highlightColor : valueColor,
                      fontSize: isHighlighted ? 16 : 13,
                      fontWeight: FontWeight.w700,
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
  Widget _buildBanner({required String message, required bool isAdvanced}) {
    final Color bg = isAdvanced ? bannerBgDark : bannerBgLight;
    final Color border = isAdvanced ? bannerBorderDark : bannerBorderLight;
    final Color icon = isAdvanced ? bannerIconDark : bannerBorderLight;
    final Color text = isAdvanced ? bannerTextDark : bannerBorderLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top_rounded, color: icon, size: 24),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: text,
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
  // Returns whether the request was actually created — false means the
  // caller (the onTap handler below) must not proceed to the
  // matching-analysis/confirmed-dialog step, since nothing was booked.
  Future<bool> _createBookingRequest({
    required BuildContext context,
    required String? caregiverId,
    required String caregiverName,
    required String careType,
    required String startDate,
    required String startTime,
    required String endTime,
    required String duration,
    required String endDate,
    required String location,
    double? locationLat,
    double? locationLng,
    bool isEmergency = false,
    // Set when a family member is booking on the patient's behalf — the
    // booking is created under the *patient's* uid, not the signed-in
    // family member's. The profile-completeness gate below is about the
    // signed-in account's own patient profile, which doesn't apply to a
    // family member (who may have no patient profile at all), so it's
    // skipped in that case; the patient's own profile is assumed complete
    // since they were already able to invite someone.
    String? onBehalfOfPatientUid,
  }) async {
    if (onBehalfOfPatientUid == null) {
      if (!await ensurePatientProfileComplete(context)) return false;
      if (!context.mounted) return false;
    }
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return false;
    final isFlexible = careType.contains('Flexible');
    await BookingService.createBookingRequest(
      patientUid: onBehalfOfPatientUid ?? uid,
      createdByUid: uid,
      caregiverId: caregiverId,
      caregiverName: caregiverName,
      careType: careType,
      startDate: startDate,
      startTime: startTime,
      endTime: isFlexible ? endTime : null,
      duration: isFlexible ? null : duration,
      endDate: isFlexible ? null : endDate,
      location: location,
      locationLat: locationLat,
      locationLng: locationLng,
      isEmergency: isEmergency,
    );
    return true;
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
                  if (isAdvanced) {
                    // Advanced flow never has a specific caregiver picked yet
                    // at this step — no booking is created here. The real
                    // request is created later, with a real caregiverId/
                    // name/photo, when the patient taps "Request" on a
                    // specific ranked caregiver in advanced_match_results_
                    // screen.dart. (Previously this created a placeholder
                    // bookingRequests doc with caregiverId: null and the
                    // literal name "Matching caregivers" — no caregiver-side
                    // query ever matches a null caregiverId, so that request
                    // could never actually be seen or accepted by anyone.)
                    final onBehalf = args?['onBehalfOfPatientUid'] as String?;
                    if (onBehalf == null) {
                      if (!await ensurePatientProfileComplete(context)) return;
                      if (!context.mounted) return;
                    }
                    Navigator.pushNamed(
                      context,
                      '/matching-analysis',
                      arguments: args,
                    );
                    return;
                  }
                  final created = await _createBookingRequest(
                    context:       context,
                    caregiverId:   args?['caregiverId'] as String?,
                    caregiverName: caregiverName,
                    careType:      careType,
                    startDate:     startDate,
                    startTime:     startTime,
                    endTime:       endTime,
                    duration:      duration,
                    endDate:       endDate,
                    location:      location,
                    locationLat:   args?['lat'] as double?,
                    locationLng:   args?['lng'] as double?,
                    isEmergency:   args?['isEmergency'] as bool? ?? false,
                    onBehalfOfPatientUid: args?['onBehalfOfPatientUid'] as String?,
                  );
                  if (!created) return;
                  if (!context.mounted) return;
                  final resolvedName =
                      args?['caregiverName'] as String? ?? 'your caregiver';
                  _showConfirmedDialog(
                    context,
                    isAdvanced,
                    accent,
                    accentOnColor,
                    resolvedName,
                  );
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
