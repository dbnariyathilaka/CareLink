import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScheduleCareScreen extends StatefulWidget {
  const ScheduleCareScreen({super.key});

  @override
  State<ScheduleCareScreen> createState() => _ScheduleCareScreenState();
}

class _ScheduleCareScreenState extends State<ScheduleCareScreen> {
  // Colors (Figma tokens mapped to AppTheme)
  static const Color _azure11 = AppTheme.surfaceColor; // #0F172A
  static const Color _azure17 = AppTheme.cardColor;    // #1E293B
  static const Color _azure27 = AppTheme.borderColor;  // #334155
  static const Color _azure35 = Color(0xFF475569);
  static const Color _azure47 = Color(0xFF64748B);
  static const Color _azure65 = AppTheme.textSecondary; // #94A3B8
  static const Color _azure84 = Color(0xFFCBD5E1);
  static const Color _grey98 = AppTheme.textPrimary;    // #F8FAFC

  bool _isAdvanced = false;
  String _scheduleType = 'Flexible';
  Color get _green45 => _isAdvanced ? const Color(0xFF3DB498) : AppTheme.primaryGreen;
  Color get _green8 => _isAdvanced ? const Color(0xFF06291F) : AppTheme.bottleGreen;
  Color get _carePeriodBg => _isAdvanced ? const Color(0xFF3DB498).withValues(alpha: 0.18) : const Color(0x2E22C55E);

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
      backgroundColor: _azure11,
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
                        color: _green45,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 110),
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
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
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

  // ── 2. 4-step progress indicator ──
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
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 1.5,
                color: i < 2 ? _green45.withValues(alpha: 0.35) : _azure27,
              ),
            );
          }
          return _buildStepBubble(steps[i ~/ 2]);
        }),
      ),
    );
  }

  Widget _buildStepBubble(_StepInfo s) {
    final isActive = s.state == _StepState.active;
    final isDone = s.state == _StepState.done;

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _green45 : _azure17,
            border: Border.all(
              color: isActive || isDone ? _green45 : _azure27,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              s.number,
              style: TextStyle(
                color: isActive ? _green8 : (isDone ? _green45 : _azure47),
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
            color: isActive || isDone ? _green45 : _azure47,
            fontSize: 8,
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
      const SizedBox(height: 18),
      _buildChooseShiftSection(),
      const SizedBox(height: 24),
      _buildDurationSection(),
      const SizedBox(height: 16),
      _buildCustomDurationToggleOrChip(),
      const SizedBox(height: 12),
      _buildDateRangeSummaryCard(),
    ];
  }

  // B. Part-time Option Layout
  List<Widget> _buildPartTimeLayout() {
    return [
      _buildCalendar(multiSelect: false),
      const SizedBox(height: 18),
      const Text(
        'Start time',
        style: TextStyle(
          color: _azure65,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      _buildPartTimeTimePickerCard(),
      const SizedBox(height: 12),
      _buildPartTimeEndTimeCard(),
      const SizedBox(height: 24),
      _buildDurationSection(),
      const SizedBox(height: 16),
      _buildCustomDurationToggleOrChip(),
      const SizedBox(height: 12),
      _buildDateRangeSummaryCard(),
    ];
  }

  // C. Flexible Option Layout
  List<Widget> _buildFlexibleLayout() {
    return [
      _buildCalendar(multiSelect: false),
      const SizedBox(height: 18),
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
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _azure27),
        ),
        child: Row(
          children: [
            Icon(
              Icons.home_work_rounded,
              color: _green45,
              size: 22,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Caregiver stays on-site, day and night',
                style: TextStyle(
                  color: _azure84,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _buildDurationSection(),
      const SizedBox(height: 16),
      _buildCustomDurationToggleOrChip(),
      const SizedBox(height: 12),
      _buildDateRangeSummaryCard(),
    ];
  }

  // ── Component Widgets ──

  Widget _buildCalendar({required bool multiSelect}) {
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
          _buildCalendarGrid(multiSelect: multiSelect),
          const SizedBox(height: 14),
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
            color: canGoBack ? _azure84 : _azure35,
            size: 22,
          ),
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
      mainAxisSpacing: 4,
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
              ? _green45
              : inRange
                  ? _carePeriodBg
                  : Colors.transparent,
          borderRadius: BorderRadius.circular((isSelected || inRange) ? 13 : 6),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isSelected
                ? _green8
                : inRange
                    ? _green45
                    : unavailable
                        ? const Color(0xFF3F4B5E)
                        : _azure84,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _legendDot(_green45, 'Selected'),
        const SizedBox(width: 14),
        _legendDot(_carePeriodBg, 'Booked period'),
        const SizedBox(width: 14),
        _legendDot(_azure35, 'Completed'),
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
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _azure65,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Shift selection for Full-time
  Widget _buildChooseShiftSection() {
    const shiftIcons = [
      Icons.wb_sunny_rounded,
      Icons.wb_twilight_rounded,
      Icons.nightlight_round,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a shift',
          style: TextStyle(
            color: _azure65,
            fontSize: 13,
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
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                  decoration: BoxDecoration(
                    color: active ? _green45.withValues(alpha: 0.15) : _azure17,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? _green45 : _azure27,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        shiftIcons[index],
                        color: active ? _green45 : _azure84,
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
                                color: active ? _green45 : _grey98,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _shiftLabels[index],
                              style: const TextStyle(
                                color: _azure65,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (active) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          color: _green45,
                          size: 22,
                        ),
                      ],
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
        color: _azure17,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _azure27),
      ),
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered 'Time' text
          const Center(
            child: Text(
              'Time',
              style: TextStyle(
                color: _grey98,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Custom simulated Wheel Picker
          _buildSimulatedWheelPicker(),
          const SizedBox(height: 16),
          // Presets label
          const Text(
            'Presets',
            style: TextStyle(
              color: _azure65,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Presets row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _ptPresets.map((preset) {
              // check if preset matches active selection
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
                        color: isPresetSelected
                            ? _green45.withValues(alpha: 0.15)
                            : _azure11,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPresetSelected ? _green45 : _azure27,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        preset.toLowerCase(),
                        style: TextStyle(
                          color: isPresetSelected ? _green45 : _azure84,
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
    // Left, center, and right lists
    // Columns are Hour, Minute, AM/PM
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        children: [
          // Middle selected highlights bar
          Center(
            child: Container(
              height: 38,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _green45.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _green45.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
            ),
          ),
          // Scroll widgets
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
                // 1. Hour Column
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
                              color: isSelected ? _grey98 : _azure35,
                              fontSize: isSelected ? 19 : 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 2. Minute Column
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
                              color: isSelected ? _grey98 : _azure35,
                              fontSize: isSelected ? 19 : 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 3. Period Column
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
                              color: isSelected ? _grey98 : _azure35,
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
        color: _azure17,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _azure27),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_filled_rounded,
            color: _green45,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'End time (4 hr shift)',
                  style: TextStyle(
                    color: _azure65,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _ptEndTimeFormatted,
                  style: const TextStyle(
                    color: _grey98,
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
            color: _azure65,
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
              color: _azure17,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _azure27),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    color: _grey98,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  color: _azure84,
                  size: 22,
                ),
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
            color: _azure65,
            fontSize: 13,
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
                  color: active ? _green45.withValues(alpha: 0.15) : _azure17,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? _green45 : _azure27,
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: active ? _green45 : _grey98,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (active)
                      Positioned(
                        top: 6,
                        right: 8,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: _green45,
                          size: 15,
                        ),
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
      // Display active green custom chip with close 'x' icon
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        decoration: BoxDecoration(
          color: _green45.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _green45, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDuration,
              style: TextStyle(
                color: _green45,
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
              child: Icon(Icons.close_rounded, color: _green45, size: 20),
            ),
          ],
        ),
      );
    }

    // Default dashed custom button
    return GestureDetector(
      onTap: _showCustomDurationDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF475569),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Custom duration',
              style: TextStyle(
                color: _azure84,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(Icons.tune_rounded, color: _azure84, size: 20),
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
              backgroundColor: const Color(0xFF1E293B),
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
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
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
                                  color: isSelected
                                      ? (_isAdvanced ? _green45.withValues(alpha: 0.18) : const Color(0x2EF59E0B))
                                      : const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? (_isAdvanced ? _green45 : const Color(0xFFF59E0B))
                                        : const Color(0xFF334155),
                                    width: 1.2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  unit,
                                  style: TextStyle(
                                    color: isSelected
                                        ? (_isAdvanced ? _green45 : const Color(0xFFF59E0B))
                                        : const Color(0xFF94A3B8),
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
                        color: Color(0xFF94A3B8),
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
                                child: const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF94A3B8), size: 20),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  if (tempAmount > 1) {
                                    setDialogState(() => tempAmount--);
                                  }
                                },
                                child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 20),
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
                          backgroundColor: _green45,
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
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Color(0xFF06240F),
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
                            color: Color(0xFF94A3B8),
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
        color: _azure17,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _azure27),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded,
              color: _green45, size: 18),
          const SizedBox(width: 10),
          Text(
            '${_formatDate(_selectedDate)}  →  ${_formatDate(_endDate)}',
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

  // ── Bottom Button ──
  Widget _buildBottomButton(BuildContext context, String scheduleType, bool isAdvanced) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Continue',
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
}

// ── Step info model ──
enum _StepState { done, active, inactive }

class _StepInfo {
  final String number;
  final String label;
  final _StepState state;
  const _StepInfo(this.number, this.label, this.state);
}
