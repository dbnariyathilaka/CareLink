import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/storage_service.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';
import '../widgets/upload_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Edit Profile Screen (Figma node 487-604)
// ─────────────────────────────────────────────────────────────
class CaregiverEditProfileScreen extends StatefulWidget {
  const CaregiverEditProfileScreen({super.key});

  @override
  State<CaregiverEditProfileScreen> createState() =>
      _CaregiverEditProfileScreenState();
}

class _CaregiverEditProfileScreenState
    extends State<CaregiverEditProfileScreen> {
  static const Color _bg = Color(0xFFF5EEDE);
  static const Color _titleDark = Color(0xFF113341);
  static const Color _fieldLabel = Color(0xFF4F5B6C);
  static const Color _fieldBg = Color(0xFFD8D3C5);
  static const Color _fieldBorder = Color(0xFF7B7261);
  static const Color _fieldText = Color(0xFF313131);
  static const Color _stepperIcon = Color(0xFF44331C);
  static const Color _addPhoneIcon = Color(0xFF6F5620);
  static const Color _addPhoneText = Color(0xFF885F36);
  static const Color _chipSelectedBg = Color(0xFF223A5C);
  static const Color _chipSelectedText = Color(0xFFFFFFFF);
  static const Color _chipUnselectedText = Color(0xFF223A5C);
  static const Color _certBg = Color(0xFFF4D9BF);
  static const Color _certBorder = Color(0xFF443423);
  static const Color _certIcon = Color(0xFF9C7919);
  static const Color _certText = Color(0xFF44331C);
  static const Color _certDelete = Color(0xFF7A5A2E);
  static const Color _addCertIcon = Color(0xFFFBBC05);
  static const Color _saveBg = Color(0xFF1F3554);

  final _nameController = NoUnderlineTextEditingController();
  final _emailController = NoUnderlineTextEditingController();
  final List<TextEditingController> _phoneControllers = [];
  final _cityController = NoUnderlineTextEditingController();
  final _bioController = NoUnderlineTextEditingController();

  bool _loading = true;
  bool _saving = false;
  int _yearsExperience = 5;
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
    setStatusBarStyle(Brightness.dark);
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

    // Load phones
    final String rawPhone = (profile?['phone'] as String?) ?? AppState.registeredPhone.value;
    final String cleanPhone = rawPhone.replaceAll('+94', '').trim();
    _phoneControllers.clear();
    _phoneControllers.add(NoUnderlineTextEditingController(text: cleanPhone));

    final certUrls = (profile?['certificateUrls'] as List?)?.cast<String>() ?? const [];

    setState(() {
      _yearsExperience = profile?['yearsExperience'] as int? ?? 5;
      _radiusKm = profile?['serviceRadiusKm'] as int? ?? 10;
      _selectedSkills
        ..clear()
        ..addAll((profile?['skills'] as List?)?.cast<String>() ?? const [
          'Mobility assistance',
          'Medication management',
          'Dementia care',
        ]);
      _selectedLanguages
        ..clear()
        ..addAll((profile?['languagesSpoken'] as List?)?.cast<String>() ?? const [
          'Sinhala',
          'English',
        ]);
      _certificateUrls
        ..clear()
        ..addAll(certUrls);
      _certificateLabels
        ..clear()
        ..addAll(
          certUrls.map((u) => u.split('/').last.split('?').first).toList(),
        );
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final firstPhoneDigits =
          _phoneControllers.isNotEmpty ? _phoneControllers[0].text.trim() : '';
      final fullPhone =
          firstPhoneDigits.isNotEmpty ? '+94$firstPhoneDigits' : '';

      final caregiverData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'yearsExperience': _yearsExperience,
        'serviceRadiusKm': _radiusKm,
        'skills': _selectedSkills.toList(),
        'languagesSpoken': _selectedLanguages.toList(),
        'certificateUrls': _certificateUrls,
      };
      if (fullPhone.isNotEmpty) {
        caregiverData['phone'] = fullPhone;
      }

      await CaregiverService.saveCaregiverProfile(
        uid: user.uid,
        data: caregiverData,
      );

      // Best effort sync with users collection
      try {
        await AuthService.saveUserProfile(
          uid: user.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: fullPhone.isNotEmpty ? fullPhone : null,
        );
      } catch (e) {
        debugPrint('Non-fatal error updating user doc: $e');
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      debugPrint('Error saving caregiver profile: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save changes: $e'),
          backgroundColor: Colors.redAccent,
        ),
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
        data: {
          'certificateUrls': FieldValue.arrayUnion([url]),
        },
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

  Future<void> _removeCertificate(int index) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final url = _certificateUrls[index];
    setState(() {
      _certificateUrls.removeAt(index);
      _certificateLabels.removeAt(index);
    });
    await CaregiverService.saveCaregiverProfile(
      uid: uid,
      data: {
        'certificateUrls': FieldValue.arrayRemove([url]),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _titleDark,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Edit profile',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: _titleDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Form Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _saveBg),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: _buildAvatarPicker()),
                          const SizedBox(height: 24),

                          _buildLabel('Full name'),
                          const SizedBox(height: 8),
                          _buildTextField(_nameController, showEditIcon: true),
                          const SizedBox(height: 18),

                          _buildLabel('Email address'),
                          const SizedBox(height: 8),
                          _buildTextField(_emailController,
                              keyboardType: TextInputType.emailAddress,
                              showEditIcon: true),
                          const SizedBox(height: 18),

                          _buildLabel('Phone numbers'),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              for (int i = 0; i < _phoneControllers.length; i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                _buildPhoneField(
                                  _phoneControllers[i],
                                  canDelete: i > 0,
                                  onDelete: () => setState(
                                      () => _phoneControllers.removeAt(i)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => setState(() => _phoneControllers
                                .add(NoUnderlineTextEditingController())),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline_rounded,
                                    color: _addPhoneIcon, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Add another phone number',
                                  style: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: _addPhoneText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Years of experience'),
                          const SizedBox(height: 8),
                          _buildStepperRow(
                            value:
                                '$_yearsExperience ${_yearsExperience == 1 ? 'year' : 'years'}',
                            onDecrement: () {
                              if (_yearsExperience > 0) {
                                setState(() => _yearsExperience--);
                              }
                            },
                            onIncrement: () =>
                                setState(() => _yearsExperience++),
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
                            spacing: 8,
                            runSpacing: 8,
                            children: _skills.map((skill) {
                              final isSelected =
                                  _selectedSkills.contains(skill);
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
                            spacing: 8,
                            runSpacing: 8,
                            children: _languages.map((lang) {
                              final isSelected =
                                  _selectedLanguages.contains(lang);
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
                          _buildBioField(),
                          const SizedBox(height: 20),

                          _buildLabel('Certificates'),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              for (int i = 0;
                                  i < _certificateLabels.length;
                                  i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                _buildCertRow(_certificateLabels[i],
                                    () => _removeCertificate(i)),
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
                                color: Colors.transparent,
                                border: Border.all(
                                    color: _certBorder, width: 1.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _addingCertificate
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              color: _addCertIcon,
                                              strokeWidth: 2),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Uploading...',
                                          style: TextStyle(
                                              fontFamily: 'Open Sans',
                                              color: _certText,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.note_add_rounded,
                                            color: _addCertIcon, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Add certificate',
                                          style: TextStyle(
                                              fontFamily: 'Open Sans',
                                              color: _certText,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),

            // Fixed Bottom Save Changes Button
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: _saveBg,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _saving ? null : _saveProfile,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Save changes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
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
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: imagePath == null
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                        )
                      : null,
                ),
                child: imagePath != null
                    ? ClipOval(
                        child: RemoteOrLocalImage(
                            source: imagePath, width: 88, height: 88),
                      )
                    : Center(
                        child: Text(
                          _initials(),
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF383A81),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF5EEDE), width: 2),
                  ),
                  child: const Icon(Icons.photo_camera_rounded,
                      color: Colors.white, size: 14),
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
        fontFamily: 'Open Sans',
        color: _fieldLabel,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Locked +94 prefix phone field — user types only 9 digits
  Widget _buildPhoneField(
    TextEditingController controller, {
    bool canDelete = false,
    VoidCallback? onDelete,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _fieldBg,
        border: Border.all(color: _fieldBorder, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: _fieldBorder.withValues(alpha: 0.4)),
              ),
            ),
            child: const Text(
              '+94',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: _fieldText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: _fieldText,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                hintText: '77 123 4567',
                hintStyle: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.black38,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (canDelete)
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(Icons.delete_outline_rounded,
                    color: _certDelete, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool showEditIcon = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _fieldBg,
        border: Border.all(color: _fieldBorder, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: _fieldText,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (showEditIcon) ...[
            const SizedBox(width: 8),
            const Icon(Icons.edit_rounded, color: Color(0xFF1A3253), size: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildBioField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _fieldBg,
        border: Border.all(color: _fieldBorder, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _bioController,
        maxLines: 4,
        minLines: 3,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: _fieldText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        decoration: const InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Tell patients a little about yourself...',
          hintStyle: TextStyle(
            fontFamily: 'Open Sans',
            color: Colors.black38,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _fieldBg,
        border: Border.all(color: _fieldBorder, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: _fieldText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: const Icon(Icons.remove_rounded,
                    color: _stepperIcon, size: 22),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onIncrement,
                child: const Icon(Icons.add_rounded,
                    color: _stepperIcon, size: 22),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _chipSelectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: isSelected
              ? null
              : Border.all(color: _chipUnselectedText, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded,
                  color: _chipSelectedText, size: 15),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: isSelected ? _chipSelectedText : _chipUnselectedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertRow(String filename, VoidCallback onRemove) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _certBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: _certIcon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              filename,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: _certText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.cancel_rounded,
                color: _certDelete, size: 18),
          ),
        ],
      ),
    );
  }
}
