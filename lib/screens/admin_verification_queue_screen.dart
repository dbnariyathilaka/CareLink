import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

// ── Data models ──────────────────────────────────────────────────────────────

enum DocStatus { matched, review, expired }

enum AuditAction { approved, rejected }

enum QueueFilter { pending, approved, rejected }

class VerificationDocument {
  final String name;
  final DocStatus status;
  const VerificationDocument({required this.name, required this.status});
}

class VerificationEntry {
  final String initials;
  final Color avatarBg;
  final Color avatarText;
  final String name;
  final String submittedLabel; // e.g. "Submitted 2h ago · 4 documents"
  final List<VerificationDocument> documents;
  final String? warningMessage;
  bool isExpanded;

  VerificationEntry({
    required this.initials,
    required this.avatarBg,
    required this.avatarText,
    required this.name,
    required this.submittedLabel,
    required this.documents,
    this.warningMessage,
    this.isExpanded = false,
  });
}

class AuditTrailEntry {
  final AuditAction action;
  final String description;
  final String timestamp;
  const AuditTrailEntry({
    required this.action,
    required this.description,
    required this.timestamp,
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
  QueueFilter _activeFilter = QueueFilter.pending;

  // ── Color tokens ──────────────────────────────────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF50432B);
  static const Color titleColor = Color(0xFF544730);

  static const Color filterActiveBg = Color(0xFF585247);
  static const Color filterActiveFg = Color(0xFFF8FAFC);
  static const Color filterInactiveBorder = Color(0xFF585247);
  static const Color filterInactiveFg = Color(0xFF585247);

  static const Color docRowBg = Color(0xFF73513F);
  static const Color docNameColor = Color(0xFFCBD5E1);
  static const Color statusMatched = Color(0xFF34A853);
  static const Color statusReview = Color(0xFFB26915);
  static const Color statusExpired = Color(0xFFEF4444);

  static const Color warningBg = Color(0x14EF4444);   // 8%
  static const Color warningBorder = Color(0x40EF4444); // 25%
  static const Color warningText = Color(0xFFEA4335);

  static const Color approveBtnBg = Color(0xFF795D3D);
  static const Color approveBtnFg = Color(0xFFFFF1E2);
  static const Color rejectBtnBorder = Color(0xFF92512E);
  static const Color rejectBtnFg = Color(0xFF944E29);
  static const Color commentBtnBorder = Color(0xFF585247);

  static const Color collapsedName = Color(0xFF585247);
  static const Color collapsedSub = Color(0xFFFCE8C3);

  static const Color auditLabel = Color(0xFF585247);
  static const Color auditTimestamp = Color(0xFFFCE8C3);
  static const Color sectionHeaderColor = Colors.black;

  // ── Sample data ───────────────────────────────────────────────────────────
  final List<VerificationEntry> _entries = [
    VerificationEntry(
      initials: 'BK',
      avatarBg: const Color(0xFF6D6B3B),
      avatarText: Colors.white,
      name: 'Brian Kumara',
      submittedLabel: 'Submitted 2h ago · 4 documents',
      documents: const [
        VerificationDocument(name: 'NIC — 923456789V', status: DocStatus.matched),
        VerificationDocument(name: 'Police clearance.pdf', status: DocStatus.review),
        VerificationDocument(name: 'Caregiving diploma.pdf', status: DocStatus.review),
        VerificationDocument(name: 'CPR / First-aid cert.pdf', status: DocStatus.expired),
      ],
      warningMessage:
          'First-aid certificate expired 12 Jun 2026.\nCaregiver cannot accept jobs until renewed.',
      isExpanded: true,
    ),
    VerificationEntry(
      initials: 'PJ',
      avatarBg: const Color(0xFF313131),
      avatarText: const Color(0xFFFFBE4D),
      name: 'Priya Jayasuriya',
      submittedLabel: 'Submitted 5h ago · 3 documents',
      documents: const [
        VerificationDocument(name: 'NIC — 876543210V', status: DocStatus.review),
        VerificationDocument(name: 'Nursing certificate.pdf', status: DocStatus.review),
        VerificationDocument(name: 'First-aid cert.pdf', status: DocStatus.review),
      ],
      isExpanded: false,
    ),
    VerificationEntry(
      initials: 'SR',
      avatarBg: const Color(0xFF4A3728),
      avatarText: const Color(0xFFFFD9A8),
      name: 'Saman Ranaweera',
      submittedLabel: 'Submitted 8h ago · 2 documents',
      documents: const [
        VerificationDocument(name: 'NIC — 654321098V', status: DocStatus.review),
        VerificationDocument(name: 'Police clearance.pdf', status: DocStatus.review),
      ],
      isExpanded: false,
    ),
  ];

  final List<AuditTrailEntry> _auditTrail = const [
    AuditTrailEntry(
      action: AuditAction.approved,
      description: 'Sanduni D. approved NIC for A. Fernando',
      timestamp: '21 Aug 2026 · 4:12 PM',
    ),
    AuditTrailEntry(
      action: AuditAction.rejected,
      description: 'Tharaka M. rejected blurred diploma scan',
      timestamp: '20 Aug 2026 · 11:38 AM',
    ),
  ];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _docStatusLabel(DocStatus s) {
    switch (s) {
      case DocStatus.matched: return 'MATCHED';
      case DocStatus.review:  return 'REVIEW';
      case DocStatus.expired: return 'EXPIRED';
    }
  }

  Color _docStatusColor(DocStatus s) {
    switch (s) {
      case DocStatus.matched: return statusMatched;
      case DocStatus.review:  return statusReview;
      case DocStatus.expired: return statusExpired;
    }
  }

  IconData _docIcon(DocStatus s) {
    switch (s) {
      case DocStatus.matched: return Icons.badge_outlined;
      case DocStatus.review:  return Icons.shield_outlined;
      case DocStatus.expired: return Icons.workspace_premium_outlined;
    }
  }

  void _approveEntry(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_entries[index].name} approved ✓'),
        backgroundColor: statusMatched,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _rejectEntry(int index) {
    _showRejectDialog(index);
  }

  void _showRejectDialog(int index) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reject Documents',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason for rejecting ${_entries[index].name}\'s submission:',
              style: const TextStyle(color: Color(0xFFD4CDC3), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                hintStyle: const TextStyle(color: Color(0xFF6B5E4A)),
                filled: true,
                fillColor: const Color(0xFF3B3329),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: rejectBtnBorder,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_entries[index].name}\'s submission rejected'),
                  backgroundColor: statusExpired,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  void _showCommentSheet(int index) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C251D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add comment for ${_entries[index].name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your comment...',
                hintStyle: const TextStyle(color: Color(0xFF6B5E4A)),
                filled: true,
                fillColor: const Color(0xFF3B3329),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: approveBtnBg,
                  foregroundColor: approveBtnFg,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment added'),
                      backgroundColor: Color(0xFF585247),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Send comment',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            _buildFilterBar(),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._entries.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: e.value.isExpanded
                            ? _buildExpandedCard(e.key, e.value)
                            : _buildCollapsedCard(e.key, e.value),
                      );
                    }),
                    _buildSectionLabel('AUDIT TRAIL'),
                    const SizedBox(height: 8),
                    _buildAuditTrailCard(),
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
          Icon(Icons.history_rounded, color: titleColor.withValues(alpha: 0.7), size: 22),
        ],
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    final filters = [
      (QueueFilter.pending, 'Pending 12'),
      (QueueFilter.approved, 'Approved'),
      (QueueFilter.rejected, 'Rejected'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Row(
        children: filters.map((f) {
          final isActive = _activeFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? filterActiveBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isActive ? Colors.transparent : filterInactiveBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? filterActiveFg : filterInactiveFg,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Expanded card (Brian Kumara style) ────────────────────────────────────

  Widget _buildExpandedCard(int index, VerificationEntry entry) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name row
          _buildCardHeader(index, entry),
          const SizedBox(height: 11),

          // Document rows
          Column(
            children: entry.documents.map((doc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _buildDocumentRow(doc),
              );
            }).toList(),
          ),

          // Warning banner
          if (entry.warningMessage != null) ...[
            _buildWarningBanner(entry.warningMessage!),
            const SizedBox(height: 11),
          ],

          // Action buttons
          _buildActionButtons(index),
        ],
      ),
    );
  }

  Widget _buildCardHeader(int index, VerificationEntry entry) {
    return GestureDetector(
      onTap: () => setState(() => entry.isExpanded = !entry.isExpanded),
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
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: entry.avatarText,
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
                  entry.submittedLabel,
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
        ],
      ),
    );
  }

  Widget _buildDocumentRow(VerificationDocument doc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: docRowBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(_docIcon(doc.status), size: 17, color: docNameColor),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              doc.name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: docNameColor,
              ),
            ),
          ),
          Text(
            _docStatusLabel(doc.status),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _docStatusColor(doc.status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: warningBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: warningBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: warningText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: warningText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int index) {
    return Row(
      children: [
        // Approve
        Expanded(
          flex: 3,
          child: Material(
            color: approveBtnBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _approveEntry(index),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Center(
                  child: Text(
                    'Approve',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: approveBtnFg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Reject
        Expanded(
          flex: 3,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _rejectEntry(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: rejectBtnBorder, width: 1),
                ),
                child: const Center(
                  child: Text(
                    'Reject',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: rejectBtnFg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Comment
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showCommentSheet(index),
            child: Container(
              width: 46,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: commentBtnBorder, width: 1),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: commentBtnBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Collapsed card (Priya Jayasuriya style) ───────────────────────────────

  Widget _buildCollapsedCard(int index, VerificationEntry entry) {
    return GestureDetector(
      onTap: () => setState(() => entry.isExpanded = true),
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: entry.avatarText,
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
                    entry.submittedLabel,
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

  // ── Audit trail ───────────────────────────────────────────────────────────

  Widget _buildAuditTrailCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        children: _auditTrail.asMap().entries.map((e) {
          final entry = e.value;
          final isLast = e.key == _auditTrail.length - 1;
          return Column(
            children: [
              _buildAuditRow(entry),
              if (!isLast) const SizedBox(height: 10),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAuditRow(AuditTrailEntry entry) {
    final isApproved = entry.action == AuditAction.approved;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 2),
          child: Icon(
            isApproved
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            size: 16,
            color: isApproved ? statusMatched : statusExpired,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: auditLabel,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.timestamp,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: auditTimestamp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
