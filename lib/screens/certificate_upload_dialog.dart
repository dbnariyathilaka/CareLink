import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/matching_service.dart' show nvqLabels;
import '../services/storage_service.dart';
import '../widgets/upload_picker_sheet.dart';

/// What "Submit" returns: the caregiver's real NVQ level (the thesis's S2
/// proxy strategy only applies when this is genuinely absent, so it's
/// required here, not optional) plus the uploaded certificate file(s).
typedef CertificateSubmission = ({int nvqLevel, List<String> urls});

// ─────────────────────────────────────────────────────────────
//  "Submit training certificates" dialog
//  Figma node: 355-1659 · shown when a caregiver selects "Yes"
//  for "Formal caregiving training" during onboarding.
//
//  Uploads each picked file to Storage as it's selected; Submit requires
//  both an NVQ level and at least one file, and returns both, or null on
//  Cancel.
// ─────────────────────────────────────────────────────────────
Future<CertificateSubmission?> showCertificateUploadDialog(BuildContext context) {
  return showDialog<CertificateSubmission>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const CertificateUploadDialog(),
  );
}

class CertificateUploadDialog extends StatefulWidget {
  const CertificateUploadDialog({super.key});

  @override
  State<CertificateUploadDialog> createState() => _CertificateUploadDialogState();
}

class _CertificateUploadDialogState extends State<CertificateUploadDialog> {
  static const Color _dialogBg = Color(0xFFDAD5D1);
  static const Color _dialogBorder = Color(0xFF334155);
  static const Color _titleDark = Color(0xFF112541);
  static const Color _subtitle = Color(0xFF475467);
  static const Color _dropzoneIcon = Color(0xFF505185);
  static const Color _dropzoneLabel = Color(0xFF334155);
  static const Color _dropzoneCaption = Color(0xFF64748B);
  static const Color _warningBg = Color(0xFFC2A792);
  static const Color _warningBorder = Color(0xFF94521F);
  static const Color _warningText = Color(0xFF7D583B);
  static const Color _continueBg = Color(0xFF223A5C);

  final List<_Certificate> _files = [];
  bool _uploading = false;
  int? _nvqLevel;

  Future<void> _pickCertificate() async {
    final picked = await pickImageOrDocument(context);
    if (picked == null || !mounted) return;

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploading = true);
    try {
      final url = await StorageService.uploadBytes(
        storagePath: StorageService.certificatePath(uid, picked.name),
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      if (!mounted) return;
      setState(() {
        _files.add(_Certificate(name: picked.name, url: url));
        _uploading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload certificate. Please try again.')),
      );
    }
  }

  void _submit() {
    if (_nvqLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your certificate type.')),
      );
      return;
    }
    if (_files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one certificate.')),
      );
      return;
    }
    Navigator.pop<CertificateSubmission>(
      context,
      (nvqLevel: _nvqLevel!, urls: _files.map((f) => f.url).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: _dialogBg,
          border: Border.all(color: _dialogBorder),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.all(23),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit training certificates',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: _titleDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload your caregiving training certificate(s) for verification.',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: _subtitle,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Certificate type',
              style: TextStyle(fontFamily: 'Open Sans', color: _subtitle, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: _dialogBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _nvqLevel,
                  isExpanded: true,
                  hint: const Text(
                    'Select your NVQ level',
                    style: TextStyle(fontFamily: 'Open Sans', color: _dropzoneCaption, fontSize: 13),
                  ),
                  items: nvqLabels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(
                              e.value,
                              style: const TextStyle(fontFamily: 'Open Sans', color: _titleDark, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _nvqLevel = val),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _uploading ? null : _pickCertificate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 21),
                decoration: BoxDecoration(
                  border: Border.all(color: _dialogBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _uploading
                    ? const Column(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: _continueBg, strokeWidth: 2.5),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Uploading...',
                            style: TextStyle(fontFamily: 'Open Sans', color: _dropzoneLabel, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : const Column(
                        children: [
                          Icon(Icons.upload_file_rounded, color: _dropzoneIcon, size: 26),
                          SizedBox(height: 6),
                          Text(
                            'Tap to upload certificate',
                            style: TextStyle(fontFamily: 'Open Sans', color: _dropzoneLabel, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'PDF, JPG or PNG',
                            style: TextStyle(fontFamily: 'Inter', color: _dropzoneCaption, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
              ),
            ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_files.length, (i) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _dialogBorder),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_rounded, color: _dropzoneIcon, size: 14),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Text(
                            _files[i].name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontFamily: 'Open Sans', color: _dropzoneLabel, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => setState(() => _files.removeAt(i)),
                          child: const Icon(Icons.close_rounded, color: _dropzoneCaption, size: 14),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: _warningBg,
                border: Border.all(color: _warningBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_rounded, color: _warningText, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once submitted, certificates cannot be edited or changed. '
                      'Please review before sending.',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: _warningText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _continueBg),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontFamily: 'Open Sans', color: _continueBg, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: _continueBg,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text(
                          'Submit',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Certificate {
  const _Certificate({required this.name, required this.url});
  final String name;
  final String url;
}
