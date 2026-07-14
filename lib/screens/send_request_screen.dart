import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SendRequestScreen extends StatefulWidget {
  const SendRequestScreen({super.key});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  // Dropdown options
  static const List<String> _workSchedules = [
    'Full-time',
    'Half-time',
    'Flexible',
    'Live-in',
  ];
  String _selectedWorkSchedule = 'Flexible';
  bool _dropdownOpen = false;

  final TextEditingController _notesController = TextEditingController(
    text:
        'Needs help with morning medication, mobility around the house, and meal prep. Mother is 78.',
  );

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_dropdownOpen) setState(() => _dropdownOpen = false);
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildTitleRow(context),
                  _buildStepIndicator(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCaregiverCard(),
                          const SizedBox(height: 22),
                          _buildWorkScheduleSection(),
                          const SizedBox(height: 20),
                          _buildSpecialNotesSection(),
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
      ),
    );
  }

  // ── Title row ─────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back,
                color: AppTheme.textPrimary, size: 24),
          ),
          const SizedBox(width: 10),
          const Text(
            'Send request',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4-step progress indicator ─────────────────────────────
  Widget _buildStepIndicator() {
    const steps = [
      _StepData(number: '1', label: 'Request', active: true),
      _StepData(number: '2', label: 'Schedule', active: false),
      _StepData(number: '3', label: 'Location', active: false),
      _StepData(number: '4', label: 'Confirm', active: false),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 1.5,
                color: AppTheme.borderColor,
              ),
            );
          }
          final step = steps[i ~/ 2];
          return _buildStepBubble(step);
        }),
      ),
    );
  }

  Widget _buildStepBubble(_StepData step) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step.active ? AppTheme.primaryGreen : AppTheme.inputBackground,
            border: Border.all(
              color: step.active ? AppTheme.primaryGreen : AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              step.number,
              style: TextStyle(
                color:
                    step.active ? AppTheme.bottleGreen : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(
            color: step.active ? AppTheme.primaryGreen : AppTheme.textSecondary,
            fontSize: 9,
            fontWeight: step.active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Caregiver summary card ────────────────────────────────
  Widget _buildCaregiverCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Green gradient avatar
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              ),
            ),
            child: const Center(
              child: Text(
                'AF',
                style: TextStyle(
                  color: AppTheme.bottleGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Alice Fernando',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Elder care · 7 yrs exp',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Match score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '92% match',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Work schedule dropdown ──────────────────────────────────
  Widget _buildWorkScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Work schedule',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Custom dropdown
        GestureDetector(
          onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(10),
                topRight: const Radius.circular(10),
                bottomLeft: Radius.circular(_dropdownOpen ? 0 : 10),
                bottomRight: Radius.circular(_dropdownOpen ? 0 : 10),
              ),
              border: Border.all(
                color: _dropdownOpen
                    ? AppTheme.primaryGreen
                    : AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedWorkSchedule,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                AnimatedRotation(
                  turns: _dropdownOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textPrimary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Dropdown list
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border(
                left: BorderSide(color: AppTheme.primaryGreen, width: 1),
                right: BorderSide(color: AppTheme.primaryGreen, width: 1),
                bottom: BorderSide(color: AppTheme.primaryGreen, width: 1),
              ),
            ),
            child: Column(
              children: _workSchedules
                  .map(
                    (schedule) => GestureDetector(
                      onTap: () => setState(() {
                        _selectedWorkSchedule = schedule;
                        _dropdownOpen = false;
                      }),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 17, vertical: 13),
                        decoration: BoxDecoration(
                          color: _selectedWorkSchedule == schedule
                              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: schedule != _workSchedules.last
                              ? const Border(
                                  bottom: BorderSide(
                                      color: AppTheme.borderColor,
                                      width: 0.5))
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              schedule,
                              style: TextStyle(
                                color: _selectedWorkSchedule == schedule
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: _selectedWorkSchedule == schedule
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (_selectedWorkSchedule == schedule)
                              const Icon(Icons.check_rounded,
                                  color: AppTheme.primaryGreen, size: 16),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          crossFadeState: _dropdownOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  // ── Special notes textarea ────────────────────────────────
  Widget _buildSpecialNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special notes',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 5,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText:
                'Add any special requirements or notes for the caregiver...',
            hintStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppTheme.inputBackground,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppTheme.primaryGreen, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sticky bottom button ──────────────────────────────────
  Widget _buildBottomButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.surfaceColor.withValues(alpha: 0),
            AppTheme.surfaceColor,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: SafeArea(
        top: false,
        child: Material(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/schedule-care',
                arguments: _selectedWorkSchedule,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Continue to schedule',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.bottleGreen,
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

// ── Step data model ───────────────────────────────────────
class _StepData {
  final String number;
  final String label;
  final bool active;
  const _StepData(
      {required this.number, required this.label, required this.active});
}
