import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  "Submit training certificates" dialog
//  Figma node: 498-6531 · shown when a caregiver selects "Yes"
//  for "Formal caregiving training" during onboarding.
//
//  Returns the picked files on Submit, or null on Cancel.
// ─────────────────────────────────────────────────────────────
Future<List<XFile>?> showCertificateUploadDialog(BuildContext context) {
  return showDialog<List<XFile>>(
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
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _mustard = Color(0xFFFCD34D);
  static const Color _geyser = Color(0xFFCBD5E1);

  final List<XFile> _files = [];

  Future<void> _pickCertificate() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _indigo),
              title: const Text('Take a photo',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _indigo),
              title: const Text('Choose from gallery',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _files.add(picked));
  }

  void _submit() {
    if (_files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one certificate.')),
      );
      return;
    }
    Navigator.pop(context, _files);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(23),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit training certificates',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload your caregiving training certificate(s) for verification.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickCertificate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 21),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.upload_file_rounded, color: _indigo, size: 26),
                    SizedBox(height: 6),
                    Text(
                      'Tap to upload certificate',
                      style: TextStyle(color: _geyser, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'PDF, JPG or PNG',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
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
                      color: AppTheme.surfaceColor,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_rounded, color: _indigoLight, size: 14),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Text(
                            _files[i].name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(color: _geyser, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => setState(() => _files.removeAt(i)),
                          child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 14),
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
                      'Once submitted, certificates cannot be edited or changed. '
                      'Please review before sending.',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
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
                      onTap: _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
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
          ],
        ),
      ),
    );
  }
}
