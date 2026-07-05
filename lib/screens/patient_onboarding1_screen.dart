import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PatientOnboarding1Screen extends StatefulWidget {
  const PatientOnboarding1Screen({super.key});

  @override
  State<PatientOnboarding1Screen> createState() =>
      _PatientOnboarding1ScreenState();
}

class _PatientOnboarding1ScreenState extends State<PatientOnboarding1Screen>
    with SingleTickerProviderStateMixin {
  // Care type options - single-select
  final List<String> _careTypes = [
    'Elder care',
    'Pediatric',
    'Post-surgery',
    'Physical disability',
    'Mental health',
    'Dementia',
  ];
  String _selectedCareType = 'Elder care';

  // Care level options - single-select
  final List<String> _careLevels = ['Full-time', 'Part-time', 'Live-in'];
  String _selectedCareLevel = 'Full-time';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: child,
              ),
            );
          },
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
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                    const Text(
                      'Step 1 of 4',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress bar - 4 segments
                _buildProgressBar(currentStep: 1, totalSteps: 4),

                const SizedBox(height: 24),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Care type
                        const Text(
                          'What kind of care is needed?',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Care type chips - wrap layout
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _careTypes.map((type) {
                            final isSelected = _selectedCareType == type;
                            return _buildChip(
                              label: type,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedCareType = type;
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 34),

                        // Section 2: Care level
                        const Text(
                          'How much care is needed?',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Care level chips - equal width row
                        Row(
                          children: _careLevels.map((level) {
                            final isSelected = _selectedCareLevel == level;
                            final isLast = level == _careLevels.last;
                            return Expanded(
                              child: Padding(
                                padding:
                                    EdgeInsets.only(right: isLast ? 0 : 10),
                                child: _buildLevelChip(
                                  label: level,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(
                                        () => _selectedCareLevel = level);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Continue button pinned at bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.pushNamed(
                              context, '/patient-onboarding-2');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Continue',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Progress bar with segmented steps
  Widget _buildProgressBar(
      {required int currentStep, required int totalSteps}) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color:
                  isActive ? AppTheme.primaryGreen : AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  /// Chip for care type selection (wrap layout)
  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
              : AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.primaryGreen
                : const Color(0xFFCBD5E1), // Geyser
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Chip for care level selection (equal-width row)
  Widget _buildLevelChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
              : AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.primaryGreen
                  : const Color(0xFFCBD5E1),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
