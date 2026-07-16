import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Matching Analysis Screen  (Advanced Match — loading/waiting)
//  Figma: P-17-loading · Analyzing Matches (v2) — waiting screen  node 282-13544
//  Auto-advances to /top-matches after the staged animation completes.
// ─────────────────────────────────────────────────────────────────────────────
class MatchingAnalysisScreen extends StatefulWidget {
  const MatchingAnalysisScreen({super.key});

  @override
  State<MatchingAnalysisScreen> createState() => _MatchingAnalysisScreenState();
}

class _MatchingAnalysisScreenState extends State<MatchingAnalysisScreen>
    with TickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _keppel      = Color(0xFF3DB498);
  static const Color _azure11     = Color(0xFF0F172A);
  static const Color _azure17     = Color(0xFF1E293B);
  static const Color _azure27     = Color(0xFF334155);
  static const Color _azure47     = Color(0xFF64748B);
  static const Color _azure65     = Color(0xFF94A3B8);
  static const Color _grey98      = Color(0xFFF8FAFC);
  static const Color _tealTop     = Color(0xFF1A7A6E);
  static const Color _tealMid     = Color(0xFF0D4F47);

  // ── Steps ──────────────────────────────────────────────────────────────────
  static const _steps = [
    'Reviewing care type & schedule',
    'Checking location & distance',
    'Matching qualifications...',
    'Ranking your top 5',
    'Preparing your results',
  ];

  int _completedSteps = 0; // how many have ticked green
  int _activeStep     = 0; // 0-based currently animating step
  bool _done          = false;

  Map<String, dynamic> _bookingArgs = {};

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _spinCtrl;    // orbit ring rotation
  late AnimationController _pulseCtrl;   // inner glow pulse
  late AnimationController _orbitCtrl;   // floating icons orbit
  late AnimationController _dotsCtrl;    // ellipsis dots

  late Animation<double> _spinAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _orbitAnim;
  late Animation<double> _dotsAnim;

  // Step timers
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();

    // Spinning orbit ring
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _spinAnim = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.linear));

    // Pulsing inner glow
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Orbiting small icons
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    _orbitAnim = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _orbitCtrl, curve: Curves.linear));

    // Animated dots
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotsAnim = Tween<double>(begin: 0, end: 3)
        .animate(CurvedAnimation(parent: _dotsCtrl, curve: Curves.linear));

    // Stage the step progression
    _scheduleSteps();
  }

  void _scheduleSteps() {
    // Each step takes ~1.4 s, step 0 already "completed" at start
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
            _activeStep     = i + 1;
          } else {
            _completedSteps = _steps.length;
            _activeStep     = _steps.length;
            _done           = true;
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
      // Mark that a match result is now active globally
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
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Column(
        children: [
          // Top teal hero
          Expanded(
            flex: 40,
            child: _buildHero(),
          ),
          // Bottom content
          Expanded(
            flex: 60,
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  // ── Hero section ───────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_tealTop, _tealMid],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing outer glow
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (ctx, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _keppel.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),

                // Spinning orbit ring
                AnimatedBuilder(
                  animation: _spinAnim,
                  builder: (ctx, child) => Transform.rotate(
                    angle: _spinAnim.value,
                    child: Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _grey98.withValues(alpha: 0.85),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Inner filled circle with icon
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (ctx, child) => Transform.scale(
                    scale: 0.97 + (_pulseAnim.value - 0.88) * 0.3,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _keppel.withValues(alpha: 0.35),
                        border: Border.all(
                          color: _keppel.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: _grey98,
                        size: 44,
                      ),
                    ),
                  ),
                ),

                // Orbiting floating icons
                AnimatedBuilder(
                  animation: _orbitAnim,
                  builder: (ctx, child) {
                    const radius = 82.0;
                    // heart icon at angle 0 + offset
                    final heartAngle = _orbitAnim.value - math.pi / 6;
                    final heartX = math.cos(heartAngle) * radius;
                    final heartY = math.sin(heartAngle) * radius;

                    // grad cap at opposite side
                    final capAngle = _orbitAnim.value + math.pi * 0.75;
                    final capX = math.cos(capAngle) * radius;
                    final capY = math.sin(capAngle) * radius;

                    return Stack(
                      children: [
                        Positioned(
                          left: 100 + heartX - 18,
                          top:  100 + heartY - 18,
                          child: _buildOrbitIcon(Icons.favorite_rounded),
                        ),
                        Positioned(
                          left: 100 + capX - 18,
                          top:  100 + capY - 18,
                          child: _buildOrbitIcon(Icons.school_rounded),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _tealMid,
        border: Border.all(color: _grey98.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Icon(icon, color: _grey98, size: 18),
    );
  }

  // ── Content section ────────────────────────────────────────────────────────
  Widget _buildContent() {
    return Container(
      color: _azure11,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _buildTitle(),
          const SizedBox(height: 14),

          // Step list
          _buildStepList(),
          const Spacer(),

          // Info banners
          _buildInfoBanner(
            icon: Icons.verified_user_outlined,
            text: 'We only show caregivers who are verified and background-checked.',
          ),
          const SizedBox(height: 8),
          _buildInfoBanner(
            icon: Icons.bolt_rounded,
            text: 'Hang tight — this usually takes just a few seconds.',
            isAccent: true,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _dotsAnim,
          builder: (ctx, child) {
            final dots = '.' * ((_dotsAnim.value.floor() % 4));
            final suffix = _done ? '' : dots;
            return Text(
              'Analyzing your details$suffix',
              style: const TextStyle(
                color: _grey98,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Almost done — we\'re ranking caregivers who best match what you need.',
          style: TextStyle(
            color: _azure65,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStepList() {
    return Column(
      children: List.generate(_steps.length, (i) {
        final isDone   = i < _completedSteps;
        final isActive = i == _activeStep && !_done && i < _completedSteps == false;
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
          // Indicator column
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Bubble
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? _keppel
                        : (isActive
                            ? _keppel.withValues(alpha: 0.15)
                            : _azure17),
                    border: Border.all(
                      color: isDone || isActive ? _keppel : _azure27,
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                      : isActive
                          ? Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _keppel,
                              ),
                            )
                          : null,
                ),
                // Connector line
                if (!isLastStep)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? _keppel : _azure27,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Label
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 4,
                bottom: isLastStep ? 0 : 10,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isDone
                      ? _grey98
                      : (isActive ? _keppel : _azure47),
                  fontSize: 14,
                  fontWeight: isDone || isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
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
    bool isAccent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _azure27),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isAccent ? _keppel : _azure65,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isAccent ? _keppel : _azure65,
                fontSize: 13,
                height: 1.45,
                fontWeight: isAccent ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
