import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Schedule Care Screen  (Send-request flow — Step 2)
//  Figma node: 160-2257
// ─────────────────────────────────────────────────────────────
class ScheduleCareScreen extends StatefulWidget {
  const ScheduleCareScreen({super.key});

  @override
  State<ScheduleCareScreen> createState() => _ScheduleCareScreenState();
}

class _ScheduleCareScreenState extends State<ScheduleCareScreen> {
  // ── colours (Figma tokens) ───────────────────────────────
  static const Color _cyan40 = Color(0xFF14B8A6);     // teal – selected time / care period
  static const Color _cyan10 = Color(0xFF042F2A);     // dark teal text on selected chip
  static const Color _green45 = AppTheme.primaryGreen; // #22C55E
  static const Color _green8 = AppTheme.bottleGreen;   // #06240F
  static const Color _azure11 = AppTheme.surfaceColor; // #0F172A
  static const Color _azure17 = AppTheme.cardColor;    // #1E293B
  static const Color _azure27 = AppTheme.borderColor;  // #334155
  static const Color _azure35 = Color(0xFF475569);
  static const Color _azure47 = Color(0xFF64748B);
  static const Color _azure65 = AppTheme.textSecondary; // #94A3B8
  static const Color _azure84 = Color(0xFFCBD5E1);
  static const Color _grey98 = AppTheme.textPrimary;    // #F8FAFC
  static const Color _carePeriodBg = Color(0x2E22C55E); // green 18%

  // ── state ───────────────────────────────────────────────
  // Calendar
  DateTime _focusedMonth = DateTime(2025, 12);
  DateTime _selectedDate = DateTime(2025, 12, 20);

  // Start time
  static const List<String> _times = [
    '6 AM', '8 AM', '10 AM', '12 PM', '2 PM', '4 PM', '6 PM'
  ];
  String _selectedTime = '8 AM';

  // Duration
  static const List<String> _durations = [
    '1 week', '2 weeks', '1 month', '3 months', '6 months', 'Ongoing'
  ];
  String _selectedDuration = '1 month';

  // ── helpers ─────────────────────────────────────────────
  /// Days that are highlighted as "care period" (green 18% bg, green text).
  /// In Figma the care period starts the day after the selected date (21–23 shown).
  List<DateTime> get _carePeriodDays {
    final start = _selectedDate.add(const Duration(days: 1));
    return List.generate(3, (i) => start.add(Duration(days: i)));
  }

