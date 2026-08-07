import 'package:flutter/material.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Advanced Match — Send Request (Step 1 of 5)
//  Figma node: 296-6914
// ─────────────────────────────────────────────────────────────
class AdvancedMatchSendRequestScreen extends StatefulWidget {
  const AdvancedMatchSendRequestScreen({super.key});

  @override
  State<AdvancedMatchSendRequestScreen> createState() => _AdvancedMatchSendRequestScreenState();
}

class _AdvancedMatchSendRequestScreenState extends State<AdvancedMatchSendRequestScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color titleText = Color(0xFF313131);
  static const Color accent = Color(0xFF6D4275);
  static const Color stepInactiveBg = Color(0xFFD1BAC6);
  static const Color stepLineInactive = Color(0xFFD1BAC6);
  static const Color titleGreen = Color(0xFF033724);

  static const Color cardBg = Color(0xFF313131);
  static const Color cardBorder = Color(0xFF334155);
  static const Color cardText = Color(0xFFFEFFE6);
  static const Color amberIcon = Color(0xFFFBBC05);

  static const Color fieldBorder = Color(0xFF334155);
  static const Color fieldValue = Color(0xFF313131);
  static const Color fieldLabel = Color.fromRGBO(0, 0, 0, 0.63);

  static const Color notesFieldBg = Color.fromRGBO(49, 49, 49, 0.41);
  static const Color notesText = Color.fromRGBO(49, 49, 49, 0.85);

  static const Color creamButtonText = Color(0xFFF6F0E2);

  // Dropdown Options
  static const List<String> _workSchedules = [
    'Flexible',
    'Full-time',
    'Part-time',
    'Live-in',
  ];
  String _selectedWorkSchedule = 'Flexible';
  bool _dropdownOpen = false;

  final TextEditingController _notesController = NoUnderlineTextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
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
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 110),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: titleText, size: 22),
          ),
          const SizedBox(width: 16),
          const Text(
            'Send Request',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: titleText,
              fontSize: 24,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Every connector stays the same neutral tone — only the step
            // circles themselves indicate progress, matching Figma exactly.
            return Expanded(
              child: Padding(
                // Centers the line on the 35px step circle above the label.
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 3,
                  decoration: BoxDecoration(
                    color: stepLineInactive,
                    borderRadius: BorderRadius.circular(4),
                  ),
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
    return Column(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.active ? accent : stepInactiveBg,
          ),
          child: Center(
            child: Text(
              s.number,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: s.active ? Colors.white : Colors.black,
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

  // ── 3. Three reassurance info cards (kept on the dark panel treatment) ──
  Widget _buildBenefitsCardList() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.verified_user_outlined,
          iconColor: const Color(0xFFFFA722),
          text: 'Your request goes only to caregivers who meet the qualifications you selected.',
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          icon: Icons.bolt_outlined,
          iconColor: amberIcon,
          text: 'Most matching caregivers respond within 6 hours of a request.',
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          icon: Icons.lock_outline_rounded,
          iconColor: amberIcon,
          text: 'Your contact details stay private until you confirm a booking.',
        ),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required Color iconColor, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: cardText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Work schedule dropdown ──
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
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(10),
                topRight: const Radius.circular(10),
                bottomLeft: Radius.circular(_dropdownOpen ? 0 : 10),
                bottomRight: Radius.circular(_dropdownOpen ? 0 : 10),
              ),
              border: Border.all(
                color: _dropdownOpen ? accent : fieldBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedWorkSchedule,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: fieldValue,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AnimatedRotation(
                  turns: _dropdownOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: fieldValue.withValues(alpha: 0.72),
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
              color: bgCream,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border(
                left: BorderSide(color: accent, width: 1),
                right: BorderSide(color: accent, width: 1),
                bottom: BorderSide(color: accent, width: 1),
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
                      color: isSelected ? accent.withValues(alpha: 0.1) : Colors.transparent,
                      border: schedule != _workSchedules.last
                          ? Border(bottom: BorderSide(color: fieldBorder.withValues(alpha: 0.3), width: 0.5))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          schedule,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: isSelected ? accent : Colors.black,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded, color: accent, size: 16),
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

  // ── 5. Special notes textarea ──
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
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: notesFieldBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 5,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: fieldValue,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Add any special requirements or notes for the caregiver...',
              hintStyle: const TextStyle(
                fontFamily: 'Open Sans',
                color: notesText,
                fontSize: 14,
              ),
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
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
            color: accent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 2, offset: const Offset(2, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                // Navigate to schedule-care passing arguments to enable advanced match flow
                Navigator.pushNamed(
                  context,
                  '/schedule-care',
                  arguments: {
                    'schedule': _selectedWorkSchedule,
                    'isAdvanced': true,
                    'notes': _notesController.text.trim(),
                  },
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Continue to schedule',
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

class _StepInfo {
  final String number;
  final String label;
  final bool active;
  const _StepInfo(this.number, this.label, this.active);
}
