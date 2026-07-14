import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Qualifications Intro Screen  (Advanced Match — Step 4 transition)
//  Figma: P-10e-intro · Qualifications (v2) — Transition intro  node 282-13106
// ─────────────────────────────────────────────────────────────────────────────
class QualificationsIntroScreen extends StatefulWidget {
  const QualificationsIntroScreen({super.key});

  @override
  State<QualificationsIntroScreen> createState() =>
      _QualificationsIntroScreenState();
}

class _QualificationsIntroScreenState extends State<QualificationsIntroScreen>
    with TickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _keppel    = Color(0xFF3DB498); // Keppel Cyan
  static const Color _bottleGreen = Color(0xFF06291F);
  static const Color _azure11   = Color(0xFF0F172A); // surface
  static const Color _azure17   = Color(0xFF1E293B); // card
  static const Color _azure27   = Color(0xFF334155); // border
  static const Color _azure65   = Color(0xFF94A3B8); // text secondary
  static const Color _grey98    = Color(0xFFF8FAFC); // text primary
  static const Color _tealTop   = Color(0xFF1A7A6E); // hero gradient top
  static const Color _tealMid   = Color(0xFF0F4F46); // hero gradient mid

  // ── State ──────────────────────────────────────────────────────────────────
  Map<String, dynamic> _bookingArgs = {};

  // Pulse animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Float animation for icons
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
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
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Column(
        children: [
          // ── Hero (top teal section) ──────────────────────────────────────
          Expanded(
            flex: 42,
            child: _buildHeroSection(),
          ),

          // ── Content (bottom dark section) ────────────────────────────────
          Expanded(
            flex: 58,
            child: _buildContentSection(context),
          ),
        ],
      ),
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Back button top-left
            Positioned(
              top: 8,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
              ),
            ),

            // Step indicator (5 bubbles)
            Positioned(
              top: 44,
              left: 16,
              right: 16,
              child: _buildStepIndicator(),
            ),

            // Pulsing glow rings behind central icon
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (ctx, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _keppel.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _keppel.withValues(alpha: 0.18),
              ),
            ),

            // Central shield-check icon
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _keppel.withValues(alpha: 0.30),
                border: Border.all(color: _keppel.withValues(alpha: 0.5), width: 1.5),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: _grey98,
                size: 32,
              ),
            ),

            // Floating graduation cap icon (top-right of center)
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (ctx, child) => Transform.translate(
                offset: Offset(62, -38 + _floatAnim.value * 0.5),
                child: _buildFloatingIcon(Icons.school_rounded, 36),
              ),
            ),

            // Floating translate/language icon (bottom-left of center)
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (ctx2, child) => Transform.translate(
                offset: Offset(-70, 38 - _floatAnim.value * 0.5),
                child: _buildFloatingIcon(Icons.translate_rounded, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, double size) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _keppel.withValues(alpha: 0.20),
        border: Border.all(color: _keppel.withValues(alpha: 0.40), width: 1.2),
      ),
      child: Icon(icon, color: _grey98, size: size * 0.58),
    );
  }

  // ── Step Indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    const steps = [
      _StepData('1', 'Request',        _StepState.done),
      _StepData('2', 'Schedule',       _StepState.done),
      _StepData('3', 'Location',       _StepState.done),
      _StepData('4', 'Qualifications', _StepState.active),
      _StepData('5', 'Confirm',        _StepState.inactive),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 1.5,
              color: i < 6 ? _keppel : _azure27,
            ),
          );
        }
        final s = steps[i ~/ 2];
        final isActive = s.state == _StepState.active;
        final isDone   = s.state == _StepState.done;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? _keppel : _tealMid,
                border: Border.all(
                  color: isActive || isDone ? _keppel : _azure27,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  s.number,
                  style: TextStyle(
                    color: isActive
                        ? _bottleGreen
                        : (isDone ? _keppel : _azure65),
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
                color: isActive || isDone ? _keppel : _azure65.withValues(alpha: 0.8),
                fontSize: 7.5,
                fontWeight:
                    isActive || isDone ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Content Section ───────────────────────────────────────────────────────
  Widget _buildContentSection(BuildContext context) {
    return Container(
      color: _azure11,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          const Text(
            "Now, let's set caregiver\nqualifications",
            style: TextStyle(
              color: _grey98,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          const Text(
            'Tell us the education, experience and skills your ideal caregiver should have.',
            style: TextStyle(
              color: _azure65,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Category cards row
          Row(
            children: [
              _buildCategoryCard(Icons.school_rounded, 'Education'),
              const SizedBox(width: 12),
              _buildCategoryCard(Icons.work_history_rounded, 'Experience'),
              const SizedBox(width: 12),
              _buildCategoryCard(Icons.translate_rounded, 'Languages'),
            ],
          ),

          const Spacer(),

          // Continue button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Material(
                color: _keppel,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/qualifications-selection',
                      arguments: _bookingArgs,
                    );
                  },
                  child: const SizedBox(
                    height: 54,
                    child: Center(
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: _bottleGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _azure27),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _keppel, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: _grey98,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
enum _StepState { done, active, inactive }

class _StepData {
  final String number;
  final String label;
  final _StepState state;
  const _StepData(this.number, this.label, this.state);
}
