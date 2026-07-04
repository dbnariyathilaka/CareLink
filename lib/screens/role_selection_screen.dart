import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/progress_bar.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'patient';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProgressBar(currentStep: 0, totalSteps: 3),
            const SizedBox(height: 24),

            // Heading
            const Text(
              'Who are you registering as?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This determines your app experience',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            // Role cards
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    title: 'Patient',
                    subtitle: 'I need a caregiver',
                    icon: Icons.person_outline_rounded,
                    isSelected: _selectedRole == 'patient',
                    onTap: () {
                      setState(() => _selectedRole = 'patient');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RoleCard(
                    title: 'Caregiver',
                    subtitle: 'I provide care',
                    icon: Icons.medical_services_outlined,
                    isSelected: _selectedRole == 'caregiver',
                    iconColor: Colors.purpleAccent,
                    onTap: () {
                      setState(() => _selectedRole = 'caregiver');
                    },
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Continue button
            CustomButton(
              text: 'Continue as $_selectedRole',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/account-details',
                  arguments: _selectedRole,
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color? iconColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                    : AppTheme.borderColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppTheme.primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
