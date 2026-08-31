import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import '../services/caregiver_service.dart';
import '../services/user_directory_service.dart';

// ── Data models ──────────────────────────────────────────────────────────────

/// One real submitted document, individually addressable so it can carry
/// its own real approve/reject decision (`caregiverProfiles.documentReviews`,
/// see CaregiverService.setDocumentReviewStatus).
class DocumentEntry {
  final String key; // 'nic' | 'policeClearance' | 'cert0'... | 'other0'...
  final String label;
  final Map<String, dynamic>? review; // null = still in review

  const DocumentEntry({required this.key, required this.label, this.review});
}

/// A caregiver with at least one verification document actually submitted,
/// built live from real `caregiverProfiles` fields (nic, certificateUrls,
/// policeClearanceUrl, otherDocumentUrls) joined to `users` for the display
/// name.
class VerificationEntry {
  final String uid;
  final String name;
  final String initials;
  final Color avatarBg;
  final List<DocumentEntry> documents;
  bool isExpanded;

  VerificationEntry({
    required this.uid,
    required this.name,
    required this.initials,
    required this.avatarBg,
    required this.documents,
    this.isExpanded = false,
  });
}

// ── Screen ───────────────────────────────────────────────────────────────────

class AdminVerificationQueueScreen extends StatefulWidget {
  const AdminVerificationQueueScreen({super.key});

  @override
  State<AdminVerificationQueueScreen> createState() =>
      _AdminVerificationQueueScreenState();
}