  /// "Strikethrough / dimmed" days: weekends before the selected date.
  bool _isUnavailable(DateTime day) {
    // In the Figma mock, 5 & 6 (Fri/Sat of first week, actually Dec 5=Fri, 6=Sat) are struck-through.
    return (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) &&
        day.isBefore(_selectedDate);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInCarePeriod(DateTime day) =>
      _carePeriodDays.any((d) => _isSameDay(d, day));

  /// End date derived from duration selection.
  DateTime get _endDate {
    switch (_selectedDuration) {
      case '1 week':
        return _selectedDate.add(const Duration(days: 7));
      case '2 weeks':
        return _selectedDate.add(const Duration(days: 14));
      case '1 month':
        return DateTime(
            _selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
      case '3 months':
        return DateTime(
            _selectedDate.year, _selectedDate.month + 3, _selectedDate.day);
      case '6 months':
        return DateTime(
            _selectedDate.year, _selectedDate.month + 6, _selectedDate.day);
      case 'Ongoing':
      default:
        return DateTime(
            _selectedDate.year + 1, _selectedDate.month, _selectedDate.day);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  // ── build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildStatusBar(),
                _buildTitleRow(context),
                _buildStepIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCalendar(),
                        const SizedBox(height: 18),
                        _buildStartTimeSection(),
                        const SizedBox(height: 10),
                        _buildLegend(),
                        const SizedBox(height: 18),
                        _buildDurationSection(),
                        const SizedBox(height: 12),
                        _buildDateRangeRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sticky bottom button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomButton(context),
          ),
        ],
      ),
    );
  }

  // ── Status bar ───────────────────────────────────────────
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
                color: _grey98,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: const [
                Icon(Icons.signal_cellular_alt, color: _grey98, size: 18),
                SizedBox(width: 5),
                Icon(Icons.wifi, color: _grey98, size: 18),
                SizedBox(width: 5),
                Icon(Icons.battery_full, color: _grey98, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Title row ────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
          ),
          const SizedBox(width: 10),
          const Text(
            'Schedule care',
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

  // ── Step indicator ───────────────────────────────────────
  Widget _buildStepIndicator() {
    const steps = [
      _StepInfo('1', 'Request', _StepState.done),
      _StepInfo('2', 'Schedule', _StepState.active),
      _StepInfo('3', 'Confirm', _StepState.inactive),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Connector
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    height: 1.5,
                    color: i < 2
                        ? _green45.withValues(alpha: 0.35)
                        : _azure27,
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
    final isDone = s.state == _StepState.done;
    final isInactive = s.state == _StepState.inactive;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? _green45
                : isDone
                    ? _azure17
                    : _azure17,
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : isDone
                      ? _green45
                      : _azure27,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              s.number,
              style: TextStyle(
                color: isActive
                    ? _green8
                    : isDone
                        ? _green45
                        : _azure47,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.label,
          style: TextStyle(
            color: isInactive ? _azure47 : _green45,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Calendar ─────────────────────────────────────────────
  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _azure27),
      ),
      padding: const EdgeInsets.fromLTRB(15, 21, 15, 15),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 8),
          _buildDayLabels(),
          const SizedBox(height: 4),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthName = _monthName(_focusedMonth.month);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _focusedMonth =
                DateTime(_focusedMonth.year, _focusedMonth.month - 1);
          }),
          child: const Icon(Icons.chevron_left, color: _azure84, size: 22),
        ),
        Text(
          '$monthName ${_focusedMonth.year}',
          style: const TextStyle(
            color: _grey98,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _focusedMonth =
                DateTime(_focusedMonth.year, _focusedMonth.month + 1);
          }),
          child: const Icon(Icons.chevron_right, color: _azure84, size: 22),
        ),
      ],
    );
  }

  Widget _buildDayLabels() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: labels
          .map(
            (l) => Expanded(
              child: Center(
                child: Text(
                  l,
                  style: const TextStyle(
                    color: _azure47,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7; // 0=Sun

    final List<Widget> cells = [];

    // Empty leading cells
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      cells.add(_buildDayCell(day));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.55,
      children: cells,
    );
  }

  Widget _buildDayCell(DateTime day) {
    final isSelected = _isSameDay(day, _selectedDate);
    final inPeriod = _isInCarePeriod(day);
    final unavailable = _isUnavailable(day);

    return GestureDetector(
      onTap: unavailable
          ? null
          : () => setState(() => _selectedDate = day),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? _green45
              : inPeriod
                  ? _carePeriodBg
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(isSelected ? 13 : 6),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isSelected
                ? _green8
                : inPeriod
                    ? _green45
                    : unavailable
                        ? _azure35
                        : _azure84,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            decoration: unavailable
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            decorationColor: _azure35,
          ),
        ),
      ),
    );
  }

  // ── Start time chips ─────────────────────────────────────
  Widget _buildStartTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Start time',
          style: TextStyle(
            color: _azure65,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _times.map(_buildTimeChip).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeChip(String time) {
    final selected = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _cyan40 : _azure17,
          borderRadius: BorderRadius.circular(8),
          border: selected ? null : Border.all(color: _azure27),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: selected ? _cyan10 : _azure84,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Legend ───────────────────────────────────────────────
  Widget _buildLegend() {
    return Row(
      children: [
        _legendDot(_cyan40),
        const SizedBox(width: 6),
        const Text(
          'Care period',
          style: TextStyle(color: _azure65, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 14),
        _legendDot(_azure35),
        const SizedBox(width: 6),
        const Text(
          'Existing booking',
          style: TextStyle(color: _azure65, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }

  // ── Duration grid ────────────────────────────────────────
  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How long is care needed?',
          style: TextStyle(
            color: _azure65,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.2,
          children: _durations.map(_buildDurationChip).toList(),
        ),
      ],
    );
  }

  Widget _buildDurationChip(String label) {
    final selected = _selectedDuration == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? _green45.withValues(alpha: 0.15)
              : _azure17,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _green45 : _azure27,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? _green45 : _grey98,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, color: _green45, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  // ── Date range summary ───────────────────────────────────
  Widget _buildDateRangeRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _azure27),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              color: _azure65, size: 16),
          const SizedBox(width: 10),
          Text(
            '${_formatDate(_selectedDate)}  →  ${_formatDate(_endDate)}',
            style: const TextStyle(
              color: _azure84,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom button ────────────────────────────────────────
  Widget _buildBottomButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _azure11.withValues(alpha: 0),
            _azure11,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: SafeArea(
        top: false,
        child: Material(
          color: _green45,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              // TODO: navigate to step 3 (Confirm)
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Review booking details',
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
    );
  }

  // ── Util ─────────────────────────────────────────────────
  String _monthName(int m) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m];
  }
}

// ── Step model ────────────────────────────────────────────────
enum _StepState { done, active, inactive }

class _StepInfo {
  final String number;
  final String label;
  final _StepState state;
  const _StepInfo(this.number, this.label, this.state);
}
