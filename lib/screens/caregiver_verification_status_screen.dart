import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/storage_service.dart';
import '../widgets/status_bar.dart';
import '../widgets/upload_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Verification Status Screen
//  Figma node: 652-1204
//  Reads the same real per-document review decisions the admin
//  verification-queue screen writes (caregiverProfiles.documentReviews) —
//  a document with no entry there is honestly shown as "In review", not a
//  fabricated status. Re-upload for a rejected document is a real write
//  (CaregiverService.replaceDocumentUrl), which also clears that document's
//  stale decision since the replacement hasn't been reviewed yet.
// ─────────────────────────────────────────────────────────────
class CaregiverVerificationStatusScreen extends StatefulWidget {
  const CaregiverVerificationStatusScreen({super.key});

  @override
  State<CaregiverVerificationStatusScreen> createState() => _CaregiverVerificationStatusScreenState();
}

class _CaregiverVerificationStatusScreenState extends State<CaregiverVerificationStatusScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color titleDark = Color(0xFF113341);
  static const Color bannerBg = Color(0xFFF3E7C9);
  static const Color bannerBorder = Color(0xFFD8C48F);
  static const Color bannerTitle = Color(0xFF06402B);
  static const Color bannerSub = Color(0xFF6B6355);
  static const Color progressDone = Color(0xFFC56322);
  static const Color progressEmpty = Color(0xFFD8D3C5);
  static const Color sectionLabel = Color(0xFF544730);
  static const Color docCardBg = Color(0xFF1F3554);
  static const Color docNameApproved = Color(0xFF7EC8E3);
  static const Color docSub = Color(0xFFB5ADA2);
  static const Color rejectedCardBg = Color(0xFFF3D9D9);
  static const Color rejectedTitle = Color(0xFFB01E1E);
  static const Color noteCardBg = Color(0xFFDCE4F0);
  static const Color noteText = Color(0xFF1F3554);
  static const Color contactBg = Color(0xFF1F3554);

  bool _loading = true;
  Map<String, dynamic>? _profile;
  final Set<String> _uploadingKeys = {};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final profile = await CaregiverService.getCaregiverProfile(uid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  String _labelForUrl(String url, String fallback) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isEmpty) return fallback;
      var last = Uri.decodeComponent(uri.pathSegments.last);
      if (last.contains('/')) last = last.substring(last.lastIndexOf('/') + 1);
      return last.isNotEmpty ? last : fallback;
    } catch (_) {
      return fallback;
    }
  }

  List<({String key, String label, String? uploadPathFor})> _documents(Map<String, dynamic> profile) {
    final docs = <({String key, String label, String? uploadPathFor})>[];
    final nic = (profile['nic'] as String?)?.trim();
    if (nic != null && nic.isNotEmpty) {
      docs.add((key: 'nic', label: 'NIC — $nic', uploadPathFor: null));
    }
    final police = (profile['policeClearanceUrl'] as String?) ?? '';
    if (police.isNotEmpty) {
      docs.add((key: 'policeClearance', label: _labelForUrl(police, 'Police clearance certificate'), uploadPathFor: 'policeClearance'));
    }
    final certs = (profile['certificateUrls'] as List?)?.cast<String>() ?? const [];
    for (var i = 0; i < certs.length; i++) {
      final key = 'cert$i';
      docs.add((key: key, label: _labelForUrl(certs[i], 'Certificate ${i + 1}'), uploadPathFor: key));
    }
    final other = (profile['otherDocumentUrls'] as List?)?.cast<String>() ?? const [];
    for (var i = 0; i < other.length; i++) {
      final key = 'other$i';
      docs.add((key: key, label: _labelForUrl(other[i], 'Other document ${i + 1}'), uploadPathFor: key));
    }
    return docs;
  }

  Future<void> _reupload(String docKey) async {
    final picked = await pickImageOrDocument(context);
    if (picked == null || !mounted) return;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploadingKeys.add(docKey));
    try {
      final path = docKey == 'policeClearance'
          ? StorageService.policeClearancePath(uid, picked.name)
          : docKey.startsWith('cert')
              ? StorageService.certificatePath(uid, picked.name)
              : StorageService.otherDocumentPath(uid, picked.name);
      final url = await StorageService.uploadBytes(
        storagePath: path,
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      await CaregiverService.replaceDocumentUrl(uid: uid, docKey: docKey, newUrl: url);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not re-upload. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingKeys.remove(docKey));
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? const {};
    final reviews = (profile['documentReviews'] as Map?)?.cast<String, dynamic>() ?? const {};
    final documents = _documents(profile);

    final approvedCount = documents.where((d) => (reviews[d.key]?['status']) == 'approved').length;
    final rejectedDocs = documents.where((d) => (reviews[d.key]?['status']) == 'rejected').toList();
    final totalCount = documents.length;
    final allApproved = totalCount > 0 && approvedCount == totalCount;
    final anyRejected = rejectedDocs.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: titleDark, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Verification status',
                    style: TextStyle(fontFamily: 'Open Sans', color: titleDark, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: titleDark))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (totalCount == 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: bannerBg, border: Border.all(color: bannerBorder), borderRadius: BorderRadius.circular(14)),
                              child: const Text(
                                'No documents submitted yet — add them from Edit profile.',
                                style: TextStyle(fontFamily: 'Open Sans', color: bannerSub, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            )
                          else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: bannerBg, border: Border.all(color: bannerBorder), borderRadius: BorderRadius.circular(14)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        allApproved ? Icons.check_circle_rounded : (anyRejected ? Icons.error_rounded : Icons.hourglass_bottom_rounded),
                                        color: bannerTitle,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        allApproved ? 'All verified' : (anyRejected ? 'Action needed' : 'Under review'),
                                        style: const TextStyle(fontFamily: 'Open Sans', color: bannerTitle, fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    allApproved
                                        ? 'All your documents have been approved.'
                                        : 'You can\'t accept jobs until all documents are approved.',
                                    style: const TextStyle(fontFamily: 'Open Sans', color: bannerSub, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 12),
                                  Stack(
                                    children: [
                                      Container(height: 6, decoration: BoxDecoration(color: progressEmpty, borderRadius: BorderRadius.circular(3))),
                                      FractionallySizedBox(
                                        widthFactor: totalCount == 0 ? 0 : approvedCount / totalCount,
                                        child: Container(height: 6, decoration: BoxDecoration(color: progressDone, borderRadius: BorderRadius.circular(3))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '$approvedCount of $totalCount',
                                      style: const TextStyle(fontFamily: 'Open Sans', color: progressDone, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'YOUR DOCUMENTS',
                              style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            ...documents.map((d) {
                              final review = reviews[d.key] as Map<String, dynamic>?;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildDocCard(d.key, d.label, review),
                              );
                            }),
                            const SizedBox(height: 12),
                            const Text(
                              'ADMIN NOTES',
                              style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            if (rejectedDocs.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(color: noteCardBg, borderRadius: BorderRadius.circular(10)),
                                child: const Text(
                                  'No notes yet.',
                                  style: TextStyle(fontFamily: 'Open Sans', color: noteText, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              )
                            else
                              ...rejectedDocs.map((d) {
                                final review = reviews[d.key] as Map<String, dynamic>?;
                                final note = review?['note'] as String?;
                                final decidedAt = review?['decidedAt'];
                                final dateLabel = decidedAt is Timestamp ? _formatDate(decidedAt.toDate()) : '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(color: noteCardBg, borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (note != null && note.isNotEmpty) ? note : '${d.label} was rejected.',
                                          style: const TextStyle(fontFamily: 'Open Sans', color: noteText, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'CareLink verification team${dateLabel.isNotEmpty ? ' · $dateLabel' : ''}',
                                          style: const TextStyle(fontFamily: 'Open Sans', color: docSub, fontSize: 10, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: Material(
                                color: contactBg,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Support isn\'t available yet.'), duration: Duration(seconds: 2)),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    child: Text(
                                      'Contact support',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(String key, String label, Map<String, dynamic>? review) {
    final status = review?['status'] as String?; // null | 'approved' | 'rejected'
    final decidedAt = review?['decidedAt'];
    final dateLabel = decidedAt is Timestamp ? _formatDate(decidedAt.toDate()) : null;
    final isUploading = _uploadingKeys.contains(key);

    if (status == 'rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: rejectedCardBg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_rounded, color: rejectedTitle, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontFamily: 'Open Sans', color: rejectedTitle, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                'Rejected${dateLabel != null ? ' $dateLabel' : ''} — re-upload required',
                style: const TextStyle(fontFamily: 'Open Sans', color: rejectedTitle, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: isUploading ? null : () => _reupload(key),
              child: DottedBorderBox(
                child: isUploading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: rejectedTitle))),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Icon(Icons.upload_file_rounded, color: rejectedTitle, size: 22),
                            SizedBox(height: 6),
                            Text('Tap to re-upload', style: TextStyle(fontFamily: 'Open Sans', color: rejectedTitle, fontSize: 13, fontWeight: FontWeight.w700)),
                            SizedBox(height: 2),
                            Text('PDF, JPG or PNG', style: TextStyle(fontFamily: 'Inter', color: rejectedTitle, fontSize: 10)),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    }

    final icon = status == 'approved' ? Icons.check_circle_rounded : Icons.access_time_filled_rounded;
    final iconColor = status == 'approved' ? const Color(0xFF4ADE80) : const Color(0xFFF5B301);
    final subLabel = status == 'approved'
        ? 'Approved${dateLabel != null ? ' $dateLabel' : ''}'
        : 'In review — submitted';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: docCardBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Open Sans', color: docNameApproved, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subLabel, style: const TextStyle(fontFamily: 'Open Sans', color: docSub, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB01E1E), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
