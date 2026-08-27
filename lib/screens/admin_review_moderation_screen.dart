import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

enum ReviewModerationStatus { flagged, hidden, cleared }

enum ReviewFlagType { autoFlagged, reportedByCaregiver }

class AdminReviewData {
  final String id;
  ReviewModerationStatus status;
  final ReviewFlagType flagType;
  final String flagLabel;
  final String? timeAgo;
  final String? initials;
  final Color? avatarBg;
  final Color? avatarText;
  final String reviewerLine;
  final String? subtitleLine;
  final String reviewText;
  final String? infoBannerText;
  final bool showBlockButton;
  final String primaryActionLabel;
  final String secondaryActionLabel;
  String? resolutionNote;

  AdminReviewData({
    required this.id,
    required this.status,
    required this.flagType,
    required this.flagLabel,
    this.timeAgo,
    this.initials,
    this.avatarBg,
    this.avatarText,
    required this.reviewerLine,
    this.subtitleLine,
    required this.reviewText,
    this.infoBannerText,
    this.showBlockButton = false,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
    this.resolutionNote,
  });
}

class AdminReviewModerationScreen extends StatefulWidget {
  const AdminReviewModerationScreen({super.key});

  @override
  State<AdminReviewModerationScreen> createState() => _AdminReviewModerationScreenState();
}

class _AdminReviewModerationScreenState extends State<AdminReviewModerationScreen> {
  // ── Color Tokens matching Figma node 643:685 ────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);

