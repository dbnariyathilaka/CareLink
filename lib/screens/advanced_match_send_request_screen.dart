import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdvancedMatchSendRequestScreen extends StatefulWidget {
  const AdvancedMatchSendRequestScreen({super.key});

  @override
  State<AdvancedMatchSendRequestScreen> createState() => _AdvancedMatchSendRequestScreenState();
}

class _AdvancedMatchSendRequestScreenState extends State<AdvancedMatchSendRequestScreen> {
  // Figma design colors mapped to AppTheme
  static const Color _cyan47 = Color(0xFF3DB498);      // Keppel / Cyan `#3db498`
  static const Color _green8 = Color(0xFF06291F);      // Bottle Green `#06291f`
  static const Color _azure11 = AppTheme.surfaceColor; // #0F172A
  static const Color _azure17 = AppTheme.cardColor;    // #1E293B
  static const Color _azure27 = AppTheme.borderColor;  // #334155
  static const Color _azure65 = AppTheme.textSecondary; // #94A3B8
  static const Color _grey98 = AppTheme.textPrimary;    // #F8FAFC

  // Dropdown Options
  static const List<String> _workSchedules = [
    'Flexible',
    'Full-time',
    'Part-time',
    'Live-in',
  ];
  String _selectedWorkSchedule = 'Flexible';
  bool _dropdownOpen = false;

  final TextEditingController _notesController = TextEditingController();

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
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBenefitsCardList(),
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
            'Send request',
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

  // ── 2. 5-step progress indicator ──
  Widget _buildStepIndicator() {
    const steps = [
      _StepInfo('1', 'Request', true),
      _StepInfo('2', 'Schedule', false),
      _StepInfo('3', 'Location', false),
      _StepInfo('4', 'Qualifications', false),
      _StepInfo('5', 'Confirm', false),
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
                color: _azure27,
              ),
            );
          }
          return _buildStepBubble(steps[i ~/ 2]);
        }),
      ),
    );
  }

  Widget _buildStepBubble(_StepInfo s) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.active ? _cyan47 : _azure17,
            border: Border.all(
              color: s.active ? _cyan47 : _azure27,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              s.number,
              style: TextStyle(
                color: s.active ? _green8 : _azure65,
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
            color: s.active ? _cyan47 : _azure65,
            fontSize: 8.5,
            fontWeight: s.active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── 3. Three Benefits Info Cards ──
  Widget _buildBenefitsCardList() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.verified_user_rounded,
          text: 'Your request goes only to caregivers who meet the qualifications you selected.',
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          icon: Icons.timer_rounded,
          text: 'Most matching caregivers respond within 6 hours of a request.',
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          icon: Icons.lock_outline_rounded,
          text: 'Your contact details stay private until you confirm a booking.',
        ),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _azure27),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _cyan47, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _azure65,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Dropdown Section ──
  Widget _buildWorkScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Work schedule',
          style: TextStyle(
            color: _azure65,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            decoration: BoxDecoration(
              color: _azure17,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(10),
                topRight: const Radius.circular(10),
                bottomLeft: Radius.circular(_dropdownOpen ? 0 : 10),
                bottomRight: Radius.circular(_dropdownOpen ? 0 : 10),
              ),
              border: Border.all(
                color: _dropdownOpen ? _cyan47 : _azure27,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedWorkSchedule,
                  style: const TextStyle(
                    color: _grey98,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                AnimatedRotation(
                  turns: _dropdownOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _grey98,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _azure17,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border(
                left: BorderSide(color: _cyan47, width: 1),
                right: BorderSide(color: _cyan47, width: 1),
                bottom: BorderSide(color: _cyan47, width: 1),
              ),
            ),
            child: Column(
              children: _workSchedules.map((schedule) {
                final isSelected = _selectedWorkSchedule == schedule;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedWorkSchedule = schedule;
                    _dropdownOpen = false;
                  }),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected ? _cyan47.withValues(alpha: 0.1) : Colors.transparent,
                      border: schedule != _workSchedules.last
                          ? const Border(bottom: BorderSide(color: _azure27, width: 0.5))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          schedule,
                          style: TextStyle(
                            color: isSelected ? _cyan47 : _grey98,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded, color: _cyan47, size: 16),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState: _dropdownOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  // ── 5. Special Notes Section ──
  Widget _buildSpecialNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special notes',
          style: TextStyle(
            color: _azure65,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 5,
          style: const TextStyle(
            color: _grey98,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'Add any special requirements or notes for the caregiver...',
            hintStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
            filled: true,
            fillColor: _azure17,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _azure27),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _azure27),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _cyan47, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sticky bottom button ──
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
          color: _cyan47,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              // Navigate to schedule-care passing arguments to enable advanced match flow
              Navigator.pushNamed(
                context,
                '/schedule-care',
                arguments: {
                  'schedule': _selectedWorkSchedule,
                  'isAdvanced': true,
                },
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Continue to schedule',
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

class _StepInfo {
  final String number;
  final String label;
  final bool active;
  const _StepInfo(this.number, this.label, this.active);
}
