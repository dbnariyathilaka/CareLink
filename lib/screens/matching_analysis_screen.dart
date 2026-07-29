import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Matching Analysis Screen  (Advanced Match — loading screen after Confirm)
//  Figma node: 331-754
//  Auto-advances to /advanced-match-results after the staged steps complete.
// ─────────────────────────────────────────────────────────────────────────────
class MatchingAnalysisScreen extends StatefulWidget {
  const MatchingAnalysisScreen({super.key});

  @override
  State<MatchingAnalysisScreen> createState() => _MatchingAnalysisScreenState();
}

class _MatchingAnalysisScreenState extends State<MatchingAnalysisScreen> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color heroCardBg = Color(0xFFFFFADC);
  static const Color titleBrown = Color(0xFF63553D);
  static const Color subtitleBrown = Color.fromRGBO(99, 85, 61, 0.94);
  static const Color stepDoneFill = Color(0xFFC79A7F);
  static const Color stepDoneStroke = Color(0xFF4D2409);
  static const Color stepDoneCheck = Color(0xFF4F260C);
  static const Color stepPendingFill = Color.fromRGBO(157, 120, 99, 0.25);
  static const Color stepDoneLabel = Color(0xFF280F00);
  static const Color stepActiveLabel = Color(0xFFB4633D);
  static const Color stepPendingLabel = Color.fromRGBO(40, 15, 0, 0.6);
  static const Color banner1Bg = Color(0xFF313131);
  static const Color banner1Border = Color(0xFF334155);
  static const Color banner1Text = Color(0xFFDFD0BF);
  static const Color banner2Bg = Color.fromRGBO(49, 49, 49, 0.17);
  static const Color banner2Border = Color(0xFF313131);

  // ── Steps ──────────────────────────────────────────────────────────────────
  static const _steps = [
    'Reviewing care type & schedule',
    'Checking location & distance',
    'Matching qualifications…',
    'Ranking your top 5',
    'Preparing your results',
  ];

  int _completedSteps = 0; // how many have ticked done
  int _activeStep = 0; // 0-based currently animating step
  bool _done = false;

  Map<String, dynamic> _bookingArgs = {};

  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _scheduleSteps();
  }

  void _scheduleSteps() {
    // after 0.5 s → step 0 done, step 1 active
    // after 1.9 s → step 1 done, step 2 active
    // after 3.3 s → step 2 done, step 3 active
    // after 4.7 s → step 3 done, step 4 active
    // after 5.8 s → all done → navigate
    final delays = [500, 1900, 3300, 4700, 5800];

    for (int i = 0; i < delays.length; i++) {
      final t = Timer(Duration(milliseconds: delays[i]), () {
        if (!mounted) return;
        setState(() {
          if (i < _steps.length - 1) {
            _completedSteps = i + 1;
            _activeStep = i + 1;
          } else {
            _completedSteps = _steps.length;
            _activeStep = _steps.length;
            _done = true;
          }
        });
        if (i == delays.length - 1) {
          _navigateToResults();
        }
      });
      _timers.add(t);
    }
  }

  void _navigateToResults() {
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      AppState.hasActiveMatch.value = true;
      AppState.lastMatchArgs = _bookingArgs;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/advanced-match-results',
        (route) => route.settings.name == '/patient-dashboard',
        arguments: _bookingArgs,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _bookingArgs = Map<String, dynamic>.from(args);
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 28),
              _buildStepList(),
              const SizedBox(height: 20),
              _buildInfoBanner(
                icon: Icons.shield_rounded,
                text:
                    'We only show caregivers who are verified and background-checked.',
                iconSize: 30,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                bg: banner1Bg,
                border: banner1Border,
                textColor: banner1Text,
                iconColor: banner1Text,
                padding: const EdgeInsets.all(21),
                radius: 14,
              ),
              const SizedBox(height: 12),
              _buildInfoBanner(
                icon: Icons.bolt_rounded,
                text: 'Hang tight — this usually takes just a few seconds.',
                iconSize: 22,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                bg: banner2Bg,
                border: banner2Border,
                textColor: banner2Border,
                iconColor: banner2Border,
                padding: const EdgeInsets.all(15),
                radius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero card: title, subtitle, GIF ─────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        color: heroCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Column(
        children: [
          const Text(
            'Analyzing your details…',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: titleBrown,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Almost done! we're ranking caregivers who best match what you need.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: subtitleBrown,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Image.asset(
            'assets/images/loading_screen.gif',
            width: 220,
            height: 220,
          ),
        ],
      ),
    );
  }

  // ── Step list ────────────────────────────────────────────────────────────
  Widget _buildStepList() {
    return Column(
      children: List.generate(_steps.length, (i) {
        final isDone = i < _completedSteps;
        final isActive = i == _activeStep && !isDone && !_done;
        return _buildStepRow(_steps[i], isDone: isDone, isActive: isActive, index: i);
      }),
    );
  }

  Widget _buildStepRow(
    String label, {
    required bool isDone,
    required bool isActive,
    required int index,
  }) {
    final isLastStep = index == _steps.length - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? stepDoneFill
                        : (isActive ? Colors.transparent : stepPendingFill),
                    border: Border.all(
                      color: isDone || isActive
                          ? stepDoneStroke
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: stepDoneCheck, size: 16)
                      : null,
                ),
                if (!isLastStep)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isDone ? stepDoneFill : stepPendingFill,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 3,
                bottom: isLastStep ? 0 : 14,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: isDone
                      ? stepDoneLabel
                      : (isActive ? stepActiveLabel : stepPendingLabel),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required String text,
    required double iconSize,
    required double fontSize,
    required FontWeight fontWeight,
    required Color bg,
    required Color border,
    required Color textColor,
    required Color iconColor,
    required EdgeInsets padding,
    required double radius,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: fontWeight == FontWeight.w600 ? 'Inter' : 'Open Sans',
                color: textColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
