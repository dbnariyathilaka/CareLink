import 'package:flutter/material.dart';

class ScheduleCareScreen extends StatefulWidget {
  const ScheduleCareScreen({super.key});

  @override
  State<ScheduleCareScreen> createState() => _ScheduleCareScreenState();
}

class _ScheduleCareScreenState extends State<ScheduleCareScreen> {
  // ── Light-cream design tokens (Figma) ──
  static const Color bgCream = Color(0xFFF5E8DE);
  static const Color titleGreen = Color(0xFF033724);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color scheduleTypeAccent = Color(0xFFA94813);
  static const Color stepInactiveBg = Color(0xFFDCD9CF);
  static const Color stepLineInactive = Color(0xFFD9D9D9);
  static const Color calendarCardBg = Color.fromRGBO(40, 65, 101, 0.23);
  static const Color calendarHeaderText = Color(0xFF284165);
  static const Color calendarDayText = Color(0xFF25467E);
  static const Color calendarRangeBg = Color(0xFF7CA093);
  static const Color calendarRangeText = Color(0xFF033724);
  static const Color calendarCompletedBg = Color(0xFFA1A0A7);
  static const Color legendText = Color.fromRGBO(2, 5, 24, 0.68);
  static const Color shiftInactiveBg = Color(0xFFE1D5C6);
  static const Color shiftInactiveText = Color(0xFF0F172A);
  static const Color durationInactiveBg = Color.fromRGBO(51, 65, 85, 0.51);
  static const Color durationInactiveText = Color(0xFF071F40);
  static const Color creamButtonText = Color(0xFFF6F0E2);

  // Kept dark — Figma leaves the "Custom duration" trigger and the date
  // range summary card on the old dark panel treatment.
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderDashed = Color(0xFF475569);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color goldAccent = Color(0xFFFBBC05);

  bool _isAdvanced = false;
  String _scheduleType = 'Flexible';

  // Primary accent — dark green normally, teal for the "advanced match" flow.
  Color get _accent => _isAdvanced ? const Color(0xFF3DB498) : darkGreen;
  Color get _accentOnColor => _isAdvanced ? const Color(0xFF06291F) : Colors.white;
  Color get _shiftActiveBg => _isAdvanced ? _accent : const Color(0xFF0F3D2E);
  Color get _durationActiveBg => _isAdvanced ? _accent : const Color(0xFF071F40);
  Color get _calendarSelectedBg => _isAdvanced ? _accent : darkGreen;
  // Part-time's time-picker card keeps the old dark panel treatment with a
  // spring-green highlight, matching the Figma reference exactly.
  Color get _timePickerAccent => _isAdvanced ? _accent : const Color(0xFF22C55E);

  // ── State variables ──
  late DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  // For Full-time: shifts
  final List<String> _shifts = [
    '8:00 AM – 5:00 PM',
    '2:00 PM – 10:00 PM',
    '10:00 PM – 6:00 AM',
  ];
  final List<String> _shiftLabels = [
    'Day shift',
    'Evening shift',
    'Overnight shift',
  ];
  final List<IconData> _shiftIcons = [
    Icons.wb_sunny_rounded,
    Icons.wb_twilight_rounded,
    Icons.bedtime_rounded,
  ];
  int _selectedShiftIndex = 0;

  // For Part-time / Half-time: Wheel Time Picker states
  int _ptHour = 9;
  int _ptMinute = 0;
  String _ptPeriod = 'AM'; // 'AM' or 'PM'

  // Presets list for Part-time
  final List<String> _ptPresets = ['9 AM', '12 PM', '4 PM', '6 PM'];

  // For Flexible: start and end times
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  // For Flexible: selected dates
  late final Set<DateTime> _flexibleDates = {
    _selectedDate,
    _selectedDate.add(const Duration(days: 2)),
    _selectedDate.add(const Duration(days: 4)),
  };

  // Duration
  final List<String> _durations = [
    '1 week',
    '2 weeks',
    '1 month',
    '3 months',
    '6 months',
    '1 year',
  ];
  String _selectedDuration = '1 month';
  bool _isCustomDurationActive = false;

  // Helper date parsing/formatting
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isUnavailable(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return day.isBefore(today);
  }

