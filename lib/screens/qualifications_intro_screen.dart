import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Qualifications Intro Screen  (Advanced Match — Step 4 transition)
//  Figma node: 296-7000
// ─────────────────────────────────────────────────────────────
class QualificationsIntroScreen extends StatefulWidget {
  const QualificationsIntroScreen({super.key});

  @override
  State<QualificationsIntroScreen> createState() =>
      _QualificationsIntroScreenState();
}

class _QualificationsIntroScreenState extends State<QualificationsIntroScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color accent = Color(0xFF6D4275);
  static const Color stepInactiveBg = Color(0xFFDCD9CF);
  static const Color stepLineInactive = Color(0xFFD1BAC6);
  static const Color titleText = Color(0xFF313131);
  static const Color bodyText = Color.fromRGBO(58, 50, 60, 0.85);
  static const Color creamButtonText = Color(0xFFF6F0E2);

  Map<String, dynamic> _bookingArgs = {};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/qualifications_hero.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: titleText,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildStepIndicator(),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildCard(context),
          ),
        ],
      ),
    );
  }

  // ── 5-step progress indicator (steps 1-4 done, step 5 pending) ──
  Widget _buildStepIndicator() {
    const steps = [
      _StepInfo('1', 'Request', true),
      _StepInfo('2', 'Schedule', true),
      _StepInfo('3', 'Location', true),
      _StepInfo('4', 'Qualifications', true),
      _StepInfo('5', 'Confirm', false),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftDone = steps[i ~/ 2].done;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 3,
                decoration: BoxDecoration(
                  color: leftDone ? accent : stepLineInactive,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }
        final s = steps[i ~/ 2];
        return Column(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.done ? accent : stepInactiveBg,
              ),
              child: Center(
                child: Text(
                  s.number,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: s.done ? Colors.white : Colors.black,
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
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Cream rounded-top card overlapping the bottom of the hero image ──
  // Sized by its own content (not a fixed fraction of screen height) so the
  // Continue button can never get clipped on shorter screens or when the
  // system nav bar eats into the safe area.
  Widget _buildCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: bgCream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Now, let's set caregiver\nqualifications",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleText,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tell us the education, experience and skills your ideal caregiver should have.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: bodyText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryItem('assets/images/qualifications_education_icon.png', 'Education'),
                  _buildCategoryItem('assets/images/qualifications_experience_icon.png', 'Experience'),
                  _buildCategoryItem('assets/images/qualifications_language_icon.png', 'Language'),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: accent,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/qualifications-selection',
                        arguments: _bookingArgs,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String assetPath, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(assetPath, width: 48, height: 48),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Step data model ───────────────────────────────────────
class _StepInfo {
  final String number;
  final String label;
  final bool done;
  const _StepInfo(this.number, this.label, this.done);
}
