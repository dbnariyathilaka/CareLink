import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SendRequestScreen extends StatefulWidget {
  const SendRequestScreen({super.key});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  static const Color _amber = Color(0xFFF59E0B);

  // Care type options
  static const List<String> _careTypes = [
    'Elder care · Full-time',
    'Elder care · Part-time',
    'Post-surgery · Full-time',
    'Post-surgery · Part-time',
    'Disability support · Full-time',
    'Disability support · Part-time',
    'General home care · Full-time',
    'General home care · Part-time',
  ];
  String _selectedCareType = 'Elder care · Full-time';
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
                          _buildCareTypeSection(),
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
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
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
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3-step progress indicator ─────────────────────────────
  Widget _buildStepIndicator() {
    const steps = [
      _StepData(number: '1', label: 'Request', active: true),
      _StepData(number: '2', label: 'Schedule', active: false),
      _StepData(number: '3', label: 'Confirm', active: false),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final leftActive = steps[i ~/ 2].active;
            return Expanded(
              child: Container(
                height: 1.5,
                color: leftActive
                    ? AppTheme.primaryGreen.withValues(alpha: 0.35)
                    : AppTheme.borderColor,
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step.active ? AppTheme.primaryGreen : AppTheme.cardColor,
            border: Border.all(
              color: step.active ? AppTheme.primaryGreen : AppTheme.borderColor,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              step.number,
              style: TextStyle(
                color:
                    step.active ? AppTheme.bottleGreen : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          step.label,
          style: TextStyle(
            color: step.active ? AppTheme.primaryGreen : AppTheme.textSecondary,
            fontSize: 10,
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
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Green gradient avatar
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22C55E), AppTheme.primaryGreenDark],
              ),
            ),
            child: const Center(
              child: Text(
                'AF',
                style: TextStyle(
                  color: AppTheme.bottleGreen,
                  fontSize: 16,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '92% match',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Care type dropdown ────────────────────────────────────
  Widget _buildCareTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Care type',
          style: TextStyle(
            color: AppTheme.textSecondary,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
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
                width: _dropdownOpen ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCareType,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AnimatedRotation(
                  turns: _dropdownOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
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
              color: AppTheme.cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border(
                left: BorderSide(
                    color: AppTheme.primaryGreen, width: 1.5),
                right: BorderSide(
                    color: AppTheme.primaryGreen, width: 1.5),
                bottom: BorderSide(
                    color: AppTheme.primaryGreen, width: 1.5),
              ),
            ),
            child: Column(
              children: _careTypes
                  .map(
                    (type) => GestureDetector(
                      onTap: () => setState(() {
                        _selectedCareType = type;
                        _dropdownOpen = false;
                      }),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: _selectedCareType == type
                              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: type != _careTypes.last
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
                              type,
                              style: TextStyle(
                                color: _selectedCareType == type
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: _selectedCareType == type
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (_selectedCareType == type)
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
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          maxLines: 6,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            height: 1.55,
          ),
          decoration: InputDecoration(
            hintText:
                'Add any special requirements or notes for the caregiver...',
            hintStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppTheme.cardColor,
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
                  color: AppTheme.primaryGreen, width: 1.5),
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
              Navigator.pushNamed(context, '/schedule-care');
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
