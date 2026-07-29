import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/upload_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 5 of 6
//  Figma node: 498-6677 · "Police clearance certificate"
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding5Screen extends StatefulWidget {
  const CaregiverOnboarding5Screen({super.key});

  @override
  State<CaregiverOnboarding5Screen> createState() =>
      _CaregiverOnboarding5ScreenState();
}

class _UploadedDoc {
  const _UploadedDoc({required this.name, required this.url});
  final String name;
  final String url;
}

class _CaregiverOnboarding5ScreenState
    extends State<CaregiverOnboarding5Screen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _mustard = Color(0xFFFCD34D);
  static const Color _geyser = Color(0xFFCBD5E1);

  _UploadedDoc? _policeClearance;
  final List<_UploadedDoc> _otherDocuments = [];
  bool _uploadingPoliceClearance = false;
  bool _uploadingOtherDocument = false;

  bool get _busy => _uploadingPoliceClearance || _uploadingOtherDocument;

  Future<void> _pickPoliceClearance() async {
    final picked = await pickImageOrDocument(context);
    if (picked == null || !mounted) return;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploadingPoliceClearance = true);
    try {
      final url = await StorageService.uploadBytes(
        storagePath: StorageService.policeClearancePath(uid, picked.name),
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      if (!mounted) return;
      setState(() {
        _policeClearance = _UploadedDoc(name: picked.name, url: url);
        _uploadingPoliceClearance = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingPoliceClearance = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload certificate. Please try again.')),
      );
    }
  }

  Future<void> _pickOtherDocument() async {
    final picked = await pickImageOrDocument(context);
    if (picked == null || !mounted) return;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploadingOtherDocument = true);
    try {
      final url = await StorageService.uploadBytes(
        storagePath: StorageService.otherDocumentPath(uid, picked.name),
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      if (!mounted) return;
      setState(() {
        _otherDocuments.add(_UploadedDoc(name: picked.name, url: url));
        _uploadingOtherDocument = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingOtherDocument = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload document. Please try again.')),
      );
    }
  }

  void _submit() {
    final draft = AppState.caregiverOnboardingDraft;
    draft.policeClearanceUrl = _policeClearance?.url ?? '';
    draft.otherDocumentUrls = _otherDocuments.map((d) => d.url).toList();
    Navigator.pushNamed(context, '/caregiver-onboarding-6');
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
                    'Step 5 of 6',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildProgressBar(currentStep: 5, totalSteps: 6),

              const SizedBox(height: 24),

              const Text(
                'Police clearance certificate',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Upload a valid police clearance / criminal background '
                'certificate for verification (optional — you can add this '
                'later from your profile).',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: _busy ? null : _pickPoliceClearance,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _uploadingPoliceClearance
                              ? const Column(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: _indigo, strokeWidth: 2.5),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Uploading...',
                                      style: TextStyle(color: _geyser, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const Icon(Icons.gavel_rounded, color: _indigo, size: 26),
                                    const SizedBox(height: 6),
                                    Text(
                                      _policeClearance == null
                                          ? 'Tap to upload certificate (optional)'
                                          : 'Tap to replace certificate',
                                      style: const TextStyle(
                                        color: _geyser,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'PDF, JPG or PNG',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_policeClearance != null) ...[
                        const SizedBox(height: 10),
                        _buildFileChip(
                          name: _policeClearance!.name,
                          onRemove: () => setState(() => _policeClearance = null),
                        ),
                      ],

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.1),
                          border: Border.all(color: _amber.withValues(alpha: 0.35)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_rounded, color: _amber, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Once submitted, this certificate cannot be edited or '
                                'changed. Please review before sending.',
                                style: TextStyle(
                                  color: _mustard,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Other qualification documents',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Add any additional certifications, licenses or awards '
                        'that support your profile.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: _busy ? null : _pickOtherDocument,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(21),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _uploadingOtherDocument
                              ? const Column(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: _indigo, strokeWidth: 2.5),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Uploading...',
                                      style: TextStyle(color: _geyser, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                )
                              : const Column(
                                  children: [
                                    Icon(Icons.note_add_rounded, color: _indigo, size: 26),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tap to add a document',
                                      style: TextStyle(
                                        color: _geyser,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'PDF, JPG or PNG · multiple files allowed',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_otherDocuments.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(_otherDocuments.length, (i) {
                            return _buildFileChip(
                              name: _otherDocuments[i].name,
                              onRemove: () => setState(() => _otherDocuments.removeAt(i)),
                            );
                          }),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: _geyser, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: _indigo,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _busy ? null : _submit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Submit',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileChip({required String name, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_rounded, color: _indigoLight, size: 14),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(color: _geyser, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 14),
          ),
        ],
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
}
