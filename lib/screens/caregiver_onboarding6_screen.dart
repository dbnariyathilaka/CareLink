import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 6 of 6
//  Figma node: 436-570 · "Terms & conditions"
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding6Screen extends StatefulWidget {
  const CaregiverOnboarding6Screen({super.key});

  @override
  State<CaregiverOnboarding6Screen> createState() =>
      _CaregiverOnboarding6ScreenState();
}

class _CaregiverOnboarding6ScreenState
    extends State<CaregiverOnboarding6Screen> {
  static const Color bg = Color(0xFFF1F8E1);
  static const Color titleDark = Color(0xFF113341);
  static const Color stepLabel = Color(0xFF94A3B8);
  static const Color progressActive = Color(0xFF345058);
  static const Color progressInactive = Color.fromRGBO(137, 171, 199, 0.37);
  static const Color termsBoxBg = Color(0xFF55463A);
  static const Color termsHeading = Color(0xFFFBBC05);
  static const Color termsBody = Color(0xFFCBD5E1);
  static const Color continueBg = Color(0xFF223A5C);

  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  void _continue() {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions to continue.'),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/caregiver-registration-success');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Top row: back arrow + step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: titleDark,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                  const Text(
                    'Step 6 of 6',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: stepLabel,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildProgressBar(currentStep: 6, totalSteps: 6),

              const SizedBox(height: 24),

              const Text(
                'Terms & conditions',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleDark,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please review before going live',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: stepLabel,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: termsBoxBg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTermSection(
                          '1. Caregiver conduct',
                          'You agree to provide care services professionally, '
                              'respectfully, and in accordance with the care '
                              'plans agreed with patients and families.',
                        ),
                        _buildTermSection(
                          '2. Background verification',
                          'CareLink may verify your identity, certifications, '
                              'and background check status before activating '
                              'your profile.',
                        ),
                        _buildTermSection(
                          '3. Payments & cancellations',
                          'Bookings, cancellations, and payouts are processed '
                              'through CareLink per the published fee schedule.',
                        ),
                        _buildTermSection(
                          '4. Data & privacy',
                          'Your profile information is shared with patients '
                              'only as needed to facilitate care requests, per '
                              'our Privacy Policy.',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: titleDark, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _agreed
                          ? const Icon(
                              Icons.check_rounded,
                              color: titleDark,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'I agree to the Terms & Conditions and Privacy Policy',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: titleDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: continueBg,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _continue,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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

  Widget _buildTermSection(String title, String body, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: termsHeading,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: termsBody,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Progress bar with segmented steps
  Widget _buildProgressBar({
    required int currentStep,
    required int totalSteps,
  }) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? progressActive : progressInactive,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
