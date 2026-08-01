import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/upload_picker_sheet.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 5 of 6
//  Figma node: 436-466 · "Police clearance certificate"
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
  static const Color bg = Color(0xFFF1F8E1);
  static const Color titleDark = Color(0xFF112541);
  static const Color stepLabel = Color(0xFF94A3B8);
  static const Color progressActive = Color(0xFF345058);
  static const Color progressInactive = Color.fromRGBO(137, 171, 199, 0.37);
  static const Color dropzoneBg = Color.fromRGBO(193, 179, 157, 0.18);
  static const Color dropzoneBorder = Color.fromRGBO(68, 51, 28, 0.34);
  static const Color dropzoneLabel = Color(0xFF2E2A1F);
  static const Color dropzoneCaption = Color(0xFF64748B);
  static const Color warningBg = Color(0xFFE6E9D2);
  static const Color warningBorder = Color(0xFFAD9067);
  static const Color warningText = Color(0xFF8B5C27);
  static const Color fileRowBorder = Color.fromRGBO(0, 0, 0, 0.4);
  static const Color fileRowText = Color(0xFF2F2313);
  static const Color removeIcon = Color(0xFFA34207);
  static const Color continueBg = Color(0xFF223A5C);

  _UploadedDoc? _policeClearance;
  final List<_UploadedDoc> _otherDocuments = [];
  bool _uploadingPoliceClearance = false;
  bool _uploadingOtherDocument = false;

  bool get _busy => _uploadingPoliceClearance || _uploadingOtherDocument;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

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
                    'Step 5 of 6',
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

              _buildProgressBar(currentStep: 5, totalSteps: 6),

              const SizedBox(height: 24),

              const Text(
                'Police clearance certificate',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Upload a valid police clearance / criminal background '
                'certificate for verification (optional — you can add this '
                'later from your profile).',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: stepLabel,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
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
                            color: dropzoneBg,
                            border: Border.all(color: dropzoneBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _uploadingPoliceClearance
                              ? const Column(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: continueBg, strokeWidth: 2.5),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Uploading...',
                                      style: TextStyle(fontFamily: 'Open Sans', color: dropzoneLabel, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const Icon(Icons.cloud_upload_outlined, color: Colors.black54, size: 48),
                                    const SizedBox(height: 6),
                                    Text(
                                      _policeClearance == null
                                          ? 'Tap to upload certificate'
                                          : 'Tap to replace certificate',
                                      style: const TextStyle(
                                        fontFamily: 'Open Sans',
                                        color: dropzoneLabel,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'PDF, JPG or PNG',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: dropzoneCaption,
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
                        _buildFileRow(
                          name: _policeClearance!.name,
                          onRemove: () => setState(() => _policeClearance = null),
                        ),
                      ],

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        decoration: BoxDecoration(
                          color: warningBg,
                          border: Border.all(color: warningBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_rounded, color: warningBorder, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Once submitted, this certificate cannot be edited or '
                                'changed. Please review before sending.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: warningText,
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
                          fontFamily: 'Open Sans',
                          color: titleDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add any additional certifications, licenses or awards '
                        'that support your profile.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: dropzoneCaption,
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
                            color: dropzoneBg,
                            border: Border.all(color: dropzoneBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _uploadingOtherDocument
                              ? const Column(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: continueBg, strokeWidth: 2.5),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Uploading...',
                                      style: TextStyle(fontFamily: 'Open Sans', color: dropzoneLabel, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                )
                              : const Column(
                                  children: [
                                    Icon(Icons.cloud_upload_outlined, color: Colors.black54, size: 48),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tap to add a document',
                                      style: TextStyle(
                                        fontFamily: 'Open Sans',
                                        color: dropzoneLabel,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'PDF, JPG or PNG · multiple files allowed',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: dropzoneCaption,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_otherDocuments.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Uploaded',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color.fromRGBO(68, 51, 28, 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(_otherDocuments.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildFileRow(
                              name: _otherDocuments[i].name,
                              onRemove: () => setState(() => _otherDocuments.removeAt(i)),
                            ),
                          );
                        }),
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
                          side: const BorderSide(color: continueBg, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontFamily: 'Inter', color: continueBg, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: continueBg,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _busy ? null : _submit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Submit',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
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

  Widget _buildFileRow({required String name, required VoidCallback onRemove}) {
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: fileRowBorder, width: 1.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: fileRowText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.cancel_rounded, color: removeIcon, size: 22),
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
              color: isActive ? progressActive : progressInactive,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
