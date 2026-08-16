import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/upload_picker_sheet.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 4 of 6
//  Figma node: 434-426 · "Profile photo"
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding4Screen extends StatefulWidget {
  const CaregiverOnboarding4Screen({super.key});

  @override
  State<CaregiverOnboarding4Screen> createState() =>
      _CaregiverOnboarding4ScreenState();
}

class _CaregiverOnboarding4ScreenState
    extends State<CaregiverOnboarding4Screen> {
  static const Color bg = Color(0xFFF1F8E1);
  static const Color titleDark = Color(0xFF112541);
  static const Color stepLabel = Color(0xFF94A3B8);
  static const Color progressActive = Color(0xFF345058);
  static const Color progressInactive = Color.fromRGBO(137, 171, 199, 0.37);
  static const Color avatarBg = Color(0xFFE6E9D2);
  static const Color avatarBorder = Color(0xFFAFAB94);
  static const Color avatarIcon = Color(0xFF212D3F);
  static const Color cameraBadgeBg = Color(0xFF1E293B);
  static const Color cameraBadgeBorder = Color(0xFF0F172A);
  static const Color optionButtonBg = Color.fromRGBO(19, 65, 61, 0.89);
  static const Color optionIcon = Color(0xFFFBBC05);
  static const Color continueBg = Color(0xFF223A5C);

  Uint8List? _photoPreview;
  bool _uploading = false;

  Future<void> _pickFromCamera() async {
    final picked = await pickFromCamera();
    if (picked == null || !mounted) return;
    await _processPickedPhoto(picked);
  }

  Future<void> _pickFromGallery() async {
    final picked = await pickFromGallery();
    if (picked == null || !mounted) return;
    await _processPickedPhoto(picked);
  }

  Future<void> _processPickedPhoto(PickedUpload picked) async {
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
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: titleDark, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text(
                    'Step 4 of 6',
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

              _buildProgressBar(currentStep: 4, totalSteps: 6),

              const SizedBox(height: 24),

              const Text(
                'Profile photo',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A clear photo helps patients recognise and trust you',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: stepLabel,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  height: 1.4,
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _uploading ? null : _pickFromGallery,
                        child: Stack(
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: avatarBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: avatarBorder,
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
                                      color: avatarIcon,
                                      size: 56,
                                    ),
                            ),
                            if (_uploading)
                              const Positioned.fill(
                                child: Center(
                                  child: CircularProgressIndicator(color: continueBg),
                                ),
                              ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: cameraBadgeBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cameraBadgeBorder, width: 2),
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
                          onTap: _uploading ? null : _pickFromCamera,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _buildOptionButton(
                          icon: Icons.image_rounded,
                          label: 'Upload from gallery',
                          onTap: _uploading ? null : _pickFromGallery,
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
                    color: continueBg,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _uploading
                          ? null
                          : () {
                              if (_photoPreview == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please upload a profile photo before continuing.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                              Navigator.pushNamed(context, '/caregiver-onboarding-5');
                            },
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
              color: isActive ? progressActive : progressInactive,
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
      color: optionButtonBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: optionIcon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color(0xFFF8FAFC),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
