import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/upload_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 4 of 6
//  Figma node: 498-6626 · "Profile photo"
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding4Screen extends StatefulWidget {
  const CaregiverOnboarding4Screen({super.key});

  @override
  State<CaregiverOnboarding4Screen> createState() =>
      _CaregiverOnboarding4ScreenState();
}

class _CaregiverOnboarding4ScreenState
    extends State<CaregiverOnboarding4Screen> {
  static const Color _indigo = Color(0xFF6366F1);

  Uint8List? _photoPreview;
  bool _uploading = false;

  Future<void> _pickPhoto() async {
    final picked = await pickImageOrDocument(context, allowPdf: false);
    if (picked == null || !mounted) return;

    setState(() {
      _photoPreview = picked.bytes;
      _uploading = true;
    });

    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      setState(() => _uploading = false);
      return;
    }

    try {
      final url = await StorageService.uploadBytes(
        storagePath: StorageService.profilePhotoPath(uid, picked.name),
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      if (!mounted) return;
      AppState.caregiverOnboardingDraft.photoUrl = url;
      AppState.caregiverProfileImagePath.value = url;
      setState(() => _uploading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _photoPreview = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload photo. Please try again.')),
      );
    }
  }

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
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text(
                    'Step 4 of 6',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildProgressBar(currentStep: 4, totalSteps: 6),

              const SizedBox(height: 24),

              const Text(
                'Profile photo',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A clear photo helps patients recognise and trust you',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _uploading ? null : _pickPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.borderColor,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _photoPreview != null
                                  ? ClipOval(
                                      child: Image.memory(
                                        _photoPreview!,
                                        width: 156,
                                        height: 156,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF475569),
                                      size: 56,
                                    ),
                            ),
                            if (_uploading)
                              const Positioned.fill(
                                child: Center(
                                  child: CircularProgressIndicator(color: _indigo),
                                ),
                              ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _indigo,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.surfaceColor, width: 3),
                                ),
                                child: const Icon(
                                  Icons.photo_camera_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: _buildOptionButton(
                          icon: Icons.photo_camera_rounded,
                          label: 'Take a photo',
                          onTap: _uploading ? null : _pickPhoto,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _buildOptionButton(
                          icon: Icons.image_rounded,
                          label: 'Upload from gallery',
                          onTap: _uploading ? null : _pickPhoto,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: _indigo,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _uploading
                          ? null
                          : () {
                              Navigator.pushNamed(context, '/caregiver-onboarding-5');
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

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _indigo, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
