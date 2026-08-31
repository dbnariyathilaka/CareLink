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
  static const Color _addPhoneIcon = Color(0xFF6F5620);
  static const Color _addPhoneText = Color(0xFF885F36);
  static const Color _chipSelectedBg = Color(0xFF223A5C);
  static const Color _certBg = Color(0xFFF4D9BF);
  static const Color _certBorder = Color(0xFF443423);
  static const Color _certText = Color(0xFF443423);
  static const Color _addCertIcon = Color(0xFFFBBC05);
  static const Color _saveBg = Color(0xFF1F3554);

  final _nameController = NoUnderlineTextEditingController();
  final _emailController = NoUnderlineTextEditingController();
  final List<TextEditingController> _phoneControllers = [];
  final _nicController = NoUnderlineTextEditingController();
  final _refPhoneController = NoUnderlineTextEditingController();
  final _cityController = NoUnderlineTextEditingController();
  final _bioController = NoUnderlineTextEditingController();

  bool _loading = true;
  bool _saving = false;

  String _gender = 'Male';
  int _yearsExperience = 5;
  int _radiusKm = 10;
  String _educationalQualification = 'Diploma';
  bool _formalTraining = false;

  static const List<String> _allCareTypes = [
    'Part-time',
    'Full-time',
    'Live-in',
    'Flexible',
  ];
  final Set<String> _selectedCareTypes = {'Part-time', 'Full-time'};

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

  // Inline error strings
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _extraPhonesError;
  String? _nicError;
  String? _refPhoneError;
  String? _cityError;
  String? _careTypeError;
  String? _skillsError;
  String? _languagesError;

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
    final userDoc = await AuthService.getUserProfile(user.uid);
    if (!mounted) return;

    final merged = <String, dynamic>{
      if (userDoc != null) ...userDoc,
      if (profile != null) ...profile,
    };

    AppState.hydrateCaregiverPhoto(merged['photoUrl'] as String?);
    _nameController.text = (merged['name'] as String?)?.trim() ?? user.displayName ?? '';
    _emailController.text = (merged['email'] as String?)?.trim() ?? user.email ?? '';
    _nicController.text = (merged['nic'] as String?)?.trim() ?? '';
    _cityController.text = (merged['city'] as String?)?.trim() ?? '';
    _bioController.text = (merged['bio'] as String?)?.trim() ?? '';

    // Phones — prefer the real multi-number list if present, falling back
    // to the single legacy `phone` field for profiles saved before this
    // list existed.
    final phoneList = (merged['phoneNumbers'] as List?)?.cast<String>();
    final rawPhones = (phoneList != null && phoneList.isNotEmpty)
        ? phoneList
        : [(merged['phone'] as String?) ?? AppState.registeredPhone.value];
    _phoneControllers.clear();
    for (final raw in rawPhones) {
      _phoneControllers.add(NoUnderlineTextEditingController(text: raw.replaceAll('+94', '').trim()));
    }

    // Ref phone
    final String rawRef = (merged['referencePhone'] as String?) ?? '';
    _refPhoneController.text = rawRef.replaceAll('+94', '').trim();

    final certUrls = (merged['certificateUrls'] as List?)?.cast<String>() ?? const [];

    setState(() {
      _gender = (merged['gender'] as String?)?.trim() ?? 'Male';
      _yearsExperience = merged['yearsExperience'] as int? ?? 5;
      _radiusKm = merged['serviceRadiusKm'] as int? ?? 10;
      _educationalQualification =
          (merged['educationalQualification'] as String?)?.trim() ?? 'Diploma';
      _formalTraining = merged['formalTraining'] == true;

      _selectedCareTypes
        ..clear()
        ..addAll((merged['careTypes'] as List?)?.cast<String>() ?? const ['Part-time', 'Full-time']);

      _selectedSkills
        ..clear()
        ..addAll((merged['skills'] as List?)?.cast<String>() ?? const [
          'Mobility assistance',
          'Medication management',
          'Dementia care',
        ]);

      _selectedLanguages
        ..clear()
        ..addAll((merged['languagesSpoken'] as List?)?.cast<String>() ?? const [
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

  // ── Validation logic ──────────────────────────────────────
  String? _validateName(String val) {
    final v = val.trim();
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String val) {
    final v = val.trim();
    if (v.isEmpty) return 'Email address is required';
    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String val) {
    final v = val.trim();
    if (v.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{9}$').hasMatch(v)) return 'Enter exactly 9 digits after +94';
    return null;
  }

  String? _validateNic(String val) {
    final v = val.trim().toUpperCase();
    if (v.isEmpty) return 'NIC number is required';
    final oldNic = RegExp(r'^\d{9}[VX]$');
    final newNic = RegExp(r'^\d{12}$');
    if (oldNic.hasMatch(v) || newNic.hasMatch(v)) return null;
    return 'Enter 9 digits + V/X (e.g. 972345678V) or 12 digits';
  }

  String? _validateRefPhone(String val) {
    final v = val.trim();
    if (v.isEmpty) return null; // Optional
    if (!RegExp(r'^\d{9}$').hasMatch(v)) return 'Reference phone must be exactly 9 digits';
    final primary = _phoneControllers.isNotEmpty ? _phoneControllers[0].text.trim() : '';
    if (primary.isNotEmpty && v == primary) {
      return 'Reference phone must be different from primary phone';
    }
    return null;
  }

  String? _validateCity(String val) {
    final v = val.trim();
    if (v.isEmpty) return 'City / area is required';
    if (v.length < 2) return 'City must be at least 2 characters';
    return null;
  }

  /// Extra phone numbers beyond the first are optional — only validated
  /// (must be 9 digits) if the caregiver actually typed something into them.
  bool _extraPhonesValid() {
    for (var i = 1; i < _phoneControllers.length; i++) {
      final v = _phoneControllers[i].text.trim();
      if (v.isNotEmpty && !RegExp(r'^\d{9}$').hasMatch(v)) return false;
    }
    return true;
  }

  bool _runValidation() {
    final nameErr = _validateName(_nameController.text);
    final emailErr = _validateEmail(_emailController.text);
    final phoneErr = _phoneControllers.isNotEmpty
        ? _validatePhone(_phoneControllers[0].text)
        : 'Phone number is required';
    final extraPhonesErr = _extraPhonesValid() ? null : 'Additional phone numbers must be exactly 9 digits';
    final nicErr = _validateNic(_nicController.text);
    final refPhoneErr = _validateRefPhone(_refPhoneController.text);
    final cityErr = _validateCity(_cityController.text);
    final careErr = _selectedCareTypes.isEmpty ? 'Select at least one care type' : null;
    final skillsErr = _selectedSkills.isEmpty ? 'Select at least one skill' : null;
    final langErr = _selectedLanguages.isEmpty ? 'Select at least one language' : null;

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
      _extraPhonesError = extraPhonesErr;
      _nicError = nicErr;
      _refPhoneError = refPhoneErr;
      _cityError = cityErr;
      _careTypeError = careErr;
      _skillsError = skillsErr;
      _languagesError = langErr;
    });

    return nameErr == null &&
        emailErr == null &&
        phoneErr == null &&
        extraPhonesErr == null &&
        nicErr == null &&
        refPhoneErr == null &&
        cityErr == null &&
        careErr == null &&
        skillsErr == null &&
        langErr == null;
  }

  Future<void> _saveProfile() async {
    if (!_runValidation()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form before saving.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final allPhones = _phoneControllers
          .map((c) => c.text.trim())
          .where((digits) => digits.isNotEmpty)
          .map((digits) => '+94$digits')
          .toList();
      final fullPhone = allPhones.isNotEmpty ? allPhones.first : '';

      final refDigits = _refPhoneController.text.trim();
      final fullRefPhone = refDigits.isNotEmpty ? '+94$refDigits' : '';

      final caregiverData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _gender,
        'nic': _nicController.text.trim().toUpperCase(),
        'yearsExperience': _yearsExperience,
        'educationalQualification': _educationalQualification,
        'formalTraining': _formalTraining,
        'city': _cityController.text.trim(),
        'serviceRadiusKm': _radiusKm,
        'careTypes': _selectedCareTypes.toList(),
        'skills': _selectedSkills.toList(),
        'languagesSpoken': _selectedLanguages.toList(),
        'bio': _bioController.text.trim(),
        'certificateUrls': _certificateUrls,
        // Real multi-number list — 'phone' below stays the single primary
        // number for every other screen that only ever reads that field.
        'phoneNumbers': allPhones,
      };

      if (fullPhone.isNotEmpty) {
        caregiverData['phone'] = fullPhone;
      }
      if (fullRefPhone.isNotEmpty) {
        caregiverData['referencePhone'] = fullRefPhone;
      }

      await CaregiverService.saveCaregiverProfile(
        uid: user.uid,
        data: caregiverData,
      );

      // Sync with users collection
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
    _nicController.dispose();
    _refPhoneController.dispose();
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
                          _buildTextField(
                            _nameController,
                            errorText: _nameError,
                            showEditIcon: true,
                            onChanged: (_) {
                              if (_nameError != null) setState(() => _nameError = null);
                            },
                          ),
                          const SizedBox(height: 18),

                          _buildLabel('Email address'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            _emailController,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _emailError,
                            showEditIcon: true,
                            onChanged: (_) {
                              if (_emailError != null) setState(() => _emailError = null);
                            },
                          ),
                          const SizedBox(height: 18),

                          _buildLabel('Gender'),
                          const SizedBox(height: 8),
                          _buildGenderSelector(),
                          const SizedBox(height: 18),

                          _buildLabel('NIC number'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            _nicController,
                            hintText: 'e.g. 972345678V or 200012345678',
                            errorText: _nicError,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9VvXx]')),
                              LengthLimitingTextInputFormatter(12),
                            ],
                            onChanged: (_) {
                              if (_nicError != null) setState(() => _nicError = null);
                            },
                          ),
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
                                  errorText: i == 0 ? _phoneError : null,
                                  onDelete: () => setState(() {
                                    _phoneControllers[i].dispose();
                                    _phoneControllers.removeAt(i);
                                    _extraPhonesError = null;
                                  }),
                                  onChanged: (val) {
                                    if (i == 0 && _phoneError != null) {
                                      setState(() => _phoneError = null);
                                    }
                                    if (i > 0 && _extraPhonesError != null) {
                                      setState(() => _extraPhonesError = null);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                          if (_extraPhonesError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                _extraPhonesError!,
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => setState(
                                () => _phoneControllers.add(NoUnderlineTextEditingController())),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: _addPhoneIcon, size: 18),
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
                          const SizedBox(height: 18),

                          _buildLabel('Reference phone number'),
                          const SizedBox(height: 8),
                          _buildPhoneField(
                            _refPhoneController,
                            canDelete: false,
                            errorText: _refPhoneError,
                            onChanged: (_) {
                              if (_refPhoneError != null) {
                                setState(() => _refPhoneError = null);
                              }
                            },
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

                          _buildLabel('Educational qualification'),
                          const SizedBox(height: 8),
                          _buildEduDropdown(),
                          const SizedBox(height: 20),

                          _buildLabel('Formal caregiving training'),
                          const SizedBox(height: 8),
                          _buildFormalTrainingToggle(),
                          const SizedBox(height: 20),

                          _buildLabel('City / area'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            _cityController,
                            errorText: _cityError,
                            onChanged: (_) {
                              if (_cityError != null) setState(() => _cityError = null);
                            },
                          ),
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

                          _buildLabel('Care type'),
                          const SizedBox(height: 10),
                          _buildCareTypeWrap(),
                          const SizedBox(height: 20),

                          _buildLabel('Skills'),
                          const SizedBox(height: 10),
                          _buildSkillsWrap(),
                          const SizedBox(height: 20),

                          _buildLabel('Languages spoken'),
                          const SizedBox(height: 10),
                          _buildLanguagesWrap(),
                          const SizedBox(height: 20),

                          _buildLabel('Short bio'),
                          const SizedBox(height: 8),
                          _buildBioField(),
                          const SizedBox(height: 20),

                          _buildLabel('Certificates & documents'),
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
                          _buildVerificationRow(),
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
                width: 96,
                height: 96,
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
                          source: imagePath,
                          width: 96,
                          height: 96,
                        ),
                      )
                    : Center(
                        child: Text(
                          _initials(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: _saveBg, size: 14),
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
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildGenderSelector() {
    final options = ['Male', 'Female', 'Other'];
    return Row(
      children: options.map((g) {
        final isSelected = _gender == g;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _chipSelectedBg : _fieldBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _fieldBorder),
                ),
                child: Text(
                  g,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: isSelected ? Colors.white : _fieldText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEduDropdown() {
    final options = ["High school", "Diploma", "Bachelor's degree", "Master's degree"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _fieldBorder, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(_educationalQualification)
              ? _educationalQualification
              : 'Diploma',
          isExpanded: true,
          dropdownColor: _fieldBg,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: _fieldText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _educationalQualification = val);
          },
        ),
      ),
    );
  }

  Widget _buildFormalTrainingToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _formalTraining = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _formalTraining ? _chipSelectedBg : _fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _fieldBorder),
              ),
              child: Text(
                'Yes (Trained)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: _formalTraining ? Colors.white : _fieldText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _formalTraining = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_formalTraining ? _chipSelectedBg : _fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _fieldBorder),
              ),
              child: Text(
                'No formal training',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: !_formalTraining ? Colors.white : _fieldText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCareTypeWrap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allCareTypes.map((type) {
            final isSelected = _selectedCareTypes.contains(type);
            return _buildCheckChip(
              label: type,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCareTypes.remove(type);
                  } else {
                    _selectedCareTypes.add(type);
                  }
                  if (_careTypeError != null) _careTypeError = null;
                });
              },
            );
          }).toList(),
        ),
        if (_careTypeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _careTypeError!,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsWrap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
                  if (_skillsError != null) _skillsError = null;
                });
              },
            );
          }).toList(),
        ),
        if (_skillsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _skillsError!,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLanguagesWrap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
                  if (_languagesError != null) _languagesError = null;
                });
              },
            );
          }).toList(),
        ),
        if (_languagesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _languagesError!,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool showEditIcon = false,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: errorText != null ? Colors.redAccent : _fieldBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: _fieldText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15.5),
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontFamily: 'Open Sans',
                      color: _fieldText.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (showEditIcon)
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.edit_outlined, color: _saveBg, size: 18),
                ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneField(
    TextEditingController controller, {
    required bool canDelete,
    String? errorText,
    VoidCallback? onDelete,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: errorText != null ? Colors.redAccent : _fieldBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15.5),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: _fieldBorder, width: 1),
                  ),
                ),
                child: const Text(
                  '+94',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: _fieldText,
                    fontSize: 14,
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
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: _fieldText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 15.5),
                    hintText: '71 185 6936',
                  ),
                ),
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepperRow({
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _fieldBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: _fieldText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: const Icon(Icons.remove_circle_outline_rounded,
                    color: _saveBg, size: 22),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onIncrement,
                child: const Icon(Icons.add_circle_outline_rounded,
                    color: _saveBg, size: 22),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _chipSelectedBg : _fieldBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _fieldBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: isSelected ? Colors.white : _fieldText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── "Verification" summary sheet — no admin verification-status field
  // exists anywhere in the schema (see the admin verification-queue work
  // earlier), so this shows the caregiver's real submitted documents with
  // a neutral "awaiting review" framing rather than a fabricated verdict.
  Widget _buildVerificationRow() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/caregiver-verification-status'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _fieldBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: _saveBg, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verification',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: _fieldText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _fieldText, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBioField() {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _fieldBorder),
      ),
      child: TextField(
        controller: _bioController,
        maxLines: 4,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: _fieldText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
          hintText: 'Write a brief description of your experience and care approach...',
        ),
      ),
    );
  }

  Widget _buildCertRow(String name, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _certBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _certBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: _saveBg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: _certText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 20),
          ),
        ],
      ),
    );
  }
}