  // End Date derived from duration selection
  DateTime get _endDate {
    final parts = _selectedDuration.split(' ');
    if (parts.length == 2) {
      final amount = int.tryParse(parts[0]) ?? 1;
      final unit = parts[1].toLowerCase();

      if (unit.startsWith('day')) {
        return _selectedDate.add(Duration(days: amount));
      } else if (unit.startsWith('week')) {
        return _selectedDate.add(Duration(days: amount * 7));
      } else if (unit.startsWith('month')) {
        return DateTime(_selectedDate.year, _selectedDate.month + amount, _selectedDate.day);
      } else if (unit.startsWith('year')) {
        return DateTime(_selectedDate.year + amount, _selectedDate.month, _selectedDate.day);
      }
    }
    return _selectedDate.add(const Duration(days: 30));
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  // Calculated Part-time End Time (+4 hours)
  String get _ptEndTimeFormatted {
    int endHour = _ptHour + 4;
    String endPeriod = _ptPeriod;
    if (endHour >= 12) {
      if (endHour > 12) endHour -= 12;
      endPeriod = _ptPeriod == 'AM' ? 'PM' : 'AM';
    }
    final minStr = _ptMinute.toString().padLeft(2, '0');
    return '$endHour:$minStr $endPeriod';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _selectTime(bool isStart) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (selected != null) {
      setState(() {
        if (isStart) {
          _startTime = selected;
        } else {
          _endTime = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String scheduleType = 'Flexible';
    bool isAdvanced = false;

    if (args is String) {
      scheduleType = args;
    } else if (args is Map<String, dynamic>) {
      scheduleType = args['schedule'] ?? 'Flexible';
      isAdvanced = args['isAdvanced'] ?? false;
    }

    _isAdvanced = isAdvanced;

    // Normalise Half-time argument to Part-time
    if (scheduleType == 'Half-time') {
      scheduleType = 'Part-time';
    }
    _scheduleType = scheduleType;

    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTitleRow(context),
                _buildStepIndicator(isAdvanced),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 58),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      scheduleType,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: _isAdvanced ? _accent : scheduleTypeAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (scheduleType == 'Full-time') ..._buildFullTimeLayout(),
                        if (scheduleType == 'Part-time') ..._buildPartTimeLayout(),
                        if (scheduleType == 'Flexible') ..._buildFlexibleLayout(),
                        if (scheduleType == 'Live-in') ..._buildLiveInLayout(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sticky bottom Continue button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomButton(context, scheduleType, isAdvanced),
          ),
        ],
      ),
    );
  }

  // ── 1. Title Row ──
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
            'Schedule Care',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: titleGreen,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Progress step indicator ──
  Widget _buildStepIndicator(bool isAdvanced) {
    final steps = isAdvanced
        ? const [
            _StepInfo('1', 'Request', _StepState.done),
            _StepInfo('2', 'Schedule', _StepState.active),
            _StepInfo('3', 'Location', _StepState.inactive),
            _StepInfo('4', 'Qualifications', _StepState.inactive),
            _StepInfo('5', 'Confirm', _StepState.inactive),
          ]
        : const [
            _StepInfo('1', 'Request', _StepState.done),
            _StepInfo('2', 'Schedule', _StepState.active),
            _StepInfo('3', 'Location', _StepState.inactive),
            _StepInfo('4', 'Confirm', _StepState.inactive),
          ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = steps[i ~/ 2].state != _StepState.inactive;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 3,
                decoration: BoxDecoration(
                  color: leftDone ? _accent : stepLineInactive,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }
          return _buildStepBubble(steps[i ~/ 2]);
        }),
      ),
    );
  }

  Widget _buildStepBubble(_StepInfo s) {
    final isFilled = s.state != _StepState.inactive;

    return Column(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? _accent : stepInactiveBg,
          ),
          child: Center(
            child: Text(
              s.number,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: isFilled ? _accentOnColor : Colors.black,
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
  }

  // ── Parallel layouts ──

  // A. Full-time Option Layout
  List<Widget> _buildFullTimeLayout() {
    return [
      _buildCalendar(multiSelect: false),
      const SizedBox(height: 22),
      _buildChooseShiftSection(),
      const SizedBox(height: 24),
      _buildDurationSection(),
      const SizedBox(height: 14),
      _buildCustomDurationToggleOrChip(),
      const SizedBox(height: 12),
      _buildDateRangeSummaryCard(),
    ];
  }

  // B. Part-time Option Layout
  List<Widget> _buildPartTimeLayout() {
    return [
      _buildCalendar(multiSelect: false),
      const SizedBox(height: 22),
      const Text(
        'Start time',
        style: TextStyle(
          fontFamily: 'Open Sans',
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      _buildPartTimeTimePickerCard(),
      const SizedBox(height: 12),
      _buildPartTimeEndTimeCard(),
      const SizedBox(height: 24),
      _buildDurationSection(),
      const SizedBox(height: 14),
      _buildCustomDurationToggleOrChip(),
      const SizedBox(height: 12),
      _buildDateRangeSummaryCard(),
    ];
  }

  // C. Flexible Option Layout
  List<Widget> _buildFlexibleLayout() {
    return [
      _buildCalendar(multiSelect: false),
      const SizedBox(height: 22),
      _buildTimeCard(
        label: 'Start time',
        time: _startTime,
        onTap: () => _selectTime(true),
      ),
      const SizedBox(height: 14),
      _buildTimeCard(
        label: 'End time',
        time: _endTime,
        onTap: () => _selectTime(false),
      ),
    ];
  }

  // D. Live-in Option Layout
  List<Widget> _buildLiveInLayout() {
    return [
      _buildCalendar(multiSelect: false),
      const SizedBox(height: 22),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3D2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: darkBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.home_rounded, color: Color(0xFFFFA722), size: 22),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'Caregiver stays on-site, day and night',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: darkTextSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _buildDurationSection(),
      const SizedBox(height: 14),
      _buildCustomDurationToggleOrChip(),
      const SizedBox(height: 12),
      _buildDateRangeSummaryCard(),
    ];
  }

  // ── Component Widgets ──

  Widget _buildCalendar({required bool multiSelect}) {
    return Container(
      decoration: BoxDecoration(
        color: calendarCardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(4, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(15, 21, 15, 15),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 10),
          Divider(color: calendarHeaderText.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 8),
          _buildDayLabels(),
          const SizedBox(height: 4),
          _buildCalendarGrid(multiSelect: multiSelect),
          const SizedBox(height: 10),
          Divider(color: calendarHeaderText.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = months[_focusedMonth.month];
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final canGoBack = _focusedMonth.isAfter(currentMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: canGoBack
              ? () => setState(() {
                    _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  })
              : null,
          child: Icon(
            Icons.chevron_left,
            color: canGoBack ? calendarHeaderText : calendarHeaderText.withValues(alpha: 0.3),
            size: 22,
          ),
        ),
        Text(
          '$monthName ${_focusedMonth.year}',
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: calendarHeaderText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _focusedMonth =
                DateTime(_focusedMonth.year, _focusedMonth.month + 1);
          }),
          child: const Icon(Icons.chevron_right, color: calendarHeaderText, size: 22),
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
                    fontFamily: 'Open Sans',
                    color: calendarDayText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid({required bool multiSelect}) {
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
      cells.add(_buildDayCell(day, multiSelect: multiSelect));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 4,
      childAspectRatio: 1.55,
      children: cells,
    );
  }

  Widget _buildDayCell(DateTime day, {required bool multiSelect}) {
    final isSelected = _isSameDay(day, _selectedDate);

    // Calculate duration in days
    final int durationDays = _endDate.difference(_selectedDate).inDays;

    // Highlight care range starting from selected start date (service dates = user selected duration - 1)
    final bool inRange = _scheduleType != 'Flexible' &&
        day.isAfter(_selectedDate) &&
        day.isBefore(_selectedDate.add(Duration(days: durationDays)));

    final unavailable = _isUnavailable(day);

    return GestureDetector(
      onTap: unavailable
          ? null
          : () => setState(() {
                if (multiSelect) {
                  final matches = _flexibleDates.where((d) => _isSameDay(d, day));
                  if (matches.isNotEmpty) {
                    _flexibleDates.removeWhere((d) => _isSameDay(d, day));
                  } else {
                    _flexibleDates.add(day);
                  }
                  if (_flexibleDates.isNotEmpty) {
                    _selectedDate = _flexibleDates.reduce((a, b) => a.isBefore(b) ? a : b);
                  } else {
                    _selectedDate = day;
                  }
                } else {
                  _selectedDate = day;
                }
              }),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? _calendarSelectedBg
              : inRange
                  ? calendarRangeBg
                  : unavailable
                      ? calendarCompletedBg
                      : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: isSelected
                ? _accentOnColor
                : inRange
                    ? calendarRangeText
                    : unavailable
                        ? calendarDayText
                        : calendarDayText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        _legendDot(_calendarSelectedBg, 'Selected'),
        _legendDot(calendarRangeBg, 'Booked period'),
        _legendDot(calendarCompletedBg, 'Completed'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: legendText,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Shift selection for Full-time
  Widget _buildChooseShiftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a shift',
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: List.generate(_shifts.length, (index) {
            final active = _selectedShiftIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedShiftIndex = index),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: active ? _shiftActiveBg : shiftInactiveBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: active ? 0.3 : 0.2),
                        blurRadius: 2,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _shiftIcons[index],
                        color: active ? Colors.white : shiftInactiveText,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shifts[index],
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: active ? Colors.white : shiftInactiveText,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _shiftLabels[index],
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: active ? Colors.white : shiftInactiveText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (active)
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Part-time specific widgets ──

  Widget _buildPartTimeTimePickerCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Time',
              style: TextStyle(
                color: darkTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSimulatedWheelPicker(),
          const SizedBox(height: 16),
          const Text(
            'Presets',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: darkTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _ptPresets.map((preset) {
              bool isPresetSelected = false;
              if (preset == '9 AM' && _ptHour == 9 && _ptMinute == 0 && _ptPeriod == 'AM') {
                isPresetSelected = true;
              } else if (preset == '12 PM' && _ptHour == 12 && _ptMinute == 0 && _ptPeriod == 'PM') {
                isPresetSelected = true;
              } else if (preset == '4 PM' && _ptHour == 4 && _ptMinute == 0 && _ptPeriod == 'PM') {
                isPresetSelected = true;
              } else if (preset == '6 PM' && _ptHour == 6 && _ptMinute == 0 && _ptPeriod == 'PM') {
                isPresetSelected = true;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (preset == '9 AM') {
                          _ptHour = 9; _ptMinute = 0; _ptPeriod = 'AM';
                        } else if (preset == '12 PM') {
                          _ptHour = 12; _ptMinute = 0; _ptPeriod = 'PM';
                        } else if (preset == '4 PM') {
                          _ptHour = 4; _ptMinute = 0; _ptPeriod = 'PM';
                        } else if (preset == '6 PM') {
                          _ptHour = 6; _ptMinute = 0; _ptPeriod = 'PM';
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isPresetSelected ? _timePickerAccent.withValues(alpha: 0.15) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPresetSelected ? _timePickerAccent : darkBorder,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        preset.toLowerCase(),
                        style: TextStyle(
                          color: isPresetSelected ? _timePickerAccent : darkTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedWheelPicker() {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 38,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _timePickerAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _timePickerAccent.withValues(alpha: 0.4), width: 1),
              ),
            ),
          ),
          ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.15, 0.85, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 32,
                    clipBehavior: Clip.none,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _ptHour = index + 1;
                      });
                    },
                    controller: FixedExtentScrollController(initialItem: _ptHour - 1),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 12,
                      builder: (context, index) {
                        final itemHour = index + 1;
                        final isSelected = itemHour == _ptHour;
                        return Center(
                          child: Text(
                            '$itemHour',
                            style: TextStyle(
                              color: isSelected ? darkTextPrimary : darkBorder,
                              fontSize: isSelected ? 19 : 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 32,
                    clipBehavior: Clip.none,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _ptMinute = index;
                      });
                    },
                    controller: FixedExtentScrollController(initialItem: _ptMinute),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 60,
                      builder: (context, index) {
                        final itemMinute = index;
                        final isSelected = itemMinute == _ptMinute;
                        return Center(
                          child: Text(
                            itemMinute.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: isSelected ? darkTextPrimary : darkBorder,
                              fontSize: isSelected ? 19 : 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 32,
                    clipBehavior: Clip.none,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _ptPeriod = index == 0 ? 'AM' : 'PM';
                      });
                    },
                    controller: FixedExtentScrollController(initialItem: _ptPeriod == 'AM' ? 0 : 1),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 2,
                      builder: (context, index) {
                        final itemPeriod = index == 0 ? 'AM' : 'PM';
                        final isSelected = itemPeriod == _ptPeriod;
                        return Center(
                          child: Text(
                            itemPeriod.toLowerCase(),
                            style: TextStyle(
                              color: isSelected ? darkTextPrimary : darkBorder,
                              fontSize: isSelected ? 19 : 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartTimeEndTimeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled_rounded, color: goldAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'End time (4 hr shift)',
                  style: TextStyle(
                    color: darkTextMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _ptEndTimeFormatted,
                  style: const TextStyle(
                    color: darkTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // End of Part-time specific widgets

  Widget _buildTimeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            decoration: BoxDecoration(
              color: darkCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: darkBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    color: darkTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.expand_more_rounded, color: darkTextMuted, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Duration Grid Section
  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How long is care needed?',
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _durations.length,
          itemBuilder: (context, index) {
            final label = _durations[index];
            final active = _selectedDuration == label;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedDuration = label;
                _isCustomDurationActive = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: active ? _durationActiveBg : durationInactiveBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: active ? Colors.white : durationInactiveText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (active)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomDurationToggleOrChip() {
    if (_isCustomDurationActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        decoration: BoxDecoration(
          color: darkCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDuration,
              style: TextStyle(
                color: _accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDuration = '1 month';
                  _isCustomDurationActive = false;
                });
              },
              child: Icon(Icons.close_rounded, color: _accent, size: 20),
            ),
          ],
        ),
      );
    }

    // Dark dashed "Custom duration" trigger — Figma keeps this panel on the
    // old dark treatment even though the rest of the screen is light.
    return GestureDetector(
      onTap: _showCustomDurationDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        decoration: BoxDecoration(
          color: darkCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: darkBorderDashed, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Custom duration',
              style: TextStyle(
                color: darkTextSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(Icons.tune_rounded, color: darkTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCustomDurationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempUnit = 'Days';
        int tempAmount = 1;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: darkCardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Custom duration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: darkTextSecondary),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Unit selector row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['Days', 'Weeks', 'Months', 'Years'].map((unit) {
                        final isSelected = tempUnit == unit;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() => tempUnit = unit);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? _accent.withValues(alpha: 0.18) : const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? _accent : darkBorder,
                                    width: 1.2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  unit,
                                  style: TextStyle(
                                    color: isSelected ? _accent : darkTextMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    const Text(
                      'Amount',
                      style: TextStyle(
                        color: darkTextMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Amount counter card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$tempAmount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setDialogState(() => tempAmount++);
                                },
                                child: const Icon(Icons.keyboard_arrow_up_rounded, color: darkTextMuted, size: 20),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  if (tempAmount > 1) {
                                    setDialogState(() => tempAmount--);
                                  }
                                },
                                child: const Icon(Icons.keyboard_arrow_down_rounded, color: darkTextMuted, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            final singularUnit = tempUnit.toLowerCase().substring(0, tempUnit.length - 1);
                            _selectedDuration = tempAmount == 1
                                ? '1 $singularUnit'
                                : '$tempAmount ${tempUnit.toLowerCase()}';
                            _isCustomDurationActive = true;
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Apply',
                          style: TextStyle(
                            color: _accentOnColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempAmount = 1;
                            tempUnit = 'Days';
                          });
                        },
                        child: const Text(
                          'Reset to default',
                          style: TextStyle(
                            color: darkTextMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateRangeSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: goldAccent, size: 18),
          const SizedBox(width: 10),
          Text(
            _formatDate(_selectedDate),
            style: const TextStyle(
              color: darkTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, color: darkTextMuted, size: 15),
          const SizedBox(width: 8),
          Text(
            _formatDate(_endDate),
            style: const TextStyle(
              color: darkTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Button ──
  Widget _buildBottomButton(BuildContext context, String scheduleType, bool isAdvanced) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgCream.withValues(alpha: 0),
            bgCream,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: darkGreen,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: darkGreen.withValues(alpha: 0.5), blurRadius: 2, offset: const Offset(2, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                if (scheduleType == 'Flexible') {
                  final startMins = _startTime.hour * 60 + _startTime.minute;
                  final endMins = _endTime.hour * 60 + _endTime.minute;
                  if (endMins <= startMins) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('End time must be after start time.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  if (endMins - startMins < 60) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('There must be a minimum gap of 1 hour between start and end times.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                }
                Navigator.pushNamed(
                  context,
                  '/location-selection',
                  arguments: {
                    'isAdvanced': isAdvanced,
                    'schedule': scheduleType,
                    'startDate': _formatDate(_selectedDate),
                    'startTime': _formatTime(scheduleType == 'Part-time'
                        ? TimeOfDay(hour: _ptHour, minute: _ptMinute)
                        : _startTime),
                    'endTime': _formatTime(_endTime),
                    'duration': scheduleType == 'Flexible' ? '1 day' : _selectedDuration,
                    'endDate': _formatDate(scheduleType == 'Flexible' ? _selectedDate : _endDate),
                    'careType': 'Elder · $scheduleType',
                  },
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: creamButtonText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step info model ──
enum _StepState { done, active, inactive }

class _StepInfo {
  final String number;
  final String label;
  final _StepState state;
  const _StepInfo(this.number, this.label, this.state);
}
