import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Patient details — care needs (self) — "Step 2 of 2" of the
//  patient onboarding flow. Mounted at route '/patient-onboarding-2'.
//  Figma node: 123-474
// ─────────────────────────────────────────────────────────────
class PatientOnboarding1Screen extends StatefulWidget {
  const PatientOnboarding1Screen({super.key});

  @override
  State<PatientOnboarding1Screen> createState() =>
      _PatientOnboarding1ScreenState();
}

class _PatientOnboarding1ScreenState extends State<PatientOnboarding1Screen>
    with SingleTickerProviderStateMixin {
  static const Color bgCream = Color(0xFFF5E8DE);
  static const Color titleGreen = Color(0xFF033724);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color chipGreen = Color(0xFF033724);
  static const Color levelGreen = Color(0xFF0F3D2E);
  static const Color progressActive = Color(0xFF1E8370);
  static const Color progressInactive = Color(0xFFD9D9D9);
  static const Color creamButtonText = Color(0xFFF6F0E2);

  // ── Options ── (single-select: exactly one care type may be chosen)
  final List<String> _careTypes = [
    'Elder care',
    'Pediatric',
    'Post-surgery',
    'Physical disability',
    'Mental health',
    'Dementia',
    'Mobility assistance',
    'Medication management',
    'Wound care',
    'Rehabilitation',
    'Physiotherapy',
  ];

  String _selectedCareType = 'Elder care';

  final List<String> _careLevels = [
    'Full-time',
    'Part-time',
    'Live-in',
    'Flexible',
  ];
  String _selectedCareLevel = 'Full-time';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
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
      backgroundColor: bgCream,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: titleGreen, size: 22),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Patient details',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: titleGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Progress bar — step 2 of 2
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: const [
                    Expanded(
                      child: _ProgressSegment(color: progressInactive),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: _ProgressSegment(color: progressActive),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(23, 0, 23, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Care type (single-select)
                      const Text(
                        'What kind of care is needed?',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: titleGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Care type chips - wrap layout, exactly one selectable
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _careTypes.map((type) {
                          final isSelected = _selectedCareType == type;
                          return _buildChip(
                            label: type,
                            isSelected: isSelected,
                            onTap: () {
                              // Single-select: replaces any previous choice.
                              setState(() => _selectedCareType = type);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 34),

                      // Section 2: Care level (single-select grid)
                      const Text(
                        'How much care is needed?',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: levelGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _careLevels.length,
                        itemBuilder: (context, index) {
                          final level = _careLevels[index];
                          final isSelected = _selectedCareLevel == level;
                          return _buildLevelChip(
                            label: level,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => _selectedCareLevel = level);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Continue button pinned at bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(23, 0, 23, 24),
                child: Container(
                  width: double.infinity,
                  height: 59,
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
                        AppState.careType.value = _selectedCareType;
                        AppState.careSchedule.value = _selectedCareLevel;
                        Navigator.pushNamed(context, '/patient-onboarding-3');
                      },
                      child: const Center(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chip for care type selection (wrap layout) — single-select.
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
          color: isSelected ? chipGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: chipGreen, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: isSelected ? Colors.white : chipGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Chip for care level selection (grid cell) — single-select.
  Widget _buildLevelChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? levelGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: levelGreen, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: isSelected ? Colors.white : levelGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final Color color;
  const _ProgressSegment({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
