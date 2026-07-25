import 'package:flutter/material.dart';

class SendRequestScreen extends StatefulWidget {
  const SendRequestScreen({super.key});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  static const Color bgCream = Color(0xFFF5E8DE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color titleGreen = Color(0xFF033724);
  static const Color inactiveStepBg = Color(0xFFD8E4CE);
  static const Color matchBadgeBg = Color.fromRGBO(64, 64, 6, 0.3);
  static const Color matchBadgeText = Color(0xFF33440A);
  static const Color fieldBorder = Color.fromRGBO(0, 0, 0, 0.3);
  static const Color fieldLabel = Color.fromRGBO(0, 0, 0, 0.85);
  static const Color fieldValue = Color.fromRGBO(0, 0, 0, 0.5);

  // Dropdown options
  static const List<String> _workSchedules = [
    'Full-time',
    'Part-time',
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
        backgroundColor: bgCream,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildTitleRow(context),
                  const SizedBox(height: 24),
                  _buildStepIndicator(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 22, 14, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCaregiverCard(),
                          const SizedBox(height: 24),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: titleGreen, size: 22),
          ),
          const SizedBox(width: 16),
          const Text(
            'Select request',
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

  // ── 4-step progress indicator ─────────────────────────────
  Widget _buildStepIndicator() {
    const steps = [
      _StepData(number: '1', label: 'Request', active: true),
      _StepData(number: '2', label: 'Schedule', active: false),
      _StepData(number: '3', label: 'Location', active: false),
      _StepData(number: '4', label: 'Confirm', active: false),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: steps.map(_buildStepBubble).toList(),
      ),
    );
  }

  Widget _buildStepBubble(_StepData step) {
    return Column(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step.active ? darkGreen : inactiveStepBg,
          ),
          child: Center(
            child: Text(
              step.number,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: step.active ? Colors.white : Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: step.active ? darkGreen : titleGreen,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Caregiver summary card ────────────────────────────────
  Widget _buildCaregiverCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFD1C8B4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE9C368),
            ),
            child: const Center(
              child: Text(
                'RF',
                style: TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: darkGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rayan Fernando',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Elder care',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Text(
                      '7 yrs exp',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: matchBadgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '95% match',
              style: TextStyle(
                fontFamily: 'Quattrocento Sans',
                color: matchBadgeText,
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
            fontFamily: 'Open Sans',
            color: fieldLabel,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        // Custom dropdown
        GestureDetector(
          onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(_dropdownOpen ? 0 : 15),
                bottomRight: Radius.circular(_dropdownOpen ? 0 : 15),
              ),
              border: Border.all(
                color: _dropdownOpen ? darkGreen : fieldBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedWorkSchedule,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: fieldValue,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                AnimatedRotation(
                  turns: _dropdownOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.black,
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
              color: bgCream,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border(
                left: BorderSide(color: darkGreen, width: 1),
                right: BorderSide(color: darkGreen, width: 1),
                bottom: BorderSide(color: darkGreen, width: 1),
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
                              ? darkGreen.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: schedule != _workSchedules.last
                              ? Border(
                                  bottom: BorderSide(
                                      color: darkGreen.withValues(alpha: 0.15),
                                      width: 0.5))
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              schedule,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: _selectedWorkSchedule == schedule
                                    ? darkGreen
                                    : Colors.black,
                                fontSize: 14,
                                fontWeight: _selectedWorkSchedule == schedule
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (_selectedWorkSchedule == schedule)
                              const Icon(Icons.check_rounded,
                                  color: darkGreen, size: 16),
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
            fontFamily: 'Open Sans',
            color: fieldLabel,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          maxLines: 5,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: fieldValue,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText:
                'Add any special requirements or notes for the caregiver...',
            hintStyle: const TextStyle(
              fontFamily: 'Open Sans',
              color: fieldValue,
              fontSize: 12,
            ),
            filled: false,
            contentPadding: const EdgeInsets.all(20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: darkGreen, width: 1),
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
            bgCream.withValues(alpha: 0),
            bgCream,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(23, 14, 23, 24),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: darkGreen,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.5),
                blurRadius: 2,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/schedule-care',
                  arguments: _selectedWorkSchedule,
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Continue to schedule',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: Color(0xFFF6F0E2),
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

// ── Step data model ───────────────────────────────────────
class _StepData {
  final String number;
  final String label;
  final bool active;
  const _StepData(
      {required this.number, required this.label, required this.active});
}