class _AdminVerificationQueueScreenState
    extends State<AdminVerificationQueueScreen> {
  // ── Color tokens ──────────────────────────────────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF50432B);
  static const Color expandedCardBorder = Color(0xFF334155);
  static const Color titleColor = Color(0xFF544730);

  static const Color docRowBg = Color(0xFF73513F);
  static const Color docNameColor = Color(0xFFCBD5E1);
  static const Color docStatusColor = Color(0xFFB26915);

  static const Color collapsedName = Color(0xFF585247);
  static const Color collapsedSub = Color(0xFFFCE8C3);

  static const Color emptyStateColor = Color(0xFF655443);
  static const Color sectionHeaderColor = Colors.black;

  static const List<Color> _avatarPalette = [
    Color(0xFF6D6B3B),
    Color(0xFF313131),
    Color(0xFF4A3728),
    Color(0xFF735726),
    Color(0xFFA28C66),
    Color(0xFF493D2A),
  ];

  final Set<String> _expandedUids = {};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _avatarColorFor(String uid) =>
      _avatarPalette[uid.hashCode.abs() % _avatarPalette.length];

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
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

  /// Every individually-reviewable document on a caregiver's profile, with
  /// its real review decision attached if one exists (see
  /// CaregiverService.setDocumentReviewStatus). Keys match exactly what the
  /// caregiver's own verification-status screen reads.
  List<DocumentEntry> _documentsFor(Map<String, dynamic> caregiver) {
    final reviews = (caregiver['documentReviews'] as Map?)?.cast<String, dynamic>() ?? const {};
    final docs = <DocumentEntry>[];

    final nic = (caregiver['nic'] as String?)?.trim();
    if (nic != null && nic.isNotEmpty) {
      docs.add(DocumentEntry(key: 'nic', label: 'NIC — $nic', review: reviews['nic'] as Map<String, dynamic>?));
    }
    final police = (caregiver['policeClearanceUrl'] as String?) ?? '';
    if (police.isNotEmpty) {
      docs.add(DocumentEntry(
        key: 'policeClearance',
        label: _labelForUrl(police, 'Police clearance certificate'),
        review: reviews['policeClearance'] as Map<String, dynamic>?,
      ));
    }
    final certs = (caregiver['certificateUrls'] as List?)?.cast<String>() ?? const [];
    for (var i = 0; i < certs.length; i++) {
      final key = 'cert$i';
      docs.add(DocumentEntry(key: key, label: _labelForUrl(certs[i], 'Certificate ${i + 1}'), review: reviews[key] as Map<String, dynamic>?));
    }
    final other = (caregiver['otherDocumentUrls'] as List?)?.cast<String>() ?? const [];
    for (var i = 0; i < other.length; i++) {
      final key = 'other$i';
      docs.add(DocumentEntry(key: key, label: _labelForUrl(other[i], 'Other document ${i + 1}'), review: reviews[key] as Map<String, dynamic>?));
    }
    return docs;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('SUBMITTED DOCUMENTS'),
                    const SizedBox(height: 9),
                    _buildQueueSection(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('AUDIT TRAIL'),
                    const SizedBox(height: 8),
                    _buildAuditTrailSection(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: titleColor, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Verification queue',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Live queue: caregivers with at least one submitted document ─────────

  Widget _buildQueueSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: CaregiverService.streamAllCaregivers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final withDocs = snapshot.data!.where((c) {
          return _documentsFor(c).isNotEmpty;
        }).toList();

        if (withDocs.isEmpty) {
          return _buildInfoCard(
            icon: Icons.folder_off_outlined,
            message: 'No caregivers have submitted verification documents yet.',
          );
        }

        final uids = withDocs.map((c) => c['uid'] as String).toList();
        return FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: UserDirectoryService.getUsers(uids),
          builder: (context, userSnapshot) {
            final users = userSnapshot.data ?? const {};
            final entries = withDocs.map((c) {
              final uid = c['uid'] as String;
              final name = (users[uid]?['name'] as String?)?.trim();
              final displayName = (name == null || name.isEmpty) ? 'Unnamed caregiver' : name;
              return VerificationEntry(
                uid: uid,
                name: displayName,
                initials: _initialsFor(displayName),
                avatarBg: _avatarColorFor(uid),
                documents: _documentsFor(c),
                isExpanded: _expandedUids.contains(uid),
              );
            }).toList();

            return Column(
              children: entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: entry.isExpanded
                      ? _buildExpandedCard(entry)
                      : _buildCollapsedCard(entry),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(icon, size: 26, color: titleColor),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: emptyStateColor),
          ),
        ],
      ),
    );
  }

  // ── Expanded card ─────────────────────────────────────────────────────────

  Widget _buildExpandedCard(VerificationEntry entry) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: expandedCardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(entry),
          const SizedBox(height: 11),
          Column(
            children: entry.documents.map((doc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _buildDocumentRow(entry.uid, doc),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(VerificationEntry entry) {
    return GestureDetector(
      onTap: () => setState(() {
        if (_expandedUids.contains(entry.uid)) {
          _expandedUids.remove(entry.uid);
        } else {
          _expandedUids.add(entry.uid);
        }
      }),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: entry.avatarBg,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: collapsedName,
                  ),
                ),
                Text(
                  '${entry.documents.length} document${entry.documents.length == 1 ? '' : 's'} submitted',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: collapsedSub,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.expand_less_rounded, color: collapsedName, size: 20),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String uid, DocumentEntry doc) {
    final status = doc.review?['status'] as String?; // null | 'approved' | 'rejected'
    final note = doc.review?['note'] as String?;
    final (statusLabel, statusColor) = switch (status) {
      'approved' => ('APPROVED', const Color(0xFF4ADE80)),
      'rejected' => ('REJECTED', const Color(0xFFEF4444)),
      _ => ('AWAITING REVIEW', docStatusColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: docRowBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 17, color: docNameColor),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  doc.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: docNameColor,
                  ),
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (status == 'rejected' && note != null && note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                note,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400, color: docNameColor),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => CaregiverService.setDocumentReviewStatus(uid: uid, docKey: doc.key, status: 'approved'),
                  child: const Text(
                    'Approve',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4ADE80)),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _showRejectDialog(uid, doc),
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Collapsed card ────────────────────────────────────────────────────────

  Widget _buildCollapsedCard(VerificationEntry entry) {
    return GestureDetector(
      onTap: () => setState(() => _expandedUids.add(entry.uid)),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: entry.avatarBg,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Center(
                child: Text(
                  entry.initials,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: collapsedName,
                    ),
                  ),
                  Text(
                    '${entry.documents.length} document${entry.documents.length == 1 ? '' : 's'} submitted',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: collapsedSub,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: collapsedName, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: sectionHeaderColor,
        letterSpacing: 0.6,
      ),
    );
  }

  // ── Audit trail (honest empty state — no audit-log collection exists) ───

  /// Real review history, derived from every caregiver's `documentReviews`
  /// map — no separate audit-log collection needed since each decision
  /// already carries its own `decidedAt`.
  Widget _buildAuditTrailSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: CaregiverService.streamAllCaregivers(),
      builder: (context, snapshot) {
        final caregivers = snapshot.data ?? const [];
        final records = <({String uid, String docKey, String status, String? note, Timestamp? decidedAt})>[];
        for (final c in caregivers) {
          final reviews = (c['documentReviews'] as Map?)?.cast<String, dynamic>() ?? const {};
          for (final entry in reviews.entries) {
            final v = (entry.value as Map?)?.cast<String, dynamic>();
            if (v == null) continue;
            records.add((
              uid: c['uid'] as String,
              docKey: entry.key,
              status: (v['status'] as String?) ?? '',
              note: v['note'] as String?,
              decidedAt: v['decidedAt'] as Timestamp?,
            ));
          }
        }

        if (records.isEmpty) {
          return _buildInfoCard(
            icon: Icons.history_rounded,
            message: 'No verification review history recorded yet.',
          );
        }

        records.sort((a, b) {
          if (a.decidedAt == null || b.decidedAt == null) return 0;
          return b.decidedAt!.compareTo(a.decidedAt!);
        });

        final uids = records.map((r) => r.uid).toSet().toList();
        return FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: UserDirectoryService.getUsers(uids),
          builder: (context, userSnap) {
            final users = userSnap.data ?? const {};
            return Column(
              children: records.take(20).map((r) {
                final name = (users[r.uid]?['name'] as String?)?.trim();
                final displayName = (name == null || name.isEmpty) ? 'Unnamed caregiver' : name;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildAuditRow(displayName, r.docKey, r.status, r.note, r.decidedAt),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildAuditRow(String name, String docKey, String status, String? note, Timestamp? decidedAt) {
    final color = status == 'approved' ? const Color(0xFF4ADE80) : const Color(0xFFEF4444);
    final verb = status == 'approved' ? 'approved' : 'rejected';
    final dateLabel = decidedAt != null ? _formatDate(decidedAt.toDate()) : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cardBorder, width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(status == 'approved' ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$name — $docKey $verb',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(dateLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: emptyStateColor)),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Text(note, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: emptyStateColor)),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ── Reject flow — real write via CaregiverService.setDocumentReviewStatus,
  // shown to the caregiver on their own verification-status screen. ───────
  void _showRejectDialog(String uid, DocumentEntry doc) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject "${doc.label}"?',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Reason (shown to the caregiver) — optional but recommended',
            hintStyle: TextStyle(color: Color(0xFFB5ADA2), fontSize: 12),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A4032))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFBBC05))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(dialogCtx);
              CaregiverService.setDocumentReviewStatus(
                uid: uid,
                docKey: doc.key,
                status: 'rejected',
                note: controller.text.trim(),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
