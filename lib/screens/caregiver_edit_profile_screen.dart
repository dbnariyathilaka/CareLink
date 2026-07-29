import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/storage_service.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/upload_picker_sheet.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Edit Profile Screen
//  Figma node: 498-7932 · P-27b · Edit Profile (Caregiver)
//  Reached from the "Edit profile" pencil icon on My Profile.
// ─────────────────────────────────────────────────────────────
class CaregiverEditProfileScreen extends StatefulWidget {
  const CaregiverEditProfileScreen({super.key});

  @override
  State<CaregiverEditProfileScreen> createState() =>
      _CaregiverEditProfileScreenState();
}

class _CaregiverEditProfileScreenState
    extends State<CaregiverEditProfileScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);
  static const Color _geyser = Color(0xFFCBD5E1);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [
    TextEditingController(),
  ];
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  int _yearsExperience = 0;
  int _radiusKm = 10;

  static const List<String> _skills = [
    'Mobility assistance',
    'Medication management',
    'Dementia care',
    'Wound care',
    'Rehabilitation',
    'Physiotherapy',
    'Mental health support',
    'Sign language',
    'Pediatric care',
  ];
  final Set<String> _selectedSkills = {};

  static const List<String> _languages = ['Sinhala', 'English', 'Tamil'];
  final Set<String> _selectedLanguages = {};

  final List<String> _certificateLabels = [];
  final List<String> _certificateUrls = [];
  bool _addingCertificate = false;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = AuthService.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final profile = await CaregiverService.getCaregiverProfile(user.uid);
    if (!mounted) return;
    AppState.hydrateCaregiverPhoto(profile?['photoUrl'] as String?);
    _nameController.text = (profile?['name'] as String?) ?? '';
    _emailController.text = (profile?['email'] as String?) ?? user.email ?? '';
    _cityController.text = (profile?['city'] as String?) ?? '';
    _bioController.text = (profile?['bio'] as String?) ?? '';
    final certUrls = (profile?['certificateUrls'] as List?)?.cast<String>() ?? const [];
    setState(() {
      _yearsExperience = profile?['yearsExperience'] as int? ?? 0;
      _radiusKm = profile?['serviceRadiusKm'] as int? ?? 10;
      _selectedSkills
        ..clear()
        ..addAll((profile?['skills'] as List?)?.cast<String>() ?? const []);
      _selectedLanguages
        ..clear()
        ..addAll((profile?['languagesSpoken'] as List?)?.cast<String>() ?? const []);
      _certificateUrls
        ..clear()
        ..addAll(certUrls);
      _certificateLabels
        ..clear()
        ..addAll(List.generate(certUrls.length, (i) => 'Certificate ${i + 1}'));
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await CaregiverService.saveCaregiverProfile(
        uid: user.uid,
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'city': _cityController.text.trim(),
          'bio': _bioController.text.trim(),
          'yearsExperience': _yearsExperience,
          'serviceRadiusKm': _radiusKm,
          'skills': _selectedSkills.toList(),
          'languagesSpoken': _selectedLanguages.toList(),
        },
      );
      await AuthService.saveUserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save changes. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    for (final c in _phoneControllers) {
      c.dispose();
    }
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picked = await pickImageOrDocument(context, allowPdf: false);
    if (picked == null || !mounted) return;

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    try {
      final url = await StorageService.uploadBytes(
        storagePath: StorageService.profilePhotoPath(uid, picked.name),
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      if (!mounted) return;
      AppState.caregiverProfileImagePath.value = url;
      await CaregiverService.saveCaregiverProfile(uid: uid, data: {'photoUrl': url});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload photo. Please try again.')),
      );
    }
  }

  Future<void> _addCertificate() async {
    final picked = await pickImageOrDocument(context);
    if (picked == null || !mounted) return;

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _addingCertificate = true);
    try {
      final url = await StorageService.uploadBytes(
        storagePath: StorageService.certificatePath(uid, picked.name),
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      await CaregiverService.saveCaregiverProfile(
        uid: uid,
        data: {'certificateUrls': FieldValue.arrayUnion([url])},
      );
      if (!mounted) return;
      setState(() {
        _certificateUrls.add(url);
        _certificateLabels.add(picked.name);
        _addingCertificate = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _addingCertificate = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload certificate. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Edit profile',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildAvatarPicker()),
                    const SizedBox(height: 24),

                    _buildLabel('Full name'),
                    const SizedBox(height: 8),
                    _buildTextField(_nameController),
                    const SizedBox(height: 18),

                    _buildLabel('Email address'),
                    const SizedBox(height: 8),
                    _buildTextField(_emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 18),

                    _buildLabel('Phone numbers'),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        for (int i = 0; i < _phoneControllers.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _buildTextField(_phoneControllers[i], keyboardType: TextInputType.phone),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => setState(() => _phoneControllers.add(TextEditingController())),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_rounded, color: _indigoLight, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Add another phone number',
                            style: TextStyle(color: _indigoLight, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Years of experience'),
                    const SizedBox(height: 8),
                    _buildStepperRow(
                      value: '$_yearsExperience ${_yearsExperience == 1 ? 'year' : 'years'}',
                      onDecrement: () {
                        if (_yearsExperience > 0) setState(() => _yearsExperience--);
                      },
                      onIncrement: () => setState(() => _yearsExperience++),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('City / area'),
                    const SizedBox(height: 8),
                    _buildTextField(_cityController),
                    const SizedBox(height: 20),

                    _buildLabel('Service radius'),
                    const SizedBox(height: 8),
                    _buildStepperRow(
                      value: '$_radiusKm km',
                      onDecrement: () {
                        if (_radiusKm > 5) setState(() => _radiusKm -= 5);
                      },
                      onIncrement: () => setState(() => _radiusKm += 5),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Skills'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _skills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return _buildCheckChip(
                          label: skill,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedSkills.remove(skill);
                              } else {
                                _selectedSkills.add(skill);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Languages spoken'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _languages.map((lang) {
                        final isSelected = _selectedLanguages.contains(lang);
                        return _buildCheckChip(
                          label: lang,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedLanguages.remove(lang);
                              } else {
                                _selectedLanguages.add(lang);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Short bio'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBackground,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _bioController,
                        maxLines: 4,
                        minLines: 3,
                        style: const TextStyle(
                          color: _geyser,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Certificates'),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        for (int i = 0; i < _certificateLabels.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _buildCertRow(_certificateLabels[i]),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _addingCertificate ? null : _addCertificate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _addingCertificate
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: _indigoLight, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Uploading...',
                                    style: TextStyle(color: _indigoLight, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file_rounded, color: _indigoLight, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add certificate',
                                    style: TextStyle(color: _indigoLight, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: _indigo,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _saving ? null : _saveProfile,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Save changes',
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
          ],
        ),
      ),
    );
  }

  String _initials() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  Widget _buildAvatarPicker() {
    return ValueListenableBuilder<String?>(
      valueListenable: AppState.caregiverProfileImagePath,
      builder: (context, imagePath, _) {
        return GestureDetector(
          onTap: _pickProfileImage,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: imagePath == null
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_indigo, Color(0xFF4F46E5)],
                        )
                      : null,
                ),
                child: imagePath != null
                    ? ClipOval(
                        child: RemoteOrLocalImage(source: imagePath, width: 90, height: 90),
                      )
                    : Center(
                        child: Text(
                          _initials(),
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _indigo,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surfaceColor, width: 3),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildStepperRow({
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w400),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: const Icon(Icons.remove_rounded, color: AppTheme.textSecondary, size: 22),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onIncrement,
                child: const Icon(Icons.add_rounded, color: _indigo, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _indigo.withValues(alpha: 0.15) : AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? _indigo : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: _indigoLight, size: 15),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _indigoLight : _geyser,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertRow(String filename) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: _indigo, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              filename,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _geyser, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
