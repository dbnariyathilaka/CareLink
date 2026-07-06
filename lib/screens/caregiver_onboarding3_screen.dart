import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CaregiverOnboarding3Screen extends StatefulWidget {
  const CaregiverOnboarding3Screen({super.key});

  @override
  State<CaregiverOnboarding3Screen> createState() =>
      _CaregiverOnboarding3ScreenState();
}

class _DayAvailability {
  bool available;
  String hours;

  _DayAvailability({required this.available, required this.hours});
}

class _CaregiverOnboarding3ScreenState
    extends State<CaregiverOnboarding3Screen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);

  final Map<String, _DayAvailability> _days = {
    'Mon': _DayAvailability(available: true, hours: '8 AM – 6 PM'),
    'Tue': _DayAvailability(available: true, hours: '8 AM – 6 PM'),
    'Wed': _DayAvailability(available: true, hours: '8 AM – 6 PM'),
    'Thu': _DayAvailability(available: true, hours: '8 AM – 6 PM'),
    'Fri': _DayAvailability(available: true, hours: '8 AM – 6 PM'),
    'Sat': _DayAvailability(available: false, hours: '8 AM – 6 PM'),
    'Sun': _DayAvailability(available: false, hours: '8 AM – 6 PM'),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
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
                      Icons.arrow_back,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text(
                    'Step 3 of 5',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildProgressBar(currentStep: 3, totalSteps: 5),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly availability',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        'Tap a day to add or edit hours',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Column(
                        children: _days.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _buildDayRow(entry.key, entry.value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: _indigo,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.pushNamed(context, '/caregiver-onboarding-4');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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

  /// Progress bar with segmented steps
  Widget _buildProgressBar({required int currentStep, required int totalSteps}) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? _indigo : AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  /// A single day row — tap to toggle availability on/off
  Widget _buildDayRow(String day, _DayAvailability data) {
    final available = data.available;
    return GestureDetector(
      onTap: () => setState(() => data.available = !data.available),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: available ? _indigo : AppTheme.borderColor,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                day,
                style: TextStyle(
                  color: available ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                available ? data.hours : 'Unavailable',
                style: TextStyle(
                  color: available ? _indigoLight : const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              available ? Icons.edit_outlined : Icons.add_rounded,
              color: available ? _indigo : const Color(0xFF64748B),
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}