  static const Color filterActiveBg = Color(0xFF5D5445);
  static const Color filterActiveFg = Color(0xFFF8FAFC);
  static const Color filterInactiveBorder = Color(0xFF5D5445);

  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF70573C);

  static const Color autoFlagColor = Color(0xFFB26915);
  static const Color reportedFlagColor = Color(0xFFEF4444);
  static const Color timestampColor = Color(0xFF5D5445);

  static const Color nameColor = Color(0xFF544730);
  static const Color subtitleColor = Color(0xFF82716A);
  static const Color reviewTextColor = Color(0xFF5A4B37);

  static const Color infoBannerBg = Color(0xFFA69785);
  static const Color infoBannerText = Color(0xFF5D5445);

  static const Color primaryBtnBg = Color(0xFF412800);
  static const Color secondaryBtnBorder = Color(0xFF412800);
  static const Color blockBtnBorder = Color(0xFF5D5445);

  ReviewModerationStatus _activeFilter = ReviewModerationStatus.flagged;

  late final List<AdminReviewData> _reviews = [
    AdminReviewData(
      id: 'rv_1',
      status: ReviewModerationStatus.flagged,
      flagType: ReviewFlagType.autoFlagged,
      flagLabel: 'Auto-flagged · suspected fake',
      timeAgo: '2h ago',
      initials: 'AK',
      avatarBg: const Color(0xFF475569),
      avatarText: const Color(0xFFCBD5E1),
      reviewerLine: 'Anon K. → Nadeesha W.',
      subtitleLine: '1.0 ★ · account created 3 days ago',
      reviewText: '"Worst service ever, do not book. Same text posted on four other caregiver profiles."',
      infoBannerText: 'No completed booking links this reviewer to the caregiver.',
      showBlockButton: true,
      primaryActionLabel: 'Hide review',
      secondaryActionLabel: 'Keep',
    ),
    AdminReviewData(
      id: 'rv_2',
      status: ReviewModerationStatus.flagged,
      flagType: ReviewFlagType.reportedByCaregiver,
      flagLabel: 'Reported by caregiver · abusive language',
      reviewerLine: 'Ruwan D. → Alice Fernando · 2.0 ★',
      reviewText: 'Contains language that breaches community guidelines.',
      primaryActionLabel: 'Hide',
      secondaryActionLabel: 'Investigate',
    ),
    AdminReviewData(
      id: 'rv_3',
      status: ReviewModerationStatus.flagged,
      flagType: ReviewFlagType.autoFlagged,
      flagLabel: 'Auto-flagged · duplicate content',
      timeAgo: '6h ago',
      initials: 'TM',
      avatarBg: const Color(0xFF784B26),
      avatarText: const Color(0xFFFBBC05),
      reviewerLine: 'Tharaka M. → Sanduni P.',
      subtitleLine: '5.0 ★ · account created 2 months ago',
      reviewText: '"Amazing caregiver, highly recommend!" — identical wording to 6 other reviews this week.',
      infoBannerText: 'Same phrasing detected across multiple reviewer accounts.',
      showBlockButton: true,
      primaryActionLabel: 'Hide review',
      secondaryActionLabel: 'Keep',
    ),
    AdminReviewData(
      id: 'rv_4',
      status: ReviewModerationStatus.hidden,
      flagType: ReviewFlagType.reportedByCaregiver,
      flagLabel: 'Reported by caregiver · harassment',
      reviewerLine: 'Priya J. → Brian Kumara · 1.0 ★',
      reviewText: 'Personal threats directed at the caregiver outside the scope of the booking.',
      primaryActionLabel: 'Hide',
      secondaryActionLabel: 'Investigate',
      resolutionNote: 'Hidden by Sanduni D. · 19 Aug 2026',
    ),
    AdminReviewData(
      id: 'rv_5',
      status: ReviewModerationStatus.cleared,
      flagType: ReviewFlagType.autoFlagged,
      flagLabel: 'Auto-flagged · suspected fake',
      initials: 'NW',
      avatarBg: const Color(0xFF6ED5C9),
      avatarText: const Color(0xFF04302C),
      reviewerLine: 'Nadeesha W. → Kamal Perera',
      subtitleLine: '4.5 ★ · account created 1 year ago',
      reviewText: '"Very attentive and professional, would book again."',
      primaryActionLabel: 'Hide review',
      secondaryActionLabel: 'Keep',
      resolutionNote: 'Cleared by Tharaka M. · 18 Aug 2026 — confirmed genuine booking',
    ),
  ];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  int _countFor(ReviewModerationStatus s) => _reviews.where((r) => r.status == s).length;

  List<AdminReviewData> get _filteredReviews =>
      _reviews.where((r) => r.status == _activeFilter).toList();

  void _hideReview(AdminReviewData r) {
    setState(() {
      r.status = ReviewModerationStatus.hidden;
      r.resolutionNote = 'Hidden by you · just now';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review from ${r.reviewerLine} hidden.'), duration: const Duration(seconds: 2)),
    );
  }

  void _keepReview(AdminReviewData r) {
    setState(() {
      r.status = ReviewModerationStatus.cleared;
      r.resolutionNote = 'Cleared by you · just now';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review from ${r.reviewerLine} cleared.'), duration: const Duration(seconds: 2)),
    );
  }

  void _investigateReview(AdminReviewData r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Investigation opened for ${r.reviewerLine}.'), duration: const Duration(seconds: 2)),
    );
  }

  void _blockReviewer(AdminReviewData r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Block Reviewer?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'This will block the account behind "${r.reviewerLine}" from posting further reviews.',
          style: const TextStyle(color: Color(0xFFC4BBAC), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reviewer blocked for "${r.reviewerLine}".'), duration: const Duration(seconds: 2)),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredReviews.isEmpty
                  ? Center(
                      child: Text(
                        'No reviews in this category',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                      itemCount: _filteredReviews.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 11),
                      itemBuilder: (context, index) => _buildReviewCard(_filteredReviews[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
            ),
          ),
          const Icon(Icons.outlined_flag_rounded, color: titleColor, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Review moderation',
              style: TextStyle(fontFamily: 'Inter', fontSize: 19, fontWeight: FontWeight.w800, color: titleColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ──────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    final filters = [
      (ReviewModerationStatus.flagged, 'Flagged ${_countFor(ReviewModerationStatus.flagged)}'),
      (ReviewModerationStatus.hidden, 'Hidden'),
      (ReviewModerationStatus.cleared, 'Cleared'),
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
                  border: Border.all(color: filterInactiveBorder, width: isActive ? 0 : 1),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? filterActiveFg : filterInactiveBorder,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Review card ─────────────────────────────────────────────────────────
  Widget _buildReviewCard(AdminReviewData r) {
    final isAuto = r.flagType == ReviewFlagType.autoFlagged;
    final flagColor = isAuto ? autoFlagColor : reportedFlagColor;
    final flagIcon = isAuto ? Icons.flag_rounded : Icons.report_rounded;
    final isResolved = r.status != ReviewModerationStatus.flagged;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(flagIcon, size: 17, color: flagColor),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  r.flagLabel,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: flagColor),
                ),
              ),
              if (r.timeAgo != null)
                Text(
                  r.timeAgo!,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: timestampColor),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (r.initials != null) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: r.avatarBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    r.initials!,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: r.avatarText),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.reviewerLine,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700, color: nameColor),
                      ),
                      if (r.subtitleLine != null)
                        Text(
                          r.subtitleLine!,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: subtitleColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else ...[
            Text(
              r.reviewerLine,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700, color: nameColor),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            r.reviewText,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w400, color: reviewTextColor, height: 1.55),
          ),
          if (r.infoBannerText != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
              decoration: BoxDecoration(color: infoBannerBg, borderRadius: BorderRadius.circular(9)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline_rounded, size: 16, color: infoBannerText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.infoBannerText!,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: infoBannerText, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isResolved && r.resolutionNote != null) ...[
            const SizedBox(height: 10),
            Text(
              r.resolutionNote!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: r.status == ReviewModerationStatus.hidden ? reportedFlagColor : const Color(0xFF2B4A11),
              ),
            ),
          ] else ...[
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: primaryBtnBg,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _hideReview(r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Center(
                          child: Text(
                            r.primaryActionLabel,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => r.secondaryActionLabel == 'Investigate' ? _investigateReview(r) : _keepReview(r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: secondaryBtnBorder, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            r.secondaryActionLabel,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: secondaryBtnBorder),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (r.showBlockButton) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _blockReviewer(r),
                      child: Container(
                        width: 46,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: blockBtnBorder, width: 1),
                        ),
                        child: const Icon(Icons.person_off_outlined, size: 18, color: blockBtnBorder),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
